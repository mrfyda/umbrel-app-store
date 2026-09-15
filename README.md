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
