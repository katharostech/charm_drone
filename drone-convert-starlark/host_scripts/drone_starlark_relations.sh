#!/bin/bash
set -e
# Source the helper functions
. functions.sh
# initialize to false. the first call to
# the function 'log_this' will create the file and subsequent
# calls will append to the file.
logfile_created=false

lucky set-status -n drone-starlark-relation-status maintenance \
  "Configuring Drone Starlark relation"

# Do different stuff based on which hook is running
if [ ${LUCKY_HOOK} == "drone-starlark-relation-joined" ]; then
  # Publish data to relations
  set_relation_data
elif [ ${LUCKY_HOOK} == "drone-starlark-relation-changed" ]; then
  # Publish data to relations
  set_relation_data
fi

lucky set-status -n drone-starlark-relation-status active