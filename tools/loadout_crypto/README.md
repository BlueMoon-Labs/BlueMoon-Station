# Loadout encryption

New IDs use `enc1:` with AES-256-GCM (32-byte key, random 12-byte nonce,
16-byte authentication tag). The encoded payload is nonce + ciphertext + tag,
in canonical unpadded base64url. AAD is the UTF-8 string `bluemoon/loadout/enc1`.
The implementation uses [Node.js crypto](https://nodejs.org/api/crypto.html).
Node.js 18+ must be available to the **running game server**, as well as during development.
No npm packages are required.

Both accounts and arbitrary text use the same `encrypt` and `decrypt` operations.
Text is limited to 256 Unicode characters, not UTF-8 bytes. A `decrypt` request
with an array of IDs decrypts them in a batch, returning null for invalid entries.

The server-only key is configured in `config/entries/donator.txt`:

```text
LOADOUT_CKEY_SECRET <64 hex characters>
LOADOUT_CRYPTO_NODE node
```

Keep the real `LOADOUT_CKEY_SECRET` only in the deployment copy of the config;
the placeholder in the repository must remain commented out. Replacing or losing
the key makes existing `enc1:` IDs unreadable. `LOADOUT_CRYPTO_NODE` may be a
Node.js executable name or a full path without quotes or extra arguments.

The DM bridge reads the key through `CONFIG_GET` and sends it to the local helper
through a short-lived request file. The request and response files are deleted
after each operation and must be protected with the server's normal filesystem
permissions. If the server process is terminated between writing and cleanup,
the request file may remain in `tmp/` and contain the key; remove leftover
`loadout_crypto_*.json` files before sharing or backing up the directory. The key
is never printed to game logs or returned to clients.

`[SHOW]` now returns an encrypted ID; absent/broken config produces an error,
never an unencrypted fallback. In DM, `gear_ckey_id(key)` encrypts the original
spelling, and `gear_ckey_from_id(id)` decrypts it (or returns null on failure).
Whitelist checks normalize the decrypted key, preserving account identity across
case/punctuation changes. Keep the complete `enc1:` prefix when copying an ID.
Results are cached and the cache is discarded when the configured secret changes.
All encrypted whitelist entries are decrypted in one batch at loadout initialization.

Server-side inspection, with access to the private config:

The standalone CLI accepts a private file containing one line in the form
`LOADOUT_CKEY_SECRET <64 hex characters>`. Keep that file outside the repository.

```sh
node tools/loadout_crypto/crypto.cjs encrypt config/loadout_secret.txt "AA-BB-ab"
node tools/loadout_crypto/crypto.cjs decrypt config/loadout_secret.txt "enc1:..."
node tools/loadout_crypto/crypto.cjs inspect config/loadout_secret.txt modular_bluemoon/fluffs/code/donator.dm
```

`inspect` outputs each distinct encrypted ID with its original key or an error. It does not
edit the input file. Treat the output as private: it reveals the account names.
Existing plaintext entries continue to work.

Tests: `node --test tools/loadout_crypto/crypto.test.cjs`, plus the DM
`loadout_ckey_id`, `loadout_ckey_whitelist` and `loadout_ckey_encryption` unit tests.
