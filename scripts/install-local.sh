#!/usr/bin/env bash
# Build, sign, install and launch the current checkout for local development.
# Usage: IDENTITY='Apple Development: Your Name (TEAMID)' scripts/install-local.sh [--debug]
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${IDENTITY:-}" ]]; then
  echo 'Set IDENTITY to your signing identity. List identities with: security find-identity -v -p codesigning' >&2
  exit 1
fi

scripts/bundle.sh "$@"

APP='/Applications/Leader Key.app'
if [[ -d "$APP" ]]; then
  BACKUP_DIR="$(mktemp -d "${TMPDIR:-/tmp/}leaderkey-backup.XXXXXX")"
  ditto "$APP" "$BACKUP_DIR/Leader Key.app"
  echo "previous app saved to $BACKUP_DIR/Leader Key.app"
fi

# The Xcode build used "Leader Key" as its executable name.
for process in 'Leader Key' leaderkey; do
  if pgrep -x "$process" >/dev/null; then
    pkill -TERM -x "$process"
    for attempt in {1..50}; do
      if ! pgrep -x "$process" >/dev/null; then break; fi
      sleep 0.1
    done
    if pgrep -x "$process" >/dev/null; then
      echo "$process did not quit; installation stopped" >&2
      exit 1
    fi
  fi
done

rm -rf "$APP"
ditto 'build/Leader Key.app' "$APP"
open "$APP"
echo "installed Leader Key from $(git rev-parse --short HEAD)"
