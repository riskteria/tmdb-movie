#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

command -v arkana >/dev/null 2>&1 || { echo "error: Arkana is missing. Run: gem install arkana" >&2; exit 1; }
command -v xcodegen >/dev/null 2>&1 || { echo "error: XcodeGen is missing. Run: brew install xcodegen" >&2; exit 1; }
[ -f Arkana/.env ] || { echo "error: Arkana/.env is missing. Copy Arkana/.env.example and add the token" >&2; exit 1; }

./Arkana/sync-keys.sh
xcodegen generate
