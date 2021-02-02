#!/usr/bin/env bash

# https://betterdev.blog/minimal-safe-bash-script-template/

#set -Eeuo pipefail

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
IFS=$'\n\t'

# shellcheck disable=2164
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

# shellcheck disable=SC1091
source ./utils

#trap cleanup SIGINT SIGTERM ERR EXIT

INFO=1
CHECKS=1
errors=0
RESTART_THRESHOLD=${RESTART_THRESHOLD:=10} #arbitray

parse_params "$@"
setup_colors

main() {

  for i in oc jq curl; do
    check_command ${i}
  done
  
  kubeconfig
  OCUSER=$(oc_whoami)
  if [ "${INFO}" -gt 0 ]; then
    msg "Cluster information:"
    for info in ./info/*; do
      # shellcheck disable=SC1090,SC1091
      source "${info}"
    done
  fi
  if [ "${CHECKS}" -gt 0 ]; then
    msg "Running basic health checks as ${GREEN}${OCUSER}${NOCOLOR}"
    for check in ./checks/*; do
      # shellcheck disable=SC1090,SC1091
      source "${check}"
    done
    if [ ${errors} -gt 0 ]; then
      msg "${RED}Total issues found: ${errors}${NOCOLOR}"
    else
      msg "${GREEN}No issues found${NOCOLOR}"
    fi
  fi
}

main "$@"
