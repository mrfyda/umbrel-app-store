# ==============================================================================
# TEMPORARY — delete this directory once ghcr.io/gesellix/go-trmnl is public
# ==============================================================================
#
# go-trmnl's container image is published but not publicly pullable: the push
# succeeds, the manifest is there, but GHCR package visibility defaults to
# private and no workflow changes it, so anonymous pulls are refused. umbrelOS
# pulls anonymously. Upstream has been asked to flip it:
#
#   https://github.com/gesellix/go-trmnl/issues
#
# The *release assets* on the same repository are public, and they are the same
# binaries the image is built from. So this rebuilds the published image from
# the published binary rather than compiling anything — no Go toolchain, no
# source checkout, just a download and a copy.
#
# To undo, once the package is public: put the image reference back on the
# server service in docker-compose.yml and delete this directory. Nothing else
# in the app knows this exists.
#
# The runtime stage deliberately mirrors upstream's own Dockerfile — same
# distroless base, same listen address and data directory, same entrypoint — so
# the container behaves identically to the one that will replace it.

# Versions and checksums live in docker-compose.yml, not here, and that is
# load-bearing: umbrelOS copies the whole app directory on install but only a
# whitelist on update, and docker-compose.yml is on that whitelist while this
# directory is not. A version bump made here would reach a fresh install and
# silently skip everyone updating.
ARG VERSION
ARG CHECKSUMS_SHA256

FROM alpine:3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS fetch

ARG VERSION
ARG CHECKSUMS_SHA256

RUN apk add --no-cache ca-certificates curl

WORKDIR /out
RUN set -eu; \
    test -n "${VERSION}" || { echo "VERSION build arg is required" >&2; exit 1; }; \
    test -n "${CHECKSUMS_SHA256}" || { echo "CHECKSUMS_SHA256 build arg is required" >&2; exit 1; }; \
    \
    # The build runs on the machine the app runs on, so uname is the target.
    # This avoids depending on BuildKit's TARGETARCH being populated, which
    # needs the build to have gone through buildx.
    case "$(uname -m)" in \
      aarch64) asset="trmnld-${VERSION}-linux-arm64"  ;; \
      x86_64)  asset="trmnld-${VERSION}-linux-amd64"  ;; \
      armv7l)  asset="trmnld-${VERSION}-linux-armv7"  ;; \
      *) echo "no go-trmnl release binary for $(uname -m)" >&2; exit 1 ;; \
    esac; \
    base="https://github.com/gesellix/go-trmnl/releases/download/${VERSION}"; \
    \
    # Two steps, because the checksum file sitting next to the binary it
    # describes proves nothing on its own — whoever could swap one could swap
    # both. CHECKSUMS_SHA256 is pinned in this repository, out of band, and is
    # what makes the chain mean something: pinned hash -> checksum file ->
    # binary. One pinned value covers every architecture.
    curl -fsSL --retry 3 --retry-delay 2 -o checksums.sha256 "${base}/checksums.sha256"; \
    echo "${CHECKSUMS_SHA256}  checksums.sha256" > want-checksums.sha256; \
    sha256sum -c want-checksums.sha256; \
    \
    curl -fsSL --retry 3 --retry-delay 2 -o "${asset}" "${base}/${asset}"; \
    # Pull this asset's line out rather than using `sha256sum -c --ignore-
    # missing`, which is a GNU coreutils flag that Alpine's busybox lacks.
    expected="$(awk -v f="${asset}" '$2 == f { print $1 }' checksums.sha256)"; \
    test -n "${expected}" || { echo "no checksum listed for ${asset}" >&2; exit 1; }; \
    echo "${expected}  ${asset}" > want-binary.sha256; \
    sha256sum -c want-binary.sha256; \
    \
    install -m 0755 "${asset}" /out/trmnld; \
    rm -f "${asset}" checksums.sha256 want-checksums.sha256 want-binary.sha256; \
    /out/trmnld --help >/dev/null 2>&1 || true

# Pre-created so the image is complete on its own, though in this app the path
# is a bind mount from APP_DATA_DIR and Docker creates it anyway. Owned by the
# uid docker-compose.yml runs this as, not distroless' own 65532.
RUN mkdir -p /data && chown 1000:1000 /data

# Same base as upstream. distroless/static carries CA certificates, which the
# weather and calendar plugins need for outbound HTTPS; the binary is static
# and embeds its own timezone database.
FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab

COPY --from=fetch /out/trmnld /usr/local/bin/trmnld
COPY --from=fetch --chown=1000:1000 /data /data

ENV TRMNL_LISTEN=":8080" \
    TRMNL_DATA_DIR="/data"
VOLUME ["/data"]
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/trmnld"]
