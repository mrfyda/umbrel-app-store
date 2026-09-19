# mrfyda's Umbrel app store

A [community app store](https://github.com/getumbrel/umbrel-community-app-store)
for umbrelOS.

## Adding it

In the Umbrel UI: **App Store → ⋮ → Community App Stores**, then paste this
repository's URL.

## Apps

- **rs-matter-server** — a Matter controller server in Rust, speaking the
  WebSocket API Home Assistant's Matter integration talks to.
  ([source](https://github.com/mrfyda/rs-matter-server))
- **Dispatcharr** — IPTV, EPG and VOD manager, handing channels back out as
  M3U, XMLTV or an HDHomeRun tuner. All-in-one image plus a Valkey sidecar,
  sleeps when idle.
  ([source](https://github.com/Dispatcharr/Dispatcharr))
- **Karaoke Eternal** — karaoke parties where guests queue songs from their
  own phones. Sleeps when idle.
  ([source](https://github.com/bhj/KaraokeEternal))
- **TRMNL** — a self-hosted BYOS for TRMNL e-ink displays, plus a Home
  Assistant dashboard screenshotter and a bridge that drives a Visionect
  Joan 6 panel. go-trmnl rather than Terminus, so the server is one static
  binary over SQLite instead of Ruby, Postgres, Sidekiq and Valkey.
  ([source](https://github.com/gesellix/go-trmnl))

## Versioning

App versions track upstream, with a letter appended when this store changes
packaging without an upstream release — `0.31.0` becomes `0.31.0a`, then `b`,
and back to a bare number at the next upstream version.

The letter is load-bearing. umbrelOS decides an update exists by comparing the
manifest `version` against the installed one as plain strings
([`isAppUpdateAvailable`](https://github.com/getumbrel/umbrel/blob/master/packages/ui/src/modules/app-store/update-availability.ts)),
so a packaging fix shipped under an unchanged version reaches nobody who
already has the app. Nothing parses these as semantic versions — `version` is
declared as a free-form string in umbreld's manifest schema, and only
`manifestVersion` is semver-validated — so the suffix is safe and ordering
never matters, only difference.

## A note on the sleeping apps

Dispatcharr and Karaoke Eternal each run a [Lazytainer](https://github.com/vmorganp/Lazytainer)
sidecar that stops the app container once its port goes quiet and starts it
again on the next connection. Some consequences worth knowing before you
install them:

- **The first request after a sleep fails.** Nothing is listening yet, so
  umbrelOS shows its "Oops, there was an error" page. Wait for the cold start
  and reload. umbrelOS' gateway does not retry or show a waiting page.
- **Lazytainer needs the host's Docker socket**, which is effectively host
  root. That is a deliberate trade and it is why these apps are here rather
  than in the official Umbrel App Store, whose packaging rules forbid it.
- **An open browser tab keeps an app awake.** Both apps hold a websocket for
  as long as their page is open, and a backgrounded tab still counts. If an
  app never seems to sleep, look for a forgotten tab first.
- **The advertised timeout is a floor, not the figure.** Lazytainer only
  starts its idle countdown once its rolling traffic window is already empty,
  so after real use an app can take up to twice its configured timeout to go
  down — up to 10 minutes for Dispatcharr and 30 for Karaoke Eternal.

Both sidecars set `IPV4_DISABLED: "false"`, which reads backwards and is
deliberate. Lazytainer's own README presents `IPV4_DISABLED` / `IPV6_DISABLED`
as opt-in switches, but its code only enables a family when the variable
exists and is not `"true"`, so leaving them unset disables the open-connection
check entirely and leaves packet counting as the only signal. Setting it to
`"false"` is what turns the check on.

Karaoke Eternal needs one more thing on top of that. Its server binds IPv6
only — Node's `listen()` with no host argument takes `::`, and the app has no
setting to change it — so its connections land in a socket table Lazytainer is
not reading, and the check above sees nothing. Its sidecar therefore also
disables IPv6 in the network namespace the two share, which makes Node fall
back to binding IPv4. Dispatcharr needs none of this: its nginx opens a real
IPv4 socket of its own.

## A note on the TRMNL app

That app is three former Portainer stacks in one, and it swaps the server out
from under them. Terminus, TRMNL's reference BYOS, is five containers — a
Hanami web app, a Sidekiq worker, Postgres, Valkey and a certificate installer.
[go-trmnl](https://github.com/gesellix/go-trmnl) speaks the same device
protocol as a single static Go binary over SQLite, so seven containers become
four. Four things about that are worth knowing before you install it.

**Its server image is built on the host, temporarily.** Published and publicly
pullable are two different things on GHCR: go-trmnl's release workflow builds a
multi-arch image and the push succeeds, but package *visibility* is a separate
setting that defaults to private and no workflow changes it, so anonymous pulls
are refused — `ghcr.io/gesellix/go-trmnl` issues no anonymous pull token at all,
where every other image in this store does. umbrelOS pulls anonymously.

Upstream has been asked to make the package public. Until then the app builds
that one service itself, from the *release binary*, which is public on the same
repository and is what the image is built from anyway. No Go toolchain and no
source checkout — a download, a checksum, and a copy into the same distroless
base upstream uses. umbrelOS starts apps with `docker compose up --detach
--build`, and skips build-only services when it pre-pulls images, so the build
happens on its own.

The one thing it does need is an **absolute build context**, via
`${APP_DATA_DIR}`. umbrelOS composes an app from several files — its own
`legacy-compat/docker-compose.app_proxy.yml` first, the app's own last — and
Compose resolves relative paths against the directory of the *first* `--file`,
so a plain `./go-trmnl-image` is looked for next to umbreld's own compose
fragments and the install fails with `unable to prepare context`.

The download is pinned by the sha256 of the release's `checksums.sha256`,
recorded in `docker-compose.yml` rather than taken on trust from the file
itself — a checksum file sitting next to the binary it describes proves nothing
on its own. Both that hash and the version live in `docker-compose.yml` because
umbrelOS copies the whole app directory on install but only a whitelist on
update, and the compose file is on that whitelist while `go-trmnl-image` is not.

Undoing it is one line: put the image reference back on the `server` service —
it is kept in a comment there, digest and all — and delete `go-trmnl-image`.
Note the image tag is `0.5.0`, not `v0.5.0`; the git tag carries the `v` and
`docker/metadata-action`'s `{{version}}` pattern strips it. Release *assets*,
which the temporary build downloads, do use the `v`.

**A sync container exists because go-trmnl has no way in.** Terminus accepts
screens from outside over `POST /api/screens`, which is how the Home Assistant
screenshotter fed it. go-trmnl has no such endpoint — no webhook, and a
static-image plugin that deliberately takes a filename inside its own assets
directory rather than a URL. The gap is closed by pulling a screenshot and
posting it to the admin UI's upload form on a timer. That works for a precise
reason: the plugin declares a 24-hour cache TTL, so overwriting the file on
disk would keep serving yesterday's render, and it is the upload handler's
rewrite of the screen's settings — which nulls `rendered_hash` — that actually
invalidates the cache. It is an HTML form, not an API, so a go-trmnl upgrade
could break it. A dashboard that stops updating is the symptom.

**No LAN addresses are hardcoded**, which all three Portainer stacks needed.
The containers address each other over Umbrel's app network by name. Home
Assistant is the exception that proves it: its Umbrel app runs
`network_mode: host`, so it has no container name to resolve and never did —
it is reached at `$GATEWAY_IP`, the app network's gateway, which is the host
seen from inside. ZeroTier's official app addresses its own host-networked
service the same way. Nothing breaks when the box changes IP.

The server's own base URL is the one thing a container name could not serve,
because it has two consumers that do not share a resolver. The Joan bridge is a
container; the admin UI's screen previews are `<img>` tags in your browser
built from that same base URL. A container name leaves the previews blank, with
nothing in the server log because the browser never makes the request. So the
base URL is `$DEVICE_DOMAIN_NAME` — the device's own `.local` name, which the
browser already resolves and which n8n's official app uses for the same job —
and the bridge gets an `extra_hosts` entry mapping that name to `$GATEWAY_IP`,
since Docker's resolver forwards to the host's nameservers and those answer
ordinary DNS, not mDNS. A real TRMNL panel whose firmware skips mDNS is a third
consumer, and wants a LAN address set in the app's settings.

**One secret cannot go in the app's normal settings.** umbreld keys
manifest-declared environment variables by name alone, globally across the app
— `#resolveEnvironmentVariables()` dedupes into a flat set of names before it
ever looks at which services a name targets. Two services here genuinely read a
variable called `ACCESS_TOKEN`, holding different secrets: the Home Assistant
token and the Joan panel's device token. Only one can be declared, so the Joan
one goes under Settings → Advanced, which is keyed by service *and* name.

It is also **arm64 only**, because the screenshotter is published as separate
per-architecture images rather than one multi-arch manifest.
