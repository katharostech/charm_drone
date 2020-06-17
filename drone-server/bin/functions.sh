#!/bin/bash
set -ex

# function to send log messages to a file
log_this () {

  # create the logfile if needed
  if [ !${logfile_created} ]; then
    # gather some data
    now=$(date "+%Y%m%d-%H%M%S")
    logdir=/var/log/lucky
    script="${0}"
    scriptbase=$(basename -s ".sh" "${script}")
    logname="${scriptbase}"
    logfile="${logdir}/${logname}-${now}.log"

    # create the dir if it doesn't exist
    mkdir -p ${logdir}
    touch ${logfile}
    # say we created it
    logfile_created=true
  fi

  # write message to log
  echo "${LUCKY_HOOK}::${1}" >> ${logfile}

  # clean up files older than 10 minutes
  find ${logdir} -name "${logname}-*" -mmin +10 -print | xargs rm -f
}

# Function to set the http interface relation
# Convention found here: https://discourse.jujucharms.com/t/interface-http/2392
set_http_relation () {
  # Set port if needed
  set_container_port
  
  # Get the port from the KV store
  bind_port=$(lucky kv get bind_port)

  # Log it
  log_this "hostname: $(lucky private-address)"
  log_this "port: ${bind_port}"

  # Publish the listen address to the relation
  lucky relation set "hostname=$(lucky private-address)"
  lucky relation set "port=${bind_port}"
}

set_container_port () {
  # Get random port if not set
  if [ -z "$(lucky kv get bind_port)" ]; then
    # Use random function of Lucky
    rand_port=$(lucky random --available-port)
    lucky kv set bind_port="$rand_port"
  fi
}

set_rpc_secret () {
  # Get random string if not set
  if [ -z "$(lucky kv get rpc_secret)" ]; then
    # Use Lucky random function
    secret=$(lucky random --length 32)
    lucky kv set rpc_secret="${secret}"
  fi
}

sc_config_check () {
  # Get config values
  bitbucket_client_id=$(lucky get-config bitbucket-client-id)
  bitbucket_client_secret=$(lucky get-config bitbucket-client-secret)
  github_client_id=$(lucky get-config github-client-id)
  github_client_secret=$(lucky get-config github-client-secret)
  github_server=$(lucky get-config github-server)
  gitlab_client_id=$(lucky get-config gitlab-client-id)
  gitlab_client_secret=$(lucky get-config gitlab-client-secret)
  gitlab_server=$(lucky get-config gitlab-server)
  gitea_client_id=$(lucky get-config gitea-client-id)
  gitea_client_secret=$(lucky get-config gitea-client-secret)
  gitea_server=$(lucky get-config gitea-server)
  admin=$(lucky get-config admin)
  server_host=$(lucky get-config server-host)
  server_proto=$(lucky get-config server-proto)
  tls_autocert=$(lucky get-config tls-autocert)
  
  # Check global configs
  if [ -z ${server_host} ]; then
    lucky set-status -n config-status blocked \
    "Config required: 'server-host'"
    exit 0
  elif [ -z ${server_proto} ]; then
    lucky set-status -n config-status blocked \
    "Config required: 'server-proto'"
    exit 0
  fi

  # Bitbucket Cloud Config
  if [ -n ${bitbucket_client_id} ] ||
  [ -n ${bitbucket_client_secret} ]; then
    # Ensure all required args are provided, otherwise block
    if [ -z ${bitbucket_client_id} ] ||
    [ -z ${bitbucket_client_secret} ]; then
      lucky set-status -n config-status blocked \
      "Bitbucket Cloud config attempted, but requires ID and Secret"
      exit 0
    fi
  # GitHub
  elif [ -n ${github_client_id} ] ||
  [ -n ${github_client_secret} ] ||
  [ -n ${github_server} ]; then
    if [ -z ${github_client_id} ] ||
    [ -z ${github_client_secret} ]; then
      lucky set-status -n config-status blocked \
      "GitHub config attempted, but requires ID and Secret"
      exit 0
    fi
  # GitLab
  elif [ -n ${gitlab_client_id} ] ||
  [ -n ${gitlab_client_secret} ] ||
  [ -n ${gitlab_server} ]; then
    if [ -z ${gitlab_client_id} ] ||
    [ -z ${gitlab_client_secret} ] ||
    [ -z ${gitlab_server} ]; then
      lucky set-status -n config-status blocked \
      "GitLab config attempted, but requires ID, Secret, and Server"
      exit 0
    fi
  # Gitea
  elif [ -n ${gitea_client_id} ] ||
  [ -n ${gitea_client_secret} ] ||
  [ -n ${gitea_server} ]; then
    if [ -z ${gitea_client_id} ] ||
    [ -z ${gitea_client_secret} ] ||
    [ -z ${gitea_server} ]; then
      lucky set-status -n config-status blocked \
      "Gitea config attempted, but requires ID, Secret, and Server"
      exit 0
    fi
  # No config has been set
  else
    lucky set-status -n config-status blocked \
    "A Source Control provider must be configured"
    exit 0
  fi
}

set_drone_rpc_relation () {
  lucky relation set --app "rpc_secret=$(lucky kv get rpc_secret)"
  lucky relation set --app "server_host=$(lucky get-config server-host)"
  lucky relation set --app "server_proto=$(lucky get-config server-proto)"
}
