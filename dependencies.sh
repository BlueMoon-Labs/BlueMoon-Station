#!/bin/sh

#Project dependencies file
#Final authority on what's required to fully build the project

# byond version
export BYOND_MAJOR=516
export BYOND_MINOR=1688
# HTTPS mirror archive for the exact pinned Linux release; verified before unpacking.
export BYOND_LINUX_SHA256=16278f318cdeb4b77c57868dd7135032fde717ea6226269d22b2a1a50968e7f9

#rust_g git tag
export RUST_G_VERSION=6.2.0

#node version
export NODE_VERSION_LTS=24.16.0
export NODE_VERSION_COMPAT=24.16.0

# SpacemanDMM git tag
export SPACEMAN_DMM_VERSION=suite-1.11

# Python version for mapmerge and other tools
export PYTHON_VERSION=3.11.0

# Extools git tag
export EXTOOLS_VERSION=v0.0.7
