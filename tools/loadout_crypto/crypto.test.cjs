'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { encrypt, decrypt, readSecret, initSecret, request } = require('./crypto.cjs');

const secret = Buffer.from(Array.from({ length: 32 }, (_, i) => i));
// Independent fixture produced with .NET AesGcm, nonce 000102030405060708090a0b.
const fixture = 'enc1:AAECAwQFBgcICQoLBkP7WYfIo3mjb7lYYwet3PW22BiBfjL-G3kJ';

test('decrypt an independent AES-GCM fixture with the exact original spelling', () => {
  assert.equal(decrypt(fixture, secret), 'AA-BB-ab...');
});

test('randomized round trips preserve original and normalized names', () => {
  for (const account of ['AA-BB-ab...', 'aabbab', 'A B C', 'X'.repeat(256), 'Я'.repeat(256), '😀'.repeat(256), 'Привет\n<&>...', '...']) {
    const first = encrypt(account, secret);
    const second = encrypt(account, secret);
    assert.notEqual(first, second);
    assert.equal(decrypt(first, secret), account);
    assert.equal(decrypt(second, secret), account);
  }
});

test('wrong keys, tampering with every payload byte, truncation and unknown versions fail closed', () => {
  assert.throws(() => decrypt(fixture, crypto.randomBytes(32)));
  const bytes = Buffer.from(fixture.slice(5), 'base64url');
  for (let i = 0; i < bytes.length; i++) {
    const changed = Buffer.from(bytes);
    changed[i] ^= 1;
    assert.throws(() => decrypt('enc1:' + changed.toString('base64url'), secret));
  }
  for (const invalid of [fixture.slice(0, -2), fixture + '=', fixture.replace('enc1:', 'enc2:'),
    'enc1:abcd', null, 'enc1:' + 'a'.repeat(400)]) {
    assert.throws(() => decrypt(invalid, secret));
  }
});

test('reject invalid text inputs; batch decrypt preserves positions for invalid IDs', () => {
  for (const invalid of ['', null, {}, 'X'.repeat(257), 'Я'.repeat(257), '😀'.repeat(257)]) {
    assert.throws(() => encrypt(invalid, secret));
  }
  assert.deepEqual(decrypt([fixture, 'enc1:bad', fixture], secret), ['AA-BB-ab...', null, 'AA-BB-ab...']);
});

test('private config, request protocol and CLI inspection; initialization never overwrites a key', (t) => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'loadout-crypto-test-'));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const config = path.join(directory, 'secret.txt');
  initSecret(config);
  const original = fs.readFileSync(config, 'utf8');
  assert.equal(readSecret(config).length, 32);
  assert.throws(() => initSecret(config));
  assert.equal(fs.readFileSync(config, 'utf8'), original);
  if (process.platform !== 'win32') assert.equal(fs.statSync(config).mode & 0o777, 0o600);

  const filename = path.join(directory, 'request.json');
  fs.writeFileSync(filename, JSON.stringify({ operation: 'encrypt', value: 'AA-BB-ab...', secret_file: config }));
  request(filename);
  const response = JSON.parse(fs.readFileSync(filename + '.out', 'utf8'));
  assert.equal(response.ok, true);
  assert.equal(decrypt(response.value, readSecret(config)), 'AA-BB-ab...');
  const batchRequest = path.join(directory, 'batch.json');
  const unicodeText = 'Я'.repeat(256);
  const unicodeToken = encrypt(unicodeText, readSecret(config));
  fs.writeFileSync(batchRequest, JSON.stringify({ operation: 'decrypt', value: [unicodeToken, 'enc1:bad', response.value], secret: readSecret(config).toString('hex') }));
  request(batchRequest);
  assert.deepEqual(JSON.parse(fs.readFileSync(batchRequest + '.out', 'utf8')), {
    ok: true, value: [unicodeText, null, 'AA-BB-ab...'],
  });
  const source = path.join(directory, 'items.dm');
  fs.writeFileSync(source, `list("${response.value}", "sha256:${'a'.repeat(64)}")`);
  fs.writeFileSync(source, response.value);
  const result = spawnSync(process.execPath, [path.join(__dirname, 'crypto.cjs'), 'inspect', config, source], { encoding: 'utf8' });
  assert.equal(result.status, 0);
  const inspected = JSON.parse(result.stdout);
  assert.equal(inspected[0].key, 'AA-BB-ab...');
  assert.ok(!result.stdout.includes(readSecret(config).toString('hex')));

  const badRequest = path.join(directory, 'bad.json');
  fs.writeFileSync(badRequest, JSON.stringify({ operation: 'decrypt', value: fixture, secret_file: config }));
  request(badRequest);
  assert.deepEqual(JSON.parse(fs.readFileSync(badRequest + '.out', 'utf8')), { ok: false });
  fs.writeFileSync(config, 'LOADOUT_CKEY_SECRET invalid\n');
  assert.throws(() => readSecret(config));
});
