#!/bin/bash
set -e
# Source the helper functions
. functions.sh
# initialize to false. the first call to
# the function 'log_this' will create the file and subsequent
# calls will append to the file.
logfile_created=false

lucky set-status -n drone-rpc-relation-status maintenance \
  "Configuring Drone relation"

# Do different stuff based on which hook is running
if [ ${LUCKY_HOOK} == "drone-rpc-relation-joined" ]; then
  # Get relation data and set container params
  set_relation_data
elif [ ${LUCKY_HOOK} == "drone-rpc-relation-changed" ]; then
  # Get relation data and set container params
  set_relation_data
fi

lucky set-status -n drone-rpc-relation-status active