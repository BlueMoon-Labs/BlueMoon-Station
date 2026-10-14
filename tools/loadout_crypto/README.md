# Loadout encryption

New IDs use `enc1:` with AES-256-GCM (32-byte key, random 12-byte nonce,
16-byte authentication tag). The encoded payload is nonce + ciphertext + tag,
in canonical unpadded base64url. AAD is the UTF-8 string `bluemoon/loadout/enc1`.
The implementation uses [Node.js crypto](https://nodejs.org/api/crypto.html).
Node.js must be available to the **running game server**, as well as during development.
Use a supported LTS release. The helper avoids `node:` imports and the newer
`base64url` Buffer encoding to tolerate older server installations; this does
not change the encryption or the token format. The test runner needs Node.js 18+.
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
`initialize_global_whitelist_cache()` warms loadout, accessory, bark, AI screen,
borg skin and hotel whitelists in a single deduplicated batch after config loading
and loadout initialization. Whitelists are read from live datums, including
configured loadout overrides. Hotel templates are prepared before the batch;
their subsystem reuses the prepared list during its later initialization. The original lists
retain their encrypted IDs; only the private crypto cache contains the decrypted text.

`/datum/sprite_accessory.ckeys_allowed` uses the same whitelist check as
`/datum/gear.ckeywhitelist`. Both lists accept original account names, normalized
ckeys, and `enc1:` IDs encrypted from either spelling, including mixed lists.
For example, `list("AA-BB-ab", "anotheraccount", "enc1:...")` may be used
for a personal accessory. Use a complete ID obtained with `[SHOW]` or the debug
verb. Checks compare normalized identities after authenticated decryption and
reuse the crypto cache. A null or empty list allows everyone; an unreadable ID
never grants access. This applies to character preferences and in-round
appearance customization.

The same formats are supported by `/datum/bark.ckeys_allowed`,
`/datum/ai_donator_screen.ckey_whitelist`, `/datum/borg_donator_skin.ckey_whitelist`
and `/datum/map_template/hilbertshotel.ckeywhitelist`. Their access rules are
preserved: a null bark list is public but an explicit empty list denies access;
empty AI screen lists deny access; borg skins require either whitelist membership
or donor group membership; empty hotel lists are public. Hotel template access
is checked on the server for both selection and check-in, and the UI receives
only the availability decision instead of the whitelist.

## In-round diagnostics

After deploying this build, use **Debug.2) Info → Loadout crypto** with debug rights.
Enter a short test string, then decrypt the returned ID. Both operations bypass
the cache and privately report diagnostics, including `node_version` when the
helper responds and `exit_code` when the shell returns. The debug request also
includes the original helper `error_detail` and shell `stderr`; ordinary callers
never request or receive these fields. Treat the debug output as private because
it can contain local paths or runtime messages. Temporary helper failures are not
cached as invalid IDs.

| Error | Meaning / next check |
| --- | --- |
| `config_unavailable` | Configuration has not been initialized. |
| `secret_missing` / `invalid_secret_config` | The loaded `LOADOUT_CKEY_SECRET` must contain exactly 64 hex characters. |
| `invalid_node_executable` | Empty or unsupported executable path in `LOADOUT_CRYPTO_NODE`. |
| `helper_missing` | `tools/loadout_crypto/crypto.cjs` is absent from the running server's working directory. Include it in deployment. |
| `rustg_rng_failed` | The installed rust-g cannot generate a request ID. Working SHA-256 alone does not verify the RNG export. |
| `request_write_failed` | The game cannot write the request under `tmp/`. |
| `shell_failed` | BYOND returned `null` and could not launch the shell. On a Linux TGS deployment, check that the security level is `Trusted`; also check that `/bin/sh` exists and the server process is allowed to execute it. |
| `node_exit_failed` | Nonzero shell status. On Linux, 127 usually means command not found; 126 usually means it cannot be executed. Other codes can indicate an incompatible runtime or response write failure. |
| `response_missing` / `invalid_response` | No valid JSON response; check shell permissions, working directory and write access. |
| `stderr_code=node_not_found` | The shell started, but could not find the configured Node executable. Set `LOADOUT_CRYPTO_NODE` to an absolute executable path. |
| `stderr_code=permission_denied` | The shell or Node executable is not permitted to run. Check TGS security level and executable permissions. |
| `stderr_code=node_not_executable` | The configured file is not a runnable Linux Node binary (wrong architecture or missing execute permission). |
| `stderr_code=process_stderr` | The process wrote an unclassified error; debug diagnostics include the raw text in `stderr`. |
| `authentication_failed` | The ID was changed or encrypted with another key. |
| `invalid_token` / `invalid_text` / `invalid_account` / `invalid_request` | The input is invalid for the requested operation. |
| `helper_failed` | The helper started but failed internally; debug diagnostics include the original error in `error_detail`. Ordinary requests receive only the fixed code. |

The TGS build uses `tools/bootstrap/node` with a separate cache. A successful
TGUI build does **not** put Node on the game process's PATH. The repository's
`tools/build/build.js` records its actual `process.execPath` in the generated
`tools/loadout_crypto/node_path.txt` during TGUI and DM builds, even when their
compiled outputs are up to date. This also works with older installed TGS
`Configuration/EventScripts/PreCompile.sh` copies that invoke this build script;
the installed hook does not need updating for path recording.

When `LOADOUT_CRYPTO_NODE` is left at its default `node`, the game uses this
generated path. An explicit executable path in config continues to override it.
Deploy the build output and repository files together so the generated path
file is available to the game. The build log prints `Loadout crypto Node: ...`.
In-round diagnostics show `node_executable`, `node_source` (`build`, `config`,
or `PATH`) and, for automatic selection, `node_path_file` (`loaded`, `missing`,
or `invalid`). A missing/invalid path file falls back to `node` from PATH.

`rustg_hash_string` is a one-way hash API, not reversible encryption. Replacing
this bridge with a native macro requires an AES-GCM export in the installed
rust-g (or a separate native library) and deployment of that binary. A DM macro
alone cannot add an export to the server's existing `.so`.

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
