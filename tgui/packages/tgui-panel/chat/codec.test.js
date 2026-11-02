import { CompressionStream, DecompressionStream } from 'node:stream/web';
import { TextDecoder, TextEncoder } from 'node:util';

import { CODEC_NAME, createCodec } from './codec';

const api = { CompressionStream, DecompressionStream, TextEncoder, TextDecoder };

describe('chat history codec', () => {
  test('packs into base64 and restores the same text', async () => {
    const codec = createCodec(api);
    const text = JSON.stringify(Array.from({ length: 300 }, (_, n) => ({
      html: `<span class="say">Капитан #${n}: «привет», "кавычки" \\ и 😀</span>`,
    })));
    const packed = await codec.pack(text);
    expect(codec.name).toBe(CODEC_NAME);
    expect(packed).toMatch(/^[A-Za-z0-9+/]+=*$/);
    expect(packed.length).toBeLessThan(text.length / 4);
    expect(await codec.unpack(packed)).toBe(text);
  });

  test('a damaged value fails to unpack', async () => {
    const codec = createCodec(api);
    await expect(codec.unpack('AAAA' + (await codec.pack('x'.repeat(1000))).slice(4)))
      .rejects.toThrow();
  });

  test('without CompressionStream there is no codec', () => {
    expect(createCodec({ ...api, CompressionStream: undefined })).toBeNull();
    expect(createCodec({
      ...api,
      CompressionStream: class {
        constructor() {
          throw new TypeError('Unsupported compression format');
        }
      },
    })).toBeNull();
  });
});
