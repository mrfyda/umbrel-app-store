# Repository guidance

This repository contains manifests and Compose stacks for a private Umbrel
community app store. Keep app metadata in each app's `umbrel-app.yml`, runtime
configuration in `docker-compose.yml`, and artwork beside the manifest.

## App changes

- Keep the manifest name, README catalog entry, and user-facing description in
  sync.
- Use a locally committed SVG icon and reference it with the app's raw GitHub
  URL. Keep the icon square, opaque, and full-bleed; embed any raster source in
  the SVG if the upstream asset is only available as a bitmap.
- Treat every store-owned packaging change as versioned work. App versions track
  the upstream release, and packaging-only changes append a letter suffix:
  `0.31.0` becomes `0.31.0a`, then `b`, and so on. Increment the suffix for
  each later packaging change; reset to the bare upstream version when upstream
  releases a new version. Umbrel compares manifest versions as strings for
  update availability, so reusing an installed version will strand the fix.
- Pin container images by digest when the upstream registry provides one.
- Preserve security warnings for Docker socket mounts, offline authentication,
  public ports, and host networking.

## Documentation

Keep `README.md` short: explain how to add the store and list the apps. Put
implementation rationale in code comments or a focused document only when it
helps maintainers make a decision that cannot be recovered by inspecting files.
Manifest `releaseNotes` describe the current version only. Replace them when
cutting a new release; do not carry forward a cumulative changelog.

## Validation

Before handoff, inspect `git diff`, validate YAML, check that every manifest
icon URL points at a tracked SVG file, and verify Compose references only files
that remain in the app directory. For umbrelOS 2.0 apps, put user-editable
configuration in manifest `environment` settings (or service-specific 2.0
Advanced settings when two services need the same variable name) and remove
obsolete 1.x file fallbacks.
