#!/bin/bash
set -e

BUILD_DIR=./build
TARGET_DIR=${BUILD_DIR}/drone-server

lucky charm build

# Remove build / push scripts from build dir
rm -f "${TARGET_DIR}/build_charm.sh"
rm -f "${TARGET_DIR}/push_charm.sh"
