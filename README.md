# mrfyda's Umbrel app store

A [community app store](https://github.com/getumbrel/umbrel-community-app-store)
for umbrelOS.

## Adding it

In the Umbrel UI: **App Store → ⋮ → Community App Stores**, then paste this
repository's URL.

## Apps

- **rs-matter-server** — a Matter controller server in Rust.
  ([source](https://github.com/mrfyda/rs-matter-server))
- **Dispatcharr** — IPTV, EPG and VOD manager with M3U, XMLTV and HDHomeRun
  outputs. ([source](https://github.com/Dispatcharr/Dispatcharr))
- **Karaoke Eternal** — karaoke parties where guests queue songs from their
  phones. ([source](https://github.com/bhj/KaraokeEternal))
- **TRMNL** — a self-hosted BYOS for TRMNL e-ink displays, bundled with a
  Home Assistant screenshotter and a Visionect Joan 6 bridge.
  ([source](https://github.com/gesellix/go-trmnl))
- **Minecraft** — a Fabric Minecraft server behind Lazymc.
  ([source](https://github.com/itzg/docker-minecraft-server))

## A note on sleeping apps

Dispatcharr, Karaoke Eternal, and Minecraft use a Lazytainer sidecar that stops
the app container when its port is idle and starts it again on the next
connection. The first request after sleep fails while the container starts;
wait briefly and reload. An open browser tab keeps a web app awake.

These sidecars need the host Docker socket, which is effectively host root.
That tradeoff is why these apps are in this community store rather than the
official Umbrel App Store.
