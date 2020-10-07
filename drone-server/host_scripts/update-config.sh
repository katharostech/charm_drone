#!/bin/bash
set -e
# Source the helper functions
. functions.sh
# initialize to false. the first call to
# the function 'log_this' will create the file and subsequent
# calls will append to the file.
logfile_created=false


lucky set-status -n config-status maintenance "Config changed; reconfiguring Drone"

# Load bash variables with configuration settings and
# verify minimum requirements met. 
sc_config_check

# Remove previously opened ports
lucky port close --all
lucky container port remove --all

# Bind the Drone http(s) port
if [ ${tls_autocert} == "true" ]; then
    # Use standard ports because I don't know how Drone handles Let's Encrypt
    lucky container port add 443:443
    lucky container port add 80:80
    # Open the port so that it will be exposed through the firewall if the user runs
    # `juju expose`
    lucky port open 443
    lucky port open 80
else
    set_container_port
    bind_port=$(lucky kv get bind_port)
    lucky container port add ${bind_port}:80
    lucky port open ${bind_port}
fi

# Generate a random secret key for Drone Runner intra-communication,
# unless one is specified by config via "server-secret".
set_rpc_secret
rpc_secret=$(lucky kv get rpc_secret)

# Set container environment variables based on the config.
# This will cause the container to be stopped, removed, and re-created after this script exits
# if the container config is not the same as was when the script was started.
lucky container env set \
    "DRONE_BITBUCKET_CLIENT_ID=${bitbucket_client_id}" \
    "DRONE_BITBUCKET_CLIENT_SECRET=${bitbucket_client_secret}" \
    "DRONE_GITLAB_CLIENT_ID=${gitlab_client_id}" \
    "DRONE_GITLAB_CLIENT_SECRET=${gitlab_client_secret}" \
    "DRONE_GITLAB_SERVER=${gitlab_server}" \
    "DRONE_GIT_ALWAYS_AUTH=${gitlab_always_auth}" \
    "DRONE_RPC_SECRET=${rpc_secret}" \
    "DRONE_USER_CREATE=username:${admin},admin:true" \
    "DRONE_SERVER_HOST=${server_host}" \
    "DRONE_SERVER_PROTO=${server_proto}" \
    "DRONE_TLS_AUTOCERT=${tls_autocert}"

# If a volume name has been provided, create it
drone_volume=$(lucky get-config server-volume)
if [ -n ${drone_volume} ]; then
    # Add a volume for Drone data
    lucky container volume add ${drone_volume} /data
fi

lucky set-status -n config-status active
