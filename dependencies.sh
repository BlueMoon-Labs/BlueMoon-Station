#!/bin/sh

#Project dependencies file
#Final authority on what's required to fully build the project

# byond version
export BYOND_MAJOR=516
export BYOND_MINOR=1680

#rust_g git tag
export RUST_G_VERSION=6.0.1
# sha256 of the pinned librust_g.so release asset (verified after download)
export RUST_G_SHA256=4de9edd022c9bd4408cedc300b0fba4066fee6e49c1e03c3ea1e2de7499c3aa8

#node version
export NODE_VERSION_LTS=20.19.0
export NODE_VERSION_COMPAT=20.19.0

# SpacemanDMM git tag
export SPACEMAN_DMM_VERSION=suite-1.11
# sha256 of the pinned dreamchecker / dmdoc release assets (verified after download)
export SPACEMAN_DMM_DREAMCHECKER_SHA256=1d31563287d1fa0f5c4f5744cdf74f97b5d3abc4911a81e3c94ce01a56f5a0d0
export SPACEMAN_DMM_DMDOC_SHA256=27c10207221b695baa1a00e0a7870bcfb80e5f362340b5d475b224d9182f4c35

# Python version for mapmerge and other tools
export PYTHON_VERSION=3.11.0

# Auxmos git tag
# v2.5.1: v2.5.6 causes illegal operation crashes + network sequence errors on this codebase
export AUXMOS_VERSION=v2.5.1
# sha256 of the pinned libauxmos.so release asset (verified after download)
export AUXMOS_SHA256=ac67ced93c5c5d77184c071b297c1f53f97338fd149a378ab2c98a182b8f6c46

# Extools git tag
export EXTOOLS_VERSION=v0.0.7
