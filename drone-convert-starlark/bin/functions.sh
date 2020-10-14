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

set_starlark_secret () {
  # If secret not specified by config, generate random secret
  # Use Lucky random function
  secret=$(lucky random --length 32)
  lucky kv set starlark_secret="${secret}"
}

set_container_port () {
  # Get random port if not set
  if [ -z "$(lucky kv get bind_port)" ]; then
    # Use random function of Lucky
    rand_port=$(lucky random --available-port)
    lucky kv set bind_port="$rand_port"
  fi
}

start_starlark () {
  lucky container env set \
    "DRONE_SECRET=$(lucky kv get starlark_secret)"

  # Remove previously opened ports
  lucky port close --all
  lucky container port remove --all 

  # Bind the container port to host
  set_container_port
  bind_port=$(lucky kv get bind_port)
  lucky port open ${bind_port}
  lucky container port add ${bind_port}:3000
}

set_relation_data () {
  # This function should only be called within the context of a 
  # relation hook. This ensures the proper context is provided when
  # setting relation information.

  # Publish the endpoint and secret
  lucky relation set "starlark_endpoint=http://$(lucky private-address):$(lucky kv get bind_port)"
  lucky relation set "starlark_secret=$(lucky kv get starlark_secret)"
}
