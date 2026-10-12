'use strict';

// Node.js built-ins only. No account name, token or secret is interpolated into a shell command.
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const PREFIX = 'enc1:';
const AAD = Buffer.from('bluemoon/loadout/enc1', 'utf8');
const MAX_KEY_BYTES = 256;

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

function validAccount(value) {
  // BYOND account keys are ASCII; keep their original case, spacing and punctuation.
  return typeof value === 'string' && Buffer.byteLength(value, 'utf8') <= MAX_KEY_BYTES
    && /^[\x20-\x7e]+$/.test(value) && /[a-zA-Z0-9]/.test(value);
}

function encrypt(key, secret) {
  if (!validAccount(key)) throw new Error('invalid_account');
  const nonce = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', secret, nonce, { authTagLength: 16 });
  cipher.setAAD(AAD);
  const ciphertext = Buffer.concat([cipher.update(key, 'utf8'), cipher.final()]);
  return PREFIX + Buffer.concat([nonce, ciphertext, cipher.getAuthTag()]).toString('base64url');
}

function encryptText(value, secret) {
  if (typeof value !== 'string' || !value.length || Buffer.byteLength(value, 'utf8') > MAX_KEY_BYTES) {
    throw new Error('invalid_text');
  }
  const nonce = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', secret, nonce, { authTagLength: 16 });
  cipher.setAAD(AAD);
  const ciphertext = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  return PREFIX + Buffer.concat([nonce, ciphertext, cipher.getAuthTag()]).toString('base64url');
}

function decrypt(token, secret) {
  if (typeof token !== 'string' || !/^enc1:[A-Za-z0-9_-]+$/.test(token) || token.length > 384) {
    throw new Error('invalid_token');
  }
  const encoded = token.slice(PREFIX.length);
  const payload = Buffer.from(encoded, 'base64url');
  if (payload.length < 29 || payload.length > 28 + MAX_KEY_BYTES
      || payload.toString('base64url') !== encoded) throw new Error('invalid_token');
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
  if (!validAccount(key) || !Buffer.from(key, 'utf8').equals(plaintext)) throw new Error('invalid_account');
  return key;
}

function decryptText(token, secret) {
  if (typeof token !== 'string' || !/^enc1:[A-Za-z0-9_-]+$/.test(token) || token.length > 384) {
    throw new Error('invalid_token');
  }
  const encoded = token.slice(PREFIX.length);
  const payload = Buffer.from(encoded, 'base64url');
  if (payload.length < 29 || payload.length > 28 + MAX_KEY_BYTES
      || payload.toString('base64url') !== encoded) throw new Error('invalid_token');
  const decipher = crypto.createDecipheriv('aes-256-gcm', secret, payload.subarray(0, 12), { authTagLength: 16 });
  decipher.setAAD(AAD);
  decipher.setAuthTag(payload.subarray(-16));
  try {
    return Buffer.concat([decipher.update(payload.subarray(12, -16)), decipher.final()]).toString('utf8');
  } catch {
    throw new Error('authentication_failed');
  }
}

function decryptMany(tokens, secret) {
  if (!Array.isArray(tokens) || tokens.length > 10000) throw new Error('invalid_request');
  return tokens.map((token) => {
    try { return decrypt(token, secret); } catch { return null; }
  });
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
  // This file contains the secret FILE PATH, not a copy of the secret.
  let result;
  try {
    const data = JSON.parse(fs.readFileSync(filename, 'utf8'));
    const secret = data.secret ? parseSecret(data.secret) : readSecret(data.secret_file);
    let value;
    if (data.operation === 'encrypt') value = encrypt(data.value, secret);
    else if (data.operation === 'decrypt') value = decrypt(data.value, secret);
    else if (data.operation === 'encrypt_text') value = encryptText(data.value, secret);
    else if (data.operation === 'decrypt_text') value = decryptText(data.value, secret);
    else if (data.operation === 'decrypt_many') value = decryptMany(data.value, secret);
    else throw new Error('invalid_request');
    result = { ok: true, value };
  } catch {
    // Never serialize native errors, input values, filenames or the secret into game logs.
    result = { ok: false };
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

module.exports = { encrypt, decrypt, encryptText, decryptText, decryptMany, readSecret, initSecret, request };
