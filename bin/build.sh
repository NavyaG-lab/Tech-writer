#!/usr/bin/env bash

set -euo pipefail

temp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$temp_dir"
  rm -rf .build
}

trap cleanup EXIT

cp -a . "${temp_dir}/docs"
cp webpage/mkdocs.yml "$temp_dir"
cp -a "${temp_dir}" .build

docker run --rm --volume="${PWD}/.build:/docs" --user="$(id -u):$(id -g)" quay.io/nubank/nu-mkdocs build

aws s3 sync --delete "${PWD}/.build/site" s3://nu-data-platform/data-platform-docs/site
