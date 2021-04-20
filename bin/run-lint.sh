#!/usr/bin/env bash

docker run -v $(pwd):/md peterdavehello/markdownlint markdownlint . --config .circleci/markdownlint-config.json --ignore \"\" --ignore node_modules/
