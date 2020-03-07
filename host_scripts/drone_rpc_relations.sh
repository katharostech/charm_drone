#!/bin/bash
# Source the helper functions
. functions.sh
# initialize to false. the first call to
# the function 'log_this' will create the file and subsequent
# calls will append to the file.
logfile_created=false

lucky set-status -n drone-rpc-relation-status maintenance \
  "Configuring drone-rpc-relation"

# Do different stuff based on which hook is running
if [ ${LUCKY_HOOK} == "drone-rpc-relation-joined" ]; then
  # Set the listen address
  set_drone_rpc_relation
elif [ ${LUCKY_HOOK} == "drone-rpc-relation-changed" ]; then
  # Just re-set the listen_address
  set_drone_rpc_relation
elif [ ${LUCKY_HOOK} == "drone-rpc-relation-departed" ]; then
  # Don't do anything
  echo "Drone RPC relation departed"
elif [ ${LUCKY_HOOK} == "drone-rpc-relation-broken" ]; then
  # Don't do anything
  echo "Drone RPC relation broken"
fi

# Do this stuff regardless of which hook is running
lucky set-status -n website-relation-status active