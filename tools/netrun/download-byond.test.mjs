import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { downloadArchive } from './download-byond.mjs';

const bytes = Buffer.from('a pinned archive with a short final chunk');
const hash = crypto.createHash('sha256').update(bytes).digest('hex');
const urls = ['https://origin.invalid/archive', 'https://mirror.invalid/archive'];
const rangeResponse = (range) => {
  const [, start, end] = /^bytes=(\d+)-(\d+)$/.exec(range);
  return new Response(bytes.subarray(Number(start), Number(end) + 1), { status: 206,
    headers: { 'Content-Range': `bytes ${start}-${end}/${bytes.length}` } });
};

test('pinned full archive succeeds without any range calls', async () => {
  let calls = 0;
  assert.deepEqual(await downloadArchive(urls, hash, { fetcher: async () => { calls++; return new Response(bytes); } }), bytes);
  assert.equal(calls, 1);
});

test('broken full downloads and one truncated range recover with bounded exact ranges', async () => {
  let truncated = false;
  const fetcher = async (url, options) => {
    assert.equal(options.headers.Connection, 'close');
    if (!options.headers.Range) return new Response('corrupt full response');
    assert.equal(url, urls[1]);
    if (options.headers.Range === 'bytes=8-15' && !truncated) {
      truncated = true;
      return new Response('x', { status: 206, headers: { 'Content-Range': `bytes 8-15/${bytes.length}` } });
    }
    return rangeResponse(options.headers.Range);
  };
  assert.deepEqual(await downloadArchive(urls, hash, { fetcher, partSize: 8, concurrency: 2 }), bytes);
  assert.equal(truncated, true);
});

test('ignored Range and wrong archive checksum cannot publish an archive', async () => {
  await assert.rejects(downloadArchive(urls, hash, { fetcher: async () => new Response('wrong') }), /range_response/);
  await assert.rejects(downloadArchive(urls, '0'.repeat(64), { partSize: 8,
    fetcher: async (url, options) => options.headers.Range ? rangeResponse(options.headers.Range) : new Response(bytes) }), /checksum/);
});
