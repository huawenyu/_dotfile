#!/bin/bash
# 1. Download deb package
#   - Download the deb package directly from: https://www.google.com/chrome/dev/
#   - Unpack it (ar xo /path/to/file.deb)
#   - Unpack the data.tar.xz (tar -xvf ...)
#   - Run opt/google/chrome/google-chrome
# 2. About flags:
#    http://www.chromium.org/developers/how-tos/run-chromium-with-flags
#     --remote-debugging-port=9222
#     --user-data-dir=$(mktemp -d -t 'chrome-remote_data_dir')
#     --headless --disable-gpu \
~/Downloads/chrome/opt/google/chrome-unstable/google-chrome-unstable \
        --allow-insecure-localhost \
        --no-first-run \
        --no-default-browser-check \
        --window-size=800,600 \
        --net-log-capture-mode=IncludeSocketBytes \
        --log-net-log=/home/hyu/tmp/chrome-netlog.json \
        "$1"

