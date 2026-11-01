/**
 * Сжатие истории чата для хранилища: deflate-raw в base64, строка без
 * символов, которые JSON экранирует.
 */

export const CODEC_NAME = 'deflate-raw';

const BASE64_SLICE = 0x8000;

const readAll = async readable => {
  const reader = readable.getReader();
  const chunks = [];
  let length = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) {
      break;
    }
    chunks.push(value);
    length += value.length;
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  return bytes;
};

const pipeThrough = async (stream, bytes) => {
  const writer = stream.writable.getWriter();
  writer.write(bytes).catch(() => {});
  writer.close().catch(() => {});
  return readAll(stream.readable);
};

const toBase64 = bytes => {
  let binary = '';
  for (let i = 0; i < bytes.length; i += BASE64_SLICE) {
    binary += String.fromCharCode.apply(null, bytes.subarray(i, i + BASE64_SLICE));
  }
  return btoa(binary);
};

const fromBase64 = text => {
  const binary = atob(text);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
};

/**
 * { name, pack(text), unpack(packed) } или null, если в браузере нет
 * CompressionStream с deflate-raw: тогда история пишется без сжатия.
 */
export const createCodec = (api = globalThis) => {
  const { CompressionStream, DecompressionStream, TextEncoder, TextDecoder } = api;
  if (typeof CompressionStream !== 'function'
    || typeof DecompressionStream !== 'function'
    || typeof TextEncoder !== 'function' || typeof TextDecoder !== 'function') {
    return null;
  }
  try {
    new CompressionStream(CODEC_NAME);
    new DecompressionStream(CODEC_NAME);
  }
  catch {
    return null;
  }
  return {
    name: CODEC_NAME,
    pack: async text => toBase64(await pipeThrough(
      new CompressionStream(CODEC_NAME), new TextEncoder().encode(text))),
    unpack: async packed => new TextDecoder().decode(await pipeThrough(
      new DecompressionStream(CODEC_NAME), fromBase64(packed))),
  };
};
