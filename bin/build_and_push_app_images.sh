#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker compose -f "${root_dir}/apps/giocci_client/docker-compose.yml" build giocci_client
docker compose -f "${root_dir}/apps/giocci_client/docker-compose.yml" push giocci_client

docker compose -f "${root_dir}/apps/giocci_relay/docker-compose.yml" build giocci_relay
docker compose -f "${root_dir}/apps/giocci_relay/docker-compose.yml" push giocci_relay

docker compose -f "${root_dir}/apps/giocci_engine/docker-compose.yml" build giocci_engine
docker compose -f "${root_dir}/apps/giocci_engine/docker-compose.yml" push giocci_engine
