#!/usr/bin/env bash

set -euox pipefail

script_dir="$( cd "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P )"
root_dir="$( cd "${script_dir}/.." > /dev/null 2>&1 ; pwd -P )"
build_dir="${root_dir}/.build"
temp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

rm -rf "${build_dir}"
cp -a "${root_dir}" "${temp_dir}/docs"
mv "${temp_dir}/docs/overrides" "${temp_dir}"
cp "${root_dir}/mkdocs.yml" "${temp_dir}"
cp -r "${root_dir}/.git" "${temp_dir}/docs/.git"
cp -a "${temp_dir}/" "${build_dir}/"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 193814090748.dkr.ecr.us-east-1.amazonaws.com
docker pull 193814090748.dkr.ecr.us-east-1.amazonaws.com/nu-mkdocs

docker run --rm --volume="${build_dir}:/docs:delegated" --user="$(id -u):$(id -g)" 193814090748.dkr.ecr.us-east-1.amazonaws.com/nu-mkdocs build --strict
