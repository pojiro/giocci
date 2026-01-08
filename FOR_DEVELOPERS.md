# For developers

## About test

### CI docker image

CI docker image is built by using the Dockerfile and docker-compose.yml for the `zenohd` service.

This image is built and pushed by following commands,

```bash
docker compose build zenohd
docker compose push zenohd
```

### How to test locally

```bash
./bin/test.sh
```

## How to update Giocci zenoh version

1. Update zenohex versions in each giocci_(client|relay|engine) mix.exs
2. Update zenoh version in Dockerfile and image tag in docker-compose.yml
3. Update image tag in .github/workflows/ci.yml
