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

errors=0
# Flags
INFO=1
CHECKS=1
LIST=0
SINGLE=0
SCRIPT_PROVIDED=''
RESTART_THRESHOLD=${RESTART_THRESHOLD:=10} #arbitray

OCDEBUGIMAGE=${OCDEBUGIMAGE:=registry.redhat.io/rhel8/support-tools:latest}

parse_params "$@"
setup_colors

main() {
    # Check if only list is needed
    if [ "${LIST}" -ne 0 ]; then
        msg "${GREEN}Available scripts:${NOCOLOR}"
        find checks/ info/ -type f | sort -n
        exit 0
    else
        # Check binaries availability
        for i in oc jq curl column; do
            check_command ${i}
        done
        # Check kubeconfig and current user
        kubeconfig
        OCUSER=$(oc_whoami)
        # Otherwise
        # If only a single script is needed:
        if [ "${SINGLE}" -ne 0 ]; then
            INFO=0
            CHECKS=0
            # shellcheck disable=SC1090,SC1091
            source "${SCRIPT_PROVIDED}"
        fi
        # If only info data is needed:
        if [ "${INFO}" -gt 0 ]; then
            msg "Gathering cluster information as ${GREEN}${OCUSER}${NOCOLOR}:"
            for info in ./info/*; do
                # shellcheck disable=SC1090,SC1091
                source "${info}"
            done
        fi
        # If only checks are needed:
        if [ "${CHECKS}" -gt 0 ]; then
            msg "Running basic health checks as ${GREEN}${OCUSER}${NOCOLOR}"
            for check in ./checks/*; do
                # shellcheck disable=SC1090,SC1091
                source "${check}"
            done
        fi
    fi
    if [ ${errors} -gt 0 ]; then
      die "${RED}Total issues found: ${errors}${NOCOLOR}"
    else
      msg "${GREEN}No issues found${NOCOLOR}"
    fi
}

main "$@"
