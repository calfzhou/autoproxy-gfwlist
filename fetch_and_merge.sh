#!/usr/bin/env bash

# Fetches remote svn updates to local repository,
# and then merge these update into local master branch and trunk branch.
# Finally, push all local changes to GitHub.

# Exit immediately if a command exits with a non-zero status.
# Print commands and their arguments as they are executed.
set -ex

use_proxy=false
if [ "$1" = "--proxy" ]; then
    use_proxy=true
fi

if [ -z "$GFWLIST_HOME" ]; then
    GFWLIST_HOME=/Users/zhouji/projects/autoproxy-gfwlist
fi

max_retry=5
failure_idle=10
proxy_duration=120

function fetch_svn_updates() {
    local i=0
    local ret=0
    while true; do
        i=`expr $i + 1`
        if $use_proxy ; then
            proxychains4 git svn fetch
        else
            git svn fetch
        fi
        ret=$?
        if [ $ret -eq 0 ]; then
            break
        elif [ $i -lt $max_retry ]; then
            sleep $failure_idle
        else
            break
        fi
    done
    return $ret
}

cd "$GFWLIST_HOME"

git checkout master

if $use_proxy ; then
    ssh -D 7070 -f -p 22 gocalfco@gocalf.com sleep $proxy_duration
fi

set +e
if fetch_svn_updates; then
    :
else
    exit $?
fi
set -e

git merge origin/trunk -m 'auto merge svn trunk branch'

git checkout trunk
git merge --ff-only origin/trunk

git push --all

git checkout master
