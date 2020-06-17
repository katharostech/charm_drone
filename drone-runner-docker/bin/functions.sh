#!/bin/bash

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

set_container_port () {
  # Get random port if not set
  if [ -z "$(lucky kv get bind_port)" ]; then
    # Use random function of Lucky
    rand_port=$(lucky random --available-port)
    lucky kv set bind_port="$rand_port"
  fi
}

set_relation_data () {
  lucky container env set \
    "DRONE_RPC_SECRET=$(lucky relation get --app rpc_secret)" \
    "DRONE_RPC_HOST=$(lucky relation get --app server_host)" \
    "DRONE_RPC_PROTO=$(lucky relation get --app server_proto)" \
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
}
