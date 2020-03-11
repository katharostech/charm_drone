#!/bin/bash
# NOTE: The "shabang" above is required for the script to execute properly
# Exit non-zero is any command in the script exits non-zero
set -e
# Source the helper functions
. functions.sh
# initialize to false. the first call to
# the function 'log_this' will create the file and subsequent
# calls will append to the file.
logfile_created=false

# Say that we are in the middle of installing
lucky set-status maintenance 'Installing Docker Drone Runner'

# Create a Docker container by setting the container image to use
lucky container image set drone/drone-runner-docker:1

# Indicate we are done installing
lucky set-status active
