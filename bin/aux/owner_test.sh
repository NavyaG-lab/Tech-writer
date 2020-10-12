#!/usr/bin/env bash

all_files_with_owner() {
  cd $PROJ_HOME
  local -r incorrect_files=$(grep -r --include='*.md' --exclude-dir='.build' -L '^owner: "[#@].*"$' .)

  if [ -n "$incorrect_files" ]; then
    echo "All files should have a owner defined. Violations in:"
    for file in $incorrect_files; do
      echo ${file}
    done
    exit 1
  fi
}

test_owner() {
  test::run "Files without defined owner" all_files_with_owner
}

test::set_suite "owner"
test_owner
