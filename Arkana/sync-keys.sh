#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
arkana --config-filepath Arkana/.arkana.yml --dotenv-filepath Arkana/.env
