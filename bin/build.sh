#!/usr/bin/env bash

set -euox pipefail

script_dir="$( cd "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P )"
root_dir="$( cd "${script_dir}/.." > /dev/null 2>&1 ; pwd -P )"
build_dir="${root_dir}/.build"

cleanup() {
  rm -rf .build
}

trap cleanup EXIT

${script_dir}/local-build.sh

aws s3 sync --delete "${build_dir}/site" s3://nu-data-platform/data-platform-docs/site
