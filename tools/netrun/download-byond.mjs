#!/usr/bin/env node
/** Загружает pinned BYOND archive; bounded ranges переживают обрывы больших HTTPS responses. */
import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const maxArchive = 64 * 1024 * 1024;
const digest = (bytes) => crypto.createHash('sha256').update(bytes).digest('hex');

/** Поток ограничен до чтения всего body, включая ответы с неверным Content-Length. */
async function readBounded(response, limit) {
  const chunks = [];
  let length = 0;
  for await (const chunk of response.body) {
    length += chunk.length;
    if (length > limit) throw new Error('byond_archive_size');
    chunks.push(chunk);
  }
  return Buffer.concat(chunks, length);
}

/** Каждый запрос имеет отдельное соединение: это также обходит зависающие keep-alive proxies. */
async function request(fetcher, url, timeoutMs, headers = {}) {
  const response = await fetcher(url, { headers: { 'User-Agent': 'NETRUN-build', Connection: 'close', ...headers },
    signal: AbortSignal.timeout(timeoutMs) });
  if (!response.ok) {
    await response.body?.cancel();
    throw new Error(`byond_http_${response.status}`);
  }
  return response;
}

/** SHA-256 проверяется для обычного и составного скачивания до публикации результата. */
export async function downloadArchive(urls, hash, { fetcher = fetch, timeoutMs = 20000, partSize = 8192, concurrency = 4 } = {}) {
  if (!/^[a-f0-9]{64}$/.test(hash) || !urls.length || !urls.every((url) => url.startsWith('https://')))
    throw new Error('byond_download_configuration');
  for (const url of urls) {
    try {
      const response = await request(fetcher, url, timeoutMs);
      const bytes = await readBounded(response, maxArchive);
      if (digest(bytes) === hash) return bytes;
    } catch { /* Следующий HTTPS source или bounded range fallback. */ }
  }
  // Диапазоны берём с mirror: официальный origin ограничивает частоту запросов.
  const url = urls.at(-1);
  const first = await request(fetcher, url, timeoutMs, { Range: `bytes=0-${partSize - 1}` });
  const match = new RegExp(`^bytes 0-${partSize - 1}/([0-9]+)$`).exec(first.headers.get('content-range') || '');
  if (first.status !== 206 || !match) { await first.body?.cancel(); throw new Error('byond_range_response'); }
  const size = Number(match[1]);
  if (size < partSize || size > maxArchive) { await first.body?.cancel(); throw new Error('byond_archive_size'); }
  const bytes = Buffer.alloc(size);
  const initial = await readBounded(first, partSize);
  if (initial.length !== partSize) throw new Error('byond_range_length');
  initial.copy(bytes);
  let cursor = partSize;
  async function worker() {
    while (cursor < size) {
      const start = cursor;
      cursor += partSize;
      const end = Math.min(start + partSize, size) - 1;
      let failure;
      for (let attempt = 0; attempt < 3; attempt++) {
        try {
          const response = await request(fetcher, url, timeoutMs, { Range: `bytes=${start}-${end}` });
          if (response.status !== 206 || response.headers.get('content-range') !== `bytes ${start}-${end}/${size}`) {
            await response.body?.cancel();
            throw new Error('byond_range_response');
          }
          const part = await readBounded(response, end - start + 1);
          if (part.length !== end - start + 1) throw new Error('byond_range_length');
          part.copy(bytes, start);
          failure = null;
          break;
        } catch (error) { failure = error; }
      }
      if (failure) throw failure;
    }
  }
  const results = await Promise.allSettled(Array.from({ length: concurrency }, worker));
  const failed = results.find((result) => result.status === 'rejected');
  if (failed) throw failed.reason;
  if (digest(bytes) !== hash) throw new Error('byond_archive_checksum');
  return bytes;
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const [version, hash, output] = process.argv.slice(2);
  if (!/^\d+\.\d+$/.test(version || '') || !output) throw new Error('byond_download_arguments');
  const major = version.split('.')[0];
  const archive = `${version}_byond_linux.zip`;
  const bytes = await downloadArchive([`https://www.byond.com/download/build/${major}/${archive}`,
    `https://byond-builds.dm-lang.org/${major}/${archive}`], hash);
  fs.writeFileSync(output, bytes);
  console.log(`BYOND ${version}: verified ${bytes.length} bytes (SHA-256 ${hash})`);
}
