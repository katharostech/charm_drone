#!/bin/bash
# NOTE: The "shabang" above is required for the script to execute properly
# Exit non-zero if any command in the script exits non-zero
set -e
# Source the helper functions
. functions.sh
# initialize to false. the first call to
# the function 'log_this' will create the file and subsequent
# calls will append to the file.
logfile_created=false


# Say that we are in the middle of installing
lucky set-status maintenance 'Installing Drone.'

# Create a Docker container by setting the container image to use
lucky container image set drone/drone:1

# The Docker container will be run with all the settings we just set when this script exits

# Indicate we are done installing
lucky set-status active
