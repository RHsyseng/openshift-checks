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
# Number of parallel jobs to be executed
PARALLELJOBS="${PARALLELJOBS:=4}"
# Var to contain the log to save the output instead the standard default system output
OUTPUTLOG=''
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
	echo -e "\tSet the mode to quiet and save the output to /tmp/output.file: $(basename "$0") -q /tmp/output.file"
	echo -e
	echo "After the execution a logfile will be generated with the name recover-northd.DATE.log"
}


###########################################################
# check_northd(): check the current status of northd
###########################################################
function check_northd() {

  pods=$(oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-master --no-headers | grep Running | awk '{print $1}')
  for pod in $pods; do
    pod_status=$(oc exec -n openshift-ovn-kubernetes -c northd "$pod" -- ovn-appctl -t ovn-northd status | awk '{print $2}')
    if [[ $pod_status == 'active' ]]; then
      active_pod=$pod
      node=$(oc get pod/"$active_pod" -n openshift-ovn-kubernetes -o json | jq .spec.nodeName | sed -e 's/\"//g')
    fi
  done

  #unset active_pod # testing
  
  if [[ -z "${active_pod}" ]]; then
    echo "no active northd leader found..."
    if eval "${REMDIATE}"; then
      echo "...recovering northd"
      for pod in $pods; do
        oc exec -n openshift-ovn-kubernetes -c northd "$pod" -- ovn-appctl -t ovn-northd exit
      done
    fi
  else
    echo "found active northd leader ($active_pod) on $node"
  fi
  
}

# Main
while getopts "dhq:k:r" flag; do
  case "${flag}" in
    q) OUTPUTLOG=${OPTARG}
	   echo "Quiet mode enabled saving output into ${OUTPUTLOG}" >> "${LOG}"
       ;;
    d) DEBUG=true
       ;;
    h) usage
       exit 1 
       ;;
    k) export KUBECONFIG="${OPTARG}"
	   echo "Exported KUBECONFIG=${KUBECONFIG}" >> "${LOG}"
       ;;
    r) REMDIATE=true
       ;;
    *) echo >&2 "Invalid option: $*"; usage; exit 1
       ;;
  esac
done

check_northd

if [[ -z "${OUTPUTLOG}" ]]; then
	echo "# Logged operations into the file ${LOG}"
fi
