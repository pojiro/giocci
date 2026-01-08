#!/bin/bash

set -e

if [ -f "/usr/bin/docker" ]; then
  docker compose run --rm zenohd bin/test.sh
else
  zenohd &
  mix test
fi
