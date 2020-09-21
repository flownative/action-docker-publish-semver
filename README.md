# Docker Publish SemVer Github Action

This Github action takes an existing, tagged Docker image from the a Docker image registry
(for example, the Github Package Repository), creates multiple new tags according to 
Semantic Versioning, and publishes them to a given target registry.

In short, if you have an image `docker.pkg.github.com/acme/docker-magic-wand/magic-wand:1.2.3+4`,
it will be tagged and released as:

- `acme/magic-wand:1.2.3`
- `acme/magic-wand:1.2`
- `acme/magic-wand:1`

and optionally as 
- `acme/magic-wand:latest`

Notes:
- if the given `tag_ref` has a "v" prefix (such as in "v1.2.3"), it will be removed before
  using the tag for the target Docker image. Therefore, a target image tag will never have that
  prefix
- the "build version" suffix ("4" in the case of "1.2.3+4") will be omitted, because the plus
  sign is not allowed as part of a Docker image tag. It also cannot be converted to "-", because
  a dash is the delimiter for a "pre-release" part of a SemVer version string (e.g "beta5").

## Additional custom tag

You may also specify a custom tag using the "tag_custom" argument. If the value of this argument
is not empty, the image is additionally tagged using this given tag. See the example below for more
details. 

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
          tag_custom: 'some-custom-tag'

          source_image_name: docker.pkg.github.com/flownative/docker-base/base
          source_registry_username: github
          source_registry_password: ${{ secrets.GITHUB_TOKEN }}
          source_registry_endpoint: https://docker.pkg.github.com/v2/

          target_image_name: flownative/base
          target_registry_username: ${{ secrets.DOCKER_IO_REGISTRY_USER }}
          target_registry_password: ${{ secrets.DOCKER_IO_REGISTRY_PASSWORD }}
          target_registry_endpoint: https://index.docker.io/v1/
````

## Outputs

After a successful run, the action provides your workflow with the following outputs:

- `image_tag`: The full tag of the Docker image, e.g. "1.2.3+42" or "2.12.19-beta1+23"
- `image_tag_major`: Major version part of the image tag, e.g. "1" if the version was 1.2.3+42
- `image_tag_minor`: Minor version part of the image tag, e.g. "2" if the version was 1.2.3+42
- `image_tag_patch`: Patch version part of the image tag, e.g. "3" if the version was 1.2.3+42
- `image_tag_patch_with_pre_release`: 'Patch version part with suffix, e.g. "3+42" if the version was 1.2.3+42

## Implementation Note

The repository of this action does not contain the actual implementation code. Instead, it's referring to a pre-built
image in order to save resources and speed up workflow runs.

The code of this action can be found [here](https://github.com/flownative/docker-action-docker-publish-semver).

