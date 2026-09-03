const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');
const {
  computeAcceptKey,
  encodeTextFrame,
  resolveSafePath,
  createDevServer,
} = require('./server.cjs');

describe('computeAcceptKey', () => {
  // RFC 6455 пример: ключ -> accept
  test('matches RFC 6455 sample vector', () => {
    expect(computeAcceptKey('dGhlIHNhbXBsZSBub25jZQ==')).toBe(
      's3pPLMBiTxaQ9kYGzzhZRbK+xOo=',
    );
  });
});

describe('encodeTextFrame', () => {
  test('short payload uses single-byte length, FIN+text opcode', () => {
    const frame = encodeTextFrame('hi');
    expect(frame[0]).toBe(0x81);
    expect(frame[1]).toBe(2);
    expect(frame.slice(2).toString('utf8')).toBe('hi');
  });

  test('medium payload (>=126) uses 16-bit length', () => {
    const text = 'x'.repeat(200);
    const frame = encodeTextFrame(text);
    expect(frame[0]).toBe(0x81);
    expect(frame[1]).toBe(126);
    expect(frame.readUInt16BE(2)).toBe(200);
    expect(frame.slice(4).toString('utf8')).toBe(text);
  });
});

describe('resolveSafePath', () => {
  const root = path.resolve('/srv/tgui/public');

  test('resolves a normal file inside root', () => {
    expect(resolveSafePath(root, '/tgui.bundle.js')).toBe(
      path.join(root, 'tgui.bundle.js'),
    );
  });

  test('rooted .. stays inside root (cannot climb above the leading slash)', () => {
    const resolved = resolveSafePath(root, '/../../etc/passwd');
    expect(resolved).not.toBeNull();
    expect(resolved.startsWith(root + path.sep)).toBe(true);
  });

  test('rejects relative escape above root', () => {
    expect(resolveSafePath(root, 'a/../../../evil')).toBeNull();
  });

  test('rejects sibling dir sharing a name prefix (public vs public-evil)', () => {
    // Это и есть граница, которую чинит startsWith(root + sep):
    // ".../public-evil" нельзя считать внутри ".../public".
    expect(resolveSafePath(root, '../public-evil/secret')).toBeNull();
  });
});

describe('createDevServer static serving', () => {
  let dir;
  let dev;

  beforeAll((done) => {
    dir = fs.mkdtempSync(path.join(os.tmpdir(), 'tgui-dev-'));
    fs.writeFileSync(path.join(dir, 'tgui.bundle.js'), 'console.log(1)');
    dev = createDevServer({ port: 0, publicDir: dir });
    dev.listen().then(done);
  });

  afterAll((done) => {
    dev.server.close(done);
  });

  test('serves bundle file with CORS and no-store', (done) => {
    const port = dev.server.address().port;
    http.get(`http://127.0.0.1:${port}/tgui.bundle.js`, (res) => {
      let body = '';
      res.on('data', (c) => (body += c));
      res.on('end', () => {
        expect(res.statusCode).toBe(200);
        expect(res.headers['access-control-allow-origin']).toBe('*');
        expect(res.headers['cache-control']).toBe('no-store');
        expect(body).toBe('console.log(1)');
        done();
      });
    });
  });

  test('returns 404 for missing file', (done) => {
    const port = dev.server.address().port;
    http.get(`http://127.0.0.1:${port}/nope.js`, (res) => {
      expect(res.statusCode).toBe(404);
      res.resume();
      done();
    });
  });
});
