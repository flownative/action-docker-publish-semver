# Docker Image Release Github Action

This Github action takes an existing, tagged Docker image from the Github package repository, 
creates multiple new tags according to Semantic Versioning, and publishes them to a given
target registry.

In short, if you have an image `docker.pkg.github.com/acme/docker-magic-wand/magic-wand:1.2.3-4`,
it will be tagged an released as:

- `acme/magic-wand:1.2.3-4`
- `acme/magic-wand:1.2.3`
- `acme/magic-wand:1.2`
- `acme/magic-wand:1`

and optionally as 
- `acme/magic-wand:latest`

## Example workflow

````yaml
name: Build and release Docker images
on:
  push:
    branches-ignore:
      - '**'
    tags:
      - 'v*.*.*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:

      - uses: actions/checkout@v2
        with:
          fetch-depth: 1

      - name: Build Docker image
        uses: flownative/action-docker-build@master
        with:
          tag_ref: ${{ github.ref }}
          image_name: flownative/docker-base/base
          registry_password: ${{ secrets.GITHUB_TOKEN }}

      - name: Publish release to docker.io
        uses: flownative/action-docker-publish-semver@master
        with:
          tag_ref: ${{ github.ref }}
          tag_latest: 'yes'

          source_image_name: docker.pkg.github.com/flownative/docker-base/base
          source_registry_username: github
          source_registry_password: ${{ secrets.GITHUB_TOKEN }}
          source_registry_endpoint: https://docker.pkg.github.com/v2/

          target_image_name: flownative/base
          target_registry_username: ${{ secrets.DOCKER_IO_REGISTRY_USER }}
          target_registry_password: ${{ secrets.DOCKER_IO_REGISTRY_PASSWORD }}
          target_registry_endpoint: https://index.docker.io/v1/
````
