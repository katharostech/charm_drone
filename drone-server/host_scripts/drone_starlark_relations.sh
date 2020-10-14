#!/bin/bash
set -e
# Source the helper functions
. functions.sh
# initialize to false. the first call to
# the function 'log_this' will create the file and subsequent
# calls will append to the file.
logfile_created=false

lucky set-status -n drone-starlark-relation-status maintenance \
  "Configuring drone-starlark-relation"
echo "Hi Mom! I'm in $0"

# Do different stuff based on which hook is running
if [ ${LUCKY_HOOK} == "drone-starlark-relation-joined" ]; then
  log_this "relation joined hook running"
  set_drone_starlark_relation
elif [ ${LUCKY_HOOK} == "drone-starlark-relation-changed" ]; then
  log_this "relation changed hook running"
  set_drone_starlark_relation
elif [ ${LUCKY_HOOK} == "drone-starlark-relation-departed" ]; then
  log_this "relation departed hook running"
  remove_drone_starlark_relation
elif [ ${LUCKY_HOOK} == "drone-starlark-relation-broken" ]; then
  log_this "relation broken hook running"
  remove_drone_starlark_relation
fi

# Do this stuff regardless of which hook is running
lucky set-status -n drone-starlark-relation-status active