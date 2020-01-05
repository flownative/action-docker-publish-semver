#!/bin/sh
set -x

TAG=${INPUT_TAG:-}
if [ -z "${TAG}" ]; then
  echo "Missing required variable TAG"
  exit 1
fi

DOCKER_IMAGE_TAG_MAJOR=$(echo "$TAG" | cut -d"." -f1 | sed -e 's/v//')
DOCKER_IMAGE_TAG_MINOR=$(echo "$TAG" | cut -d"." -f2 | sed -e 's/v//')
DOCKER_IMAGE_TAG_PATCH=$(echo "$TAG" | cut -d"." -f3 | cut -d"-" -f1 | sed -e 's/v//')
DOCKER_IMAGE_TAG_PATCH_WITH_SUFFIX=$(echo "$TAG" | cut -d"." -f3 | sed -e 's/v//')

echo "${INPUT_SOURCE_REGISTRY_PASSWORD}" | docker login -u "${INPUT_SOURCE_REGISTRY_USERNAME}" --password-stdin "${INPUT_SOURCE_REGISTRY_ENDPOINT}"
echo "${INPUT_TARGET_REGISTRY_PASSWORD}" | docker login -u "${INPUT_TARGET_REGISTRY_USERNAME}" --password-stdin "${INPUT_TARGET_REGISTRY_ENDPOINT}"

git checkout ${TAG}
set -- "-t" "${INPUT_SOURCE_IMAGE_NAME}:${TAG}"

BUILD_ENV_SCRIPT=${HOME}/.github/build-env.sh

if [ -f "${BUILD_ENV_SCRIPT}" ]; then
  # shellcheck disable=SC1090
  . "${BUILD_ENV_SCRIPT}"
  IFS="$(printf '\n ')" && IFS="${IFS% }"
  set -o noglob
  for line in $(env | grep BUILD_ARG_); do
    set -- "$@" '--build-arg' $(echo "$line" | sed -E 's/(BUILD_ARG_)//g')
  done
  echo "Build arguments: " "$@"
else
  echo "Skipping build env script (none found at ${BUILD_ENV_SCRIPT})"
fi

docker build "$@" .

docker tag "${INPUT_SOURCE_IMAGE_NAME}:${TAG}" "${INPUT_TARGET_IMAGE_NAME}:${DOCKER_IMAGE_TAG_MAJOR}"
docker push "${INPUT_TARGET_IMAGE_NAME}:${DOCKER_IMAGE_TAG_MAJOR}"
docker tag "${INPUT_SOURCE_IMAGE_NAME}:${TAG}" "${INPUT_TARGET_IMAGE_NAME}/:${DOCKER_IMAGE_TAG_MAJOR}.${DOCKER_IMAGE_TAG_MINOR}"
docker push "${INPUT_TARGET_IMAGE_NAME}/:${DOCKER_IMAGE_TAG_MAJOR}.${DOCKER_IMAGE_TAG_MINOR}"
docker tag "${INPUT_SOURCE_IMAGE_NAME}:${TAG}" "${INPUT_TARGET_IMAGE_NAME}:${DOCKER_IMAGE_TAG_MAJOR}.${DOCKER_IMAGE_TAG_MINOR}.${DOCKER_IMAGE_TAG_PATCH}"
docker push "${INPUT_TARGET_IMAGE_NAME}:${DOCKER_IMAGE_TAG_MAJOR}.${DOCKER_IMAGE_TAG_MINOR}.${DOCKER_IMAGE_TAG_PATCH}"
docker tag "${INPUT_SOURCE_IMAGE_NAME}:${TAG}" "${INPUT_TARGET_IMAGE_NAME}:${DOCKER_IMAGE_TAG_MAJOR}.${DOCKER_IMAGE_TAG_MINOR}.${DOCKER_IMAGE_TAG_PATCH_WITH_SUFFIX}"
docker push "${INPUT_TARGET_IMAGE_NAME}:${DOCKER_IMAGE_TAG_MAJOR}.${DOCKER_IMAGE_TAG_MINOR}.${DOCKER_IMAGE_TAG_PATCH_WITH_SUFFIX}"

docker tag "${INPUT_SOURCE_IMAGE_NAME}" "${INPUT_TARGET_IMAGE_NAME}:latest"
docker push "${INPUT_TARGET_IMAGE_NAME}:latest"
