# Content-addressed external RSC deployment

TGS runs `prepare` before DreamMaker and `publish` after a successful compile.
`prepare` fingerprints resource files and static DM resource references, then
embeds a content-addressed URL into that deployment's DMB. It writes the define
to the ignored `.rsc-deployment.dm` rather than changing tracked source.
`publish` creates and validates the matching ZIP in the nginx directory using a
temporary file and atomic rename. If the immutable archive already contains the
same `tgstation.rsc`, it is reused. A hash mismatch fails the deployment instead
of serving the wrong resources. A publish failure fails the TGS compile, so a
DMB can never go live before its archive is available.

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
   `http://download.ss13-bluemoon.ru:8080/byond_rsc`.
3. Grant the account which runs both TGS hooks and DreamDaemon write access to
   that directory, and ensure the filesystem has at least
   `RSC_MIN_FREE_BYTES` available after publication. Both PostCompile and the
   in-game webroot transport perform write probes; failure stops CDN setup and
   the game falls back to the simple BYOND asset transport.
4. For an existing TGS instance, replace `PreCompile.sh` and upload
   `PostCompile.sh` in `Configuration/EventScripts`. New instances receive both
   scripts from `.tgs.yml`.

No production URL needs to be edited on later deployments. The old constant
`Moon-Blue.zip` may remain temporarily as a fallback, but managed builds use
names such as `Moon-Blue-<resource-input-sha256>.zip`. Code-only deployments
whose compiled RSC is unchanged reuse the same URL and preserve client caches.

The nginx `immutable` cache policy is appropriate for these names. Archives are
not pruned automatically: modification time cannot prove that an archive is no
longer referenced by an active or rollback DMB. Any external retention job must
first inventory every deployable DMB and protect all embedded archive URLs.
Both `lobby-media/` and `browser-assets/` are served below the already configured
public base URL, so no additional nginx location is needed when the publish
directory is served recursively.
