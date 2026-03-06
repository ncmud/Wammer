#!/bin/sh
set -e

curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

mise install

mise exec -- tuist generate -p ../ --no-open
