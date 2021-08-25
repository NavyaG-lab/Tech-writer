#!/usr/bin/env bash

set -euox pipefail

script_dir="$( cd "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P )"
root_dir="$( cd "${script_dir}/.." > /dev/null 2>&1 ; pwd -P )"
build_dir="${root_dir}/.build/site"

rm -rf ${build_dir} & mkdir -p ${build_dir}

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 193814090748.dkr.ecr.us-east-1.amazonaws.com
docker pull 193814090748.dkr.ecr.us-east-1.amazonaws.com/nu-bookcase:latest

docker run --rm -v="${root_dir}:/nu-docs/docs" -v="${build_dir}:/nu-docs/.out" --user="$(id -u):$(id -g)" 193814090748.dkr.ecr.us-east-1.amazonaws.com/nu-bookcase:latest build
