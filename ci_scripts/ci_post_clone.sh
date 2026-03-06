#!/bin/sh
set -e

curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

mise install

mise exec -- tuist generate -p ../ --no-open

# Set build number to Xcode Cloud's auto-incrementing build number
if [ -n "$CI_BUILD_NUMBER" ]; then
    cd ../
    xcrun agvtool new-version -all "$CI_BUILD_NUMBER"
fi
