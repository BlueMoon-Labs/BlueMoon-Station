# Loadout encryption

New IDs use `enc1:` with AES-256-GCM (32-byte key, random 12-byte nonce,
16-byte authentication tag). The encoded payload is nonce + ciphertext + tag,
in canonical unpadded base64url. AAD is the UTF-8 string `bluemoon/loadout/enc1`.
The implementation uses [Node.js crypto](https://nodejs.org/api/crypto.html).
Node.js 18+ must be available to the **running game server**, as well as during development.
No npm packages are required.

From the repository/game directory, generate the secret once:

```sh
node tools/loadout_crypto/crypto.cjs init config/loadout_secret.txt
```

`config/loadout_secret.txt` is a private config file containing
`LOADOUT_CKEY_SECRET <64 hex characters>`. Git ignores it. The helper creates it
with mode 0600 on POSIX, never overwrites it, and never prints the key.
It is read by the crypto helper, not included through `$include` in the general
configuration loader, so its value cannot leak through config error logging or VV.
If using another config directory, create/copy the secret there and exclude it
from your deployment repository too. Back up this file separately and transfer it
securely to production. Losing/replacing it makes existing `enc1:` IDs unreadable.

Optional settings in `entries/donator.txt`:

```text
LOADOUT_CKEY_SECRET_FILE loadout_secret.txt
LOADOUT_CRYPTO_NODE node
```

The secret filename is relative to the active config directory. The second option
is a Node.js executable name/full path, without quotes or extra arguments.
BYOND must run in trusted mode to invoke the helper. Its command line contains
only a generated request filename. The private secret is never copied into request
files or command arguments. Responses are removed immediately after reading.

`[SHOW]` now returns an encrypted ID; absent/broken config produces an error,
never an unencrypted fallback. In DM, `gear_ckey_id(key)` encrypts the original
spelling, and `gear_ckey_from_id(id)` decrypts it (or returns null on failure).
Whitelist checks normalize the decrypted key, preserving account identity across
case/punctuation changes. Keep the complete `enc1:` prefix when copying an ID.
Results are cached and the cache is discarded when the secret file changes.
All encrypted whitelist entries are decrypted in one batch at loadout initialization.

Server-side inspection, with access to the private config:

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
