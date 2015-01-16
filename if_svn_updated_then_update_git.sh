#!/usr/bin/env bash

# Watching the `trigger_folder`, which is a Dropbox-syncing folder.
# Once the remote svn updated, a text file will be added to this folder via
# an IFTTT recipe (14339724).
# When `fswatch` get that change (a new file synced down), the handler will be
# called to fetch remote changes and merge into local repository and then push
# to GitHub.
# If the fetch-and-merge process fails with any error, a log file will be saved
# to another Dropbox-syncing folder `log_folder`. Another IFTTT recipe
# (14395025) will send an email to my GMail inbox to notify me.

bin_folder=$(dirname `readlink -f "$0"`)

trigger_folder=/Users/zhouji/Dropbox/IFTTT/Feed/autoproxy-gfwlist-svn
log_folder=/Users/zhouji/Dropbox/IFTTT/GfwList
handler=$bin_folder/fetch_and_merge.sh

function handle_trigger() {
    trigger_file=$1
    echo "----- ----- ----- ----- ----- ----- ----- -----"
    echo "handling trigger $trigger_file"

    if [ -f "$trigger_file" ]; then
        local tmp_file=`mktemp`
        "$handler" 2>&1 | tee "$tmp_file"
        local ret=${PIPESTATUS[0]}
        if [ $ret -eq 0 ]; then
            echo "$trigger_file process succeed"
            rm "$tmp_file"
        else
            local log_file="$log_folder/failure_$(date '+%Y%m%d_%H%M%S').txt"
            echo "$trigger_file process failed, logged to $log_file"
            mv "$tmp_file" "$log_file"
        fi
    else
        echo "$trigger_file not exists, ignored"
    fi

    echo "===== ===== ===== ===== ===== ===== ===== ====="
}

#fswatch -0 "$trigger_folder" | xargs -0 -n 1 -I file handle_trigger file
fswatch -0 "$trigger_folder" | while read -d $'\0' file; do
    handle_trigger "$file"
done
