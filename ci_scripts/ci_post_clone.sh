#!/bin/bash
set -e

brew install tuist
cd "$CI_PRIMARY_REPOSITORY_PATH"
tuist generate --no-open
