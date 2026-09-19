# Sourced by umbrelOS before it runs docker compose, so anything exported here
# is available for ${...} interpolation in docker-compose.yml. It is the only
# way to get a value into the joan service on umbrelOS 1.x: per-app settings
# arrived in 2.0, and unlike the other containers the bridge is a scratch image
# with no shell, so it cannot read a config file for itself the way screen-sync
# reads sync.env.
#
# Write the panel's identity into data/joan/joan.env:
#
#   JOAN_DEVICE_ID=AA:BB:CC:DD:EE:FF
#   JOAN_ACCESS_TOKEN=the-api-key-go-trmnl-issued
#
# On umbrelOS 2.0 the app's settings still win over anything set here, because
# umbreld writes those into a compose override applied after docker-compose.yml.

# EXPORTS_APP_DATA_DIR is only set on umbrelOS versions that support relocating
# app data; the fallback is what every official app uses.
EXPORTS_DATA_ROOT="${EXPORTS_APP_DATA_DIR:-${EXPORTS_APP_DIR}/data}"
TRMNL_JOAN_ENV="${EXPORTS_DATA_ROOT}/joan/joan.env"

# Read rather than source. This file is sourced into the shell that goes on to
# start every app, so executing user-supplied content here could clobber
# unrelated variables or, under set -e, abort a startup that has nothing to do
# with this app. Pulling out the two keys by name cannot do either. Surrounding
# quotes are tolerated because writing them is the natural instinct.
trmnl_read_setting() {
  local key="${1}" file="${2}" value=""
  [[ -f "${file}" ]] || return 0
  value="$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "${file}" | tail -n 1 | cut -d= -f2-)"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  value="${value#\"}" ; value="${value%\"}"
  value="${value#\'}" ; value="${value%\'}"
  printf '%s' "${value}"
}

export JOAN_DEVICE_ID="$(trmnl_read_setting JOAN_DEVICE_ID "${TRMNL_JOAN_ENV}")"
export JOAN_ACCESS_TOKEN="$(trmnl_read_setting JOAN_ACCESS_TOKEN "${TRMNL_JOAN_ENV}")"
