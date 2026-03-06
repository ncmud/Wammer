#!/bin/bash
set -e

curl https://mise.jdx.dev/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
mise install tuist
eval "$(mise activate bash)"

cd "$CI_PRIMARY_REPOSITORY_PATH"
tuist generate --no-open
