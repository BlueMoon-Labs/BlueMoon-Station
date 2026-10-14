'use strict';

// Node.js built-ins only. No account name, token or secret is interpolated into a shell command.
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const PREFIX = 'enc1:';
const AAD = Buffer.from('bluemoon/loadout/enc1', 'utf8');
const MAX_TEXT_CHARS = 256;
const MAX_TEXT_BYTES = MAX_TEXT_CHARS * 4;
const MAX_TOKEN_CHARS = 5 + Math.ceil((28 + MAX_TEXT_BYTES) * 4 / 3);

// Keep the enc1 wire format without requiring Node's newer base64url encoding.
function base64url(value) {
  return value.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

// Only these application-defined codes may cross the process boundary.
const ERROR_CODES = new Set(['invalid_secret_config', 'invalid_text', 'invalid_token',
  'invalid_request', 'authentication_failed', 'invalid_account']);

function readSecret(filename) {
  const contents = fs.readFileSync(filename, 'utf8');
  const lines = contents.split(/\r?\n/).map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'));
  if (lines.length !== 1 || !/^LOADOUT_CKEY_SECRET [a-fA-F0-9]{64}$/.test(lines[0])) {
    throw new Error('invalid_secret_config');
  }
  return Buffer.from(lines[0].slice('LOADOUT_CKEY_SECRET '.length), 'hex');
}

function parseSecret(value) {
  if (typeof value !== 'string') {
    throw new Error('invalid_secret_config');
  }
  const hex = value.startsWith('LOADOUT_CKEY_SECRET ') ? value.slice('LOADOUT_CKEY_SECRET '.length) : value;
  if (!/^[a-fA-F0-9]{64}$/.test(hex)) throw new Error('invalid_secret_config');
  return Buffer.from(hex, 'hex');
}

function encrypt(value, secret) {
  if (typeof value !== 'string' || !value.length || Array.from(value).length > MAX_TEXT_CHARS) {
    throw new Error('invalid_text');
  }
  const nonce = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', secret, nonce, { authTagLength: 16 });
  cipher.setAAD(AAD);
  const ciphertext = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  return PREFIX + base64url(Buffer.concat([nonce, ciphertext, cipher.getAuthTag()]));
}

function decrypt(token, secret) {
  if (Array.isArray(token)) {
    if (token.length > 10000) throw new Error('invalid_request');
    return token.map((item) => {
      if (Array.isArray(item)) return null;
      try { return decrypt(item, secret); } catch (error) {
        if (ERROR_CODES.has(error.message)) return null;
        // A runtime failure must not poison the DM cache for every ID in a batch.
        throw error;
      }
    });
  }
  if (typeof token !== 'string' || !/^enc1:[A-Za-z0-9_-]+$/.test(token) || token.length > MAX_TOKEN_CHARS) {
    throw new Error('invalid_token');
  }
  const encoded = token.slice(PREFIX.length);
  const payload = Buffer.from(encoded.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
  if (payload.length < 29 || payload.length > 28 + MAX_TEXT_BYTES
      || base64url(payload) !== encoded) throw new Error('invalid_token');
  const decipher = crypto.createDecipheriv('aes-256-gcm', secret, payload.subarray(0, 12), { authTagLength: 16 });
  decipher.setAAD(AAD);
  decipher.setAuthTag(payload.subarray(-16));
  // Never return plaintext until GCM authentication has succeeded.
  let plaintext;
  try {
    plaintext = Buffer.concat([decipher.update(payload.subarray(12, -16)), decipher.final()]);
  } catch {
    throw new Error('authentication_failed');
  }
  const key = plaintext.toString('utf8');
  if (!key.length || Array.from(key).length > MAX_TEXT_CHARS || !Buffer.from(key, 'utf8').equals(plaintext)) throw new Error('invalid_account');
  return key;
}

function initSecret(filename) {
  fs.mkdirSync(path.dirname(filename), { recursive: true });
  fs.writeFileSync(filename,
    '# Private loadout encryption key. Back up separately; never commit or share.\n'
    + `LOADOUT_CKEY_SECRET ${crypto.randomBytes(32).toString('hex')}\n`,
    { encoding: 'utf8', mode: 0o600, flag: 'wx' });
}

function request(filename) {
  // The DM side supplies only a generated filename, never shell-interpolated player input.
  // DM requests contain the configured secret and are removed by the caller.
  let result;
  let diagnostic = false;
  try {
    const data = JSON.parse(fs.readFileSync(filename, 'utf8'));
    // DM json_encode represents TRUE as 1 rather than a JSON boolean.
    diagnostic = data.diagnostic === true || data.diagnostic === 1;
    const secret = data.secret ? parseSecret(data.secret) : readSecret(data.secret_file);
    let value;
    if (data.operation === 'encrypt') value = encrypt(data.value, secret);
    else if (data.operation === 'decrypt') value = decrypt(data.value, secret);
    else throw new Error('invalid_request');
    result = { ok: true, value, node_version: process.version };
  } catch (error) {
    // Never serialize native errors, input values, filenames or the secret into game logs.
    result = { ok: false, error: ERROR_CODES.has(error.message) ? error.message : 'helper_failed',
      node_version: process.version };
    if (diagnostic) result.error_detail = String(error && error.message ? error.message : error);
  }
  fs.writeFileSync(filename + '.out', JSON.stringify(result), { encoding: 'utf8', mode: 0o600, flag: 'wx' });
}

function main(args) {
  const [operation, filename, value] = args;
  if (operation === 'request' && args.length === 2) {
    request(filename);
    return;
  }
  if (operation === 'init' && args.length === 2) {
    initSecret(filename);
    console.log('Private loadout key created. Existing files are never overwritten.');
    return;
  }
  if (!['encrypt', 'decrypt', 'inspect'].includes(operation) || args.length !== 3) {
    throw new Error('usage');
  }
  const secret = readSecret(filename);
  if (operation === 'encrypt') console.log(encrypt(value, secret));
  if (operation === 'decrypt') console.log(decrypt(value, secret));
  if (operation === 'inspect') {
    const contents = fs.readFileSync(value, 'utf8');
    const tokens = [...new Set(contents.match(/enc1:[A-Za-z0-9_-]+/g) || [])];
    console.log(JSON.stringify(tokens.map((id) => {
      try { return { id, key: decrypt(id, secret) }; }
      catch { return { id, error: 'cannot_decrypt' }; }
    }), null, 2));
  }
}

if (require.main === module) {
  try { main(process.argv.slice(2)); }
  catch {
    console.error('Loadout crypto failed. Check command, private config and ID; existing key files are never overwritten.');
    process.exitCode = 1;
  }
}

module.exports = { encrypt, decrypt, readSecret, initSecret, request };
