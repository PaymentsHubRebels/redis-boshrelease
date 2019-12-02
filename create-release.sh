#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function latest_version {
    git describe --tags "$(git rev-list --tags --max-count=1)" || return 1
}

function bump_minor_version {
    local version=$1
    local major_version
    local minor_version

    major_version="$(echo "$version" | awk -F '.' '{print $1}')"
    minor_version="$(echo "$version" | awk -F '.' '{print $2}')"

    echo "$major_version.$(( minor_version + 1 )).0"
}

function main {
    local redis_bosh_release_version
    local release_dir
    local tarball

    redis_bosh_release_version="$(bump_minor_version "$(latest_version)")"

    release_dir="$THIS_SCRIPT_DIR/releases"
    tarball="redis-boshrelease-$redis_bosh_release_version.tgz"

    "$THIS_SCRIPT_DIR"/add-blobs.sh
    bosh create-release --name=redis --force --version="$redis_bosh_release_version" --final --tarball="$release_dir/$tarball"
}

main