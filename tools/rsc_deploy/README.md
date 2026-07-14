# Content-addressed external RSC deployment

TGS runs `prepare` before DreamMaker and `publish` after a successful compile.
`prepare` fingerprints resource files, static DM resource references and
compile-time `#define`/`#undef` configuration, then embeds one or more
content-addressed URLs into that deployment's DMB. It writes the defines to the
ignored `.rsc-deployment.dm` rather than changing tracked source. A small
`.rsc-input-cache.json` beside the persistent host config reuses Git blob
results, so unchanged `.dmm` files are not reparsed and unchanged resources are
not rehashed on every deployment.
`publish` creates and validates the matching ZIP in the nginx directory using a
temporary file and atomic rename. DreamMaker embeds compilation timestamps in
`tgstation.rsc`, so repeated builds from identical inputs are not bytewise
reproducible. An existing archive selected by the same input fingerprint is
therefore reused when its uncompressed RSC size matches; both SHA-256 digests
are recorded for diagnostics. A size mismatch catches the normal add/remove
case and fails the deployment instead of reusing an archive selected by an
unexpected stale fingerprint. Normal conditional-build variants get distinct
names before compilation because their compiler definitions participate in the
fingerprint. A publish failure fails the TGS compile, so a DMB can never go live
before its archive is available.

The same publish step copies lobby backgrounds and lobby music to
content-addressed files below `lobby-media/`. It writes
`config/lobby_media.json`, which lets the lobby use direct HTTP URLs instead of
adding these files to BYOND's dynamic resource cache. It also configures the
built-in webroot transport below `browser-assets/`, moving TGUI, fonts and other
registered browser assets away from DreamDaemon.

## One-time host setup

1. Copy `config/rsc_deploy.env.example` to the instance's persistent
   `Configuration/GameStaticFiles/config/rsc_deploy.env`.
2. Change `RSC_PUBLISH_DIR` to the nginx directory behind
   `RSC_PUBLIC_BASE_URL`.
3. Grant the account which runs both TGS hooks and DreamDaemon write access to
   that directory, and ensure the filesystem has at least
   `RSC_MIN_FREE_BYTES` available after publication. Both PostCompile and the
   in-game webroot transport perform write probes; failure stops CDN setup and
   the game falls back to the simple BYOND asset transport. A later individual
   asset-copy failure also switches SSassets to the simple transport instead of
   returning a CDN URL whose file was not written.
4. For an existing TGS instance, replace the matching `PreCompile` and
   `PostCompile` scripts (`.sh` on Linux, `.bat` on Windows) in
   `Configuration/EventScripts`. New instances receive both scripts from
   `.tgs.yml`. The Windows hooks use `tools/bootstrap/python.bat`, which installs
   the repository's pinned portable Python on first use; no system Python in
   `PATH` is required.

## CORS for browser assets

The `browser-assets/` files are fetched by TGUI from a different origin. That
HTTP location must provide CORS headers or TGUI can open with missing scripts,
fonts, images, or styles. For nginx, a minimal location is:

```nginx
location /byond_rsc/browser-assets/ {
    alias /var/www/byond_rsc/browser-assets/;
    add_header Access-Control-Allow-Origin "*" always;
    add_header Vary "Origin" always;
}
```

Adjust both paths to match `RSC_PUBLIC_BASE_URL` and `RSC_PUBLISH_DIR`. Lobby
backgrounds and music use normal `<img>` and `<audio>` loading, so their
`lobby-media/` location does not need CORS for playback. The RSC ZIP itself also
does not need browser CORS headers.

With webroot enabled, TGUI bundles, the stat browser, tooltip HTML and their
static dependencies are loaded from `browser-assets/`. DreamDaemon still sends
live UI state, chat messages and tooltip content; only immutable files belong
on the CDN. The legacy chat channel remains active during TGUI startup or after
a panel failure, but is not sent a duplicate copy once TGUI is ready.

## RSC mirrors

Set `RSC_PUBLIC_MIRROR_BASE_URLS` to a semicolon-separated list of HTTP(S) base
URLs when the same immutable archives are available through multiple hosts.
The generated DMB rotates connecting clients across the primary URL and these
mirrors, using the same behavior as `EXTERNAL_RSC_URLS` for unmanaged builds.

PostCompile writes only `RSC_PUBLISH_DIR`; it does not upload to remote mirrors.
Each configured URL must therefore be an alias, shared-storage frontend, or a
mirror synchronized before TGS activates the new DMB. Do not configure a mirror
which can lag behind publication, because clients assigned to it will fall back
to resource delivery through DreamDaemon.

No production URL needs to be edited on later deployments. The unmanaged config
retains the download-host archive alias as its fallback; managed builds
use names such as `Moon-Blue-<archive-input-sha256>.zip`. That hash covers
resource/build inputs and a stable deployment namespace derived from the
persistent config path, preventing separate TGS instances on one publish
directory from colliding. `RSC_DEPLOYMENT_NAMESPACE` can override the derived
namespace for hosts which need an explicit stable identity. Code-only deployments
whose referenced resource inputs and compiled RSC size are unchanged reuse the
same URL and preserve client caches. Unreferenced media such as TGUI source and
browser bundles does not participate in this fingerprint.

The nginx `immutable` cache policy is appropriate for these names. PostCompile
automatically inventories `.rsc-deploy.json` next to every DMB in the TGS `Game`
directory and protects all referenced archives before pruning. This follows the
TGS deployment lifecycle: directories remain present while a compile job is the
latest or is locked by a running DreamDaemon, and are deleted after the locks
are released. Cleanup keeps two additional unreferenced archives and applies a
24-hour grace period by default. It aborts without deleting anything if a DMB
has no manifest, a manifest cannot be read, or the deployment root is unknown.

Lobby and browser content stores are pruned under the same grace policy.
PostCompile records every lobby file in the deployment manifest. At runtime the
webroot transport writes a per-DMB browser asset inventory below
`browser-assets/.manifests/`; files referenced by any deployable DMB inventory
are protected. During rollout, an older DMB without these fields disables the
corresponding cleanup instead of making assumptions. Turning off lobby
publication removes `config/lobby_media.json`, and turning off managed webroot
configuration removes only the managed override block, restoring the
operator-authored `ASSET_*` values left in place.

`RSC_DEPLOYMENT_ROOTS` is inferred from the normal
`Configuration/GameStaticFiles/config` layout. If multiple TGS instances share
one `RSC_PUBLISH_DIR`, configure every absolute `Game` directory as a
semicolon-separated list so an archive used by another instance is protected.
Both `lobby-media/` and `browser-assets/` are served below the already configured
public base URL, so no additional nginx location is needed when the publish
directory is served recursively.
