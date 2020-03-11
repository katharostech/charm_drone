#!/bin/bash
set -e
# Source the helper functions
. functions.sh
# initialize to false. the first call to
# the function 'log_this' will create the file and subsequent
# calls will append to the file.
logfile_created=false

lucky set-status -n config-status maintenance "Config changed; reconfiguring Drone Runner"

# Check for Drone Server relation
rel_cnt=$(lucky relation list-ids -n drone-rpc | wc -l)

# Only a single relation to a Drone server is allowed
if [ ${rel_cnt} -gt 1 ]; then
  # Set to blocked until relation is resolved
  lucky set-status -n config-status active
  # Set relation status to blocked and exit
  lucky set-status -n drone-rpc-relation-status blocked \
    "Only one or no relations to Drone Server allowed. ${rel_cnt} found"
  exit 0
elif [ ${rel_cnt} -eq 1 ]; then
# Then use the relation values to run the container
  rpc_secret=$(lucky relation get --app rpc_secret)
  rpc_server_host=$(lucky relation get --app server_host)
  rpc_server_proto=$(lucky relation get --app server_proto)
  lucky set-status -n drone-rpc-relation-status active
elif [ ${rel_cnt} -eq 0 ]; then # Use config values
  # However if config values have not been set
  if [ -z $(lucky get-config rpc_secret) ] ||
  [ -z $(lucky get-config server_host) ] ||
  [ -z $(lucky get-config server_proto) ]; then
    # Then set to waiting for either relation or config values
    lucky set-status -n config-status active
    lucky set-status -n drone-rpc-relation-status waiting \
      "Drone Runner awaiting either configuration, or a relation to a Drone Server Charm"
    exit 0
  else
    # Otherwise use the config values
    rpc_secret=$(lucky get-config rpc_secret)
    rpc_server_host=$(lucky get-config server_host)
    rpc_server_proto=$(lucky get-config server_proto)
    lucky set-status -n drone-rpc-relation-status active
  fi
fi

# Set a container environment variable based on the config.
# This will cause the container to be stopped, removed, and re-created after this script exits
# if the container config is not the same as was when the script was started.
lucky container env set \
  "DRONE_RPC_SECRET=${rpc_secret}" \
  "DRONE_RPC_HOST=${rpc_server_host}" \
  "DRONE_RPC_PROTO=${rpc_server_proto}" \
  "DRONE_RUNNER_CAPACITY=2" \
  "DRONE_RUNNER_NAME=$(hostname)"

lucky container volume add /var/run/docker.sock /var/run/docker.sock

# Remove previously opened ports
lucky port close --all
lucky container port remove --all 

# Bind the container port to host
set_container_port
bind_port=$(lucky kv get bind_port)
lucky port open ${bind_port}
lucky container port add ${bind_port}:3000

lucky set-status -n config-status active
