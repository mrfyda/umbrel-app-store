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
  M3U, XMLTV or an HDHomeRun tuner. All-in-one image, sleeps when idle.
  ([source](https://github.com/Dispatcharr/Dispatcharr))
- **Karaoke Eternal** — karaoke parties where guests queue songs from their
  own phones. Sleeps when idle.
  ([source](https://github.com/bhj/KaraokeEternal))

## A note on the sleeping apps

Dispatcharr and Karaoke Eternal each run a [Lazytainer](https://github.com/vmorganp/Lazytainer)
sidecar that stops the app container once its port goes quiet and starts it
again on the next connection. Two consequences worth knowing before you
install them:

- **The first request after a sleep fails.** Nothing is listening yet, so
  umbrelOS shows its "Oops, there was an error" page. Wait for the cold start
  and reload. umbrelOS' gateway does not retry or show a waiting page.
- **Lazytainer needs the host's Docker socket**, which is effectively host
  root. That is a deliberate trade and it is why these apps are here rather
  than in the official Umbrel App Store, whose packaging rules forbid it.
