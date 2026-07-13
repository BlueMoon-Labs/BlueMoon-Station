# Versioned external RSC deployment

TGS runs `prepare` before DreamMaker and `publish` after a successful compile.
`prepare` embeds a unique URL containing the source revision and build timestamp
into that deployment's DMB. `publish` creates and validates the matching ZIP in
the nginx directory using a temporary file and atomic rename. A publish failure
fails the TGS compile, so a DMB can never go live before its archive is available.

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
3. Grant the TGS service account write access to that directory.
4. For an existing TGS instance, replace `PreCompile.sh` and upload
   `PostCompile.sh` in `Configuration/EventScripts`. New instances receive both
   scripts from `.tgs.yml`.

No production URL needs to be edited on later deployments. The old constant
`Moon-Blue.zip` may remain temporarily as a fallback, but managed builds use
names such as `Moon-Blue-363714a6137e-20260713T002242Z.zip`.

The nginx `immutable` cache policy is appropriate for these versioned names.
Keep at least two archives so the active and previous deployments can coexist.
Both `lobby-media/` and `browser-assets/` are served below the already configured
public base URL, so no additional nginx location is needed when the publish
directory is served recursively.
