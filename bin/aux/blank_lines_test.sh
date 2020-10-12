#!/usr/bin/env bash

files_without_one_line_in_the_end() {
  # Inspired by this test:
  # https://github.com/nubank/nucli/blob/0b7bc55cc9c13e3b04ebf2c8d28063442a639772/.circleci/config.yml#L65-L91
  incorrect_files=$(find . \
    -type f \
    \( -not -name '*\.*' -o -name '*.md' -o -name '*.sh' \) \
    -not -path '*.git/*' \
    -print0 |
    xargs -0 -n1 bash -c '{ [[ "$(tail -c 1 "$0")" ]] || tail -n1 "$0" | grep -qe '^\$'; } && echo "$0"') || :

  if [[ -n "${incorrect_files}" ]]; then
    echo "There should be exactly one empty line at the end of the file. Violations in:"
    echo "${incorrect_files}" | sort
    exit 1
  fi
}

test_empty_line() {
  test::run "Files without exactly one line in the end" files_without_one_line_in_the_end
}

test::set_suite "empty-line"
test_empty_line
