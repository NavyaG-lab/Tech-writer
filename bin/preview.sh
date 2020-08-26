#!/usr/bin/env bash

set -euox pipefail

script_dir="$( cd "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P )"
root_dir="$( cd "${script_dir}/.." > /dev/null 2>&1 ; pwd -P )"
build_dir="${root_dir}/.build"
temp_dir="$(mktemp -d)"

echo "Building for $1"

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

bury_copy() {
  echo "Copying from ${1} to ${2} the file ${4} on folder ${3}"
  path_from="${1}/${3}/${4}"
  path_to="${2}/docs/${3}/${4}"
  if [[ ${4} == /* ]]; then
    path_from="${1}${4}"
    path_to="${2}/docs${4}"
  fi
  (mkdir -p `dirname ${path_to}` ; cp "${path_from}" "${path_to}") || \
    cp "${path_from}.md" "${path_to}.md" || \
    (mkdir -p `dirname ${path_to}/README.md` ; cp "${path_from}/README.md" "${path_to}/README.md")
}

export -f bury_copy

rm -rf "${build_dir}"
mkdir "${temp_dir}/docs"
cp -r "${root_dir}/stylesheets" "${temp_dir}/docs"
cp -r "${root_dir}/js" "${temp_dir}/docs"
cp -r "${root_dir}/assets" "${temp_dir}/docs"
cp -r "${root_dir}/overrides" "${temp_dir}"
mkdir -p "${temp_dir}/docs/$(dirname "$1")"
cp "${root_dir}/$1" "${temp_dir}/docs/$1"

grep  "](.*)" "${root_dir}/$1" | grep -v -E "https?://" | sed -e "s/.*(\(.*\)).*/\1/g" -e "s;^./;;" -e "s;/$;;" | \
      xargs -I {} bash -c "bury_copy ${root_dir} ${temp_dir} $(dirname "$1") {}" || true

cp "${root_dir}/mkdocs.yml" "${temp_dir}"
cp -r "${root_dir}/.git" "${temp_dir}/docs/.git"
cp -a "${temp_dir}/" "${build_dir}/"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 193814090748.dkr.ecr.us-east-1.amazonaws.com
docker pull 193814090748.dkr.ecr.us-east-1.amazonaws.com/nu-mkdocs

docker run --rm --volume="${build_dir}:/docs:delegated" -p 8000:8000 --user="$(id -u):$(id -g)" 193814090748.dkr.ecr.us-east-1.amazonaws.com/nu-mkdocs
