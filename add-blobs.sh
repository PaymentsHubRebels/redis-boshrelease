#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DOWNLOAD_FOLDER="/tmp/bosh_downloads"

REDIS_VERSION="5.0.5"
BLOB_FILENAME="redis-$REDIS_VERSION.tar.gz"
REDIS_DOWNLOAD_URL="http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz"

function blob_exists {
    local blob_path=$1

    [[ -f "$blob_path" ]] || return 1
}

if ! blob_exists "$DOWNLOAD_FOLDER/$BLOB_FILENAME"; then
    mkdir -p "$DOWNLOAD_FOLDER"
    curl -L -J -o "$DOWNLOAD_FOLDER/$BLOB_FILENAME" "$REDIS_DOWNLOAD_URL"
    bosh add-blob --dir="$THIS_SCRIPT_DIR" "$DOWNLOAD_FOLDER/$BLOB_FILENAME" "redis/$BLOB_FILENAME"
fi