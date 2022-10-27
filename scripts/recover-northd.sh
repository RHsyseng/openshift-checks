#!/usr/bin/env bash
###########################################################
# recover-northd.sh script to unwedge northd in the event #
# of a node failure                                       #
###########################################################

# Timestamp to be used in the logfile name
NOW=$(date +"%Y-%m-%d_%H-%M-%S")
# Logfile to save some DEBUG output
LOG="/tmp/recover-northd.sh.${NOW}.log"
# Debug var to write DEBUG lines into the log
DEBUG=false
# Whether to intervene if northd is wedged
REMDIATE=false

###########################################################
# usage(): prints the usage of the script
###########################################################
function usage() {
  echo "This script checks if northd is stuck and optionally intervene"
  echo -e
  echo -e "\tUsage: $(basename "$0")"
  echo -e "\tHelp: $(basename "$0") -h"
  echo -e "\tSave extra DEBUG lines into the log: $(basename "$0") -d"
  echo -e "\tSet the KUBECONFIG env var to /kubeconfig/file: $(basename "$0") -k /kubeconfig/file"
  echo -e "\tRemediate the issue: $(basename "$0") -r"
  echo -e
  echo "After the execution a logfile will be generated with the name recover-northd.DATE.log"
}

###########################################################
# check_northd(): check the current status of northd
###########################################################
function check_northd() {

  pods=$(oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-master --no-headers | grep Running | awk '{print $1}')
  for pod in ${pods}; do
    pod_status=$(oc exec -n openshift-ovn-kubernetes -c northd "${pod}" -- ovn-appctl -t ovn-northd status | awk '{print $2}')
    if [[ ${pod_status} == 'active' ]]; then
      active_pod=${pod}
      node=$(oc get pod/"$active_pod" -n openshift-ovn-kubernetes -o json | jq .spec.nodeName | sed -e 's/\"//g')
      date=$(date +"%Y-%m-%d %H:%M:%S")
      if eval "${DEBUG}"; then echo "[check_northd:${date}] pod ${pod} is active" >>"${LOG}"; fi
    else
      date=$(date +"%Y-%m-%d %H:%M:%S")
      if eval "${DEBUG}"; then echo "[check_northd:${date}] pod ${pod} NOT active,  status:${pod_status}" >>"${LOG}"; fi
    fi
  done

  if [[ -z ${active_pod} ]]; then
    date=$(date +"%Y-%m-%d %H:%M:%S")
    if eval "${DEBUG}"; then echo "[check_northd:${date}] no active northd leader found" >>"${LOG}"; else
      echo "no active northd leader found..."
    fi
    if eval "${REMDIATE}"; then
      if eval "${DEBUG}"; then echo "[check_northd:${date}] ...recovering northd" >>"${LOG}"; else
        echo "...recovering northd"
      fi
      for pod in ${pods}; do
        oc exec -n openshift-ovn-kubernetes -c northd "${pod}" -- ovn-appctl -t ovn-northd exit
        date=$(date +"%Y-%m-%d %H:%M:%S")
        if eval "${DEBUG}"; then echo "[check_northd:${date}] recovering pod ${pod}" >>"${LOG}"; else
          echo "recovering pod ${pod}"
        fi
      done
    fi
  else
    date=$(date +"%Y-%m-%d %H:%M:%S")
    if eval "${DEBUG}"; then echo "[check_northd:${date}] found active northd leader (${active_pod}) on ${node}" >>"${LOG}"; else
      echo "found active northd leader (${active_pod}) on ${node}"
    fi
  fi

}

# Main
while getopts "dhk:r" flag; do
  case "${flag}" in
  d)
    DEBUG=true
    ;;
  h)
    usage
    exit 1
    ;;
  k)
    export KUBECONFIG="${OPTARG}"
    echo "Exported KUBECONFIG=${KUBECONFIG}" >>"${LOG}"
    ;;
  r)
    REMDIATE=true
    ;;
  *)
    echo >&2 "Invalid option: $*"
    usage
    exit 1
    ;;
  esac
done

check_northd

if [[ -f ${LOG} ]]; then
  echo "# Logged operations into the file ${LOG}"
fi
