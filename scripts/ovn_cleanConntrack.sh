#!/usr/bin/env bash
###########################################################
# ovn_cleanConntrack.sh script to remove udp conntrack    #
# lines persistent in a cluster hitted by BZ 2043094      #
###########################################################

# Timestamp to be used in the logfile name
NOW=$(date +"%Y-%m-%d_%H-%M-%S")
# Logfile to save some DEBUG output
LOG="/tmp/ovn_cleanConntrack.sh.${NOW}.log"
# IP of the ovn-k8s-mp0 interface for a node subnet with mask /24 or /23
NODESUBNETIP=2
# Debug var to write DEBUG lines into the log
DEBUG=false
# Number of parallel jobs to be executed
PARALLELJOBS="${PARALLELJOBS:=4}"
# Var to contain the node name if the script has to be executed on a single node
SINGLENODE=''
# Var to contain the log to save the output instead the standard default system output
OUTPUTLOG=''

###########################################################
# usage(): prints the usage of the script
###########################################################
function usage() {
  echo "This script gives the potential list of commands to clean up wrong conntracks"
  echo "It only supports UDP stale entries"
  echo "It only considers clusterIP services"
  echo "It only works on IPV4 single stack env"
  echo "Assumes node subnet is the default /24 cidr (it also works for /23)"
  echo "Assumes Cluster CIDR is /16"
  echo "Checks for the Service CIDR to have one of the networks /8 /16 or /24"
  echo -e
  echo -e "\tUsage: $(basename "$0")"
  echo -e "\tHelp: $(basename "$0") -h"
  echo -e "\tSave extra DEBUG lines into the log: $(basename "$0") -d"
  echo -e "\tLimit the execution to a single node: $(basename "$0") -n node"
  echo -e "\tSet the KUBECONFIG env var to /kubeconfig/file: $(basename "$0") -k /kubeconfig/file"
  echo -e "\tSet the mode to quiet and save the output to /tmp/output.file: $(basename "$0") -q /tmp/output.file"
  echo -e
  echo "After the execution a logfile will be generated with the name ovn_cleanConntrack.DATE.log"
}

###########################################################
# setup(): initializes some variables after setting up
# the KUBECONFIG
###########################################################
function setup() {
  # ServiceNetwork of the cluster
  svcnetwork=$(oc get network cluster -o jsonpath='{ .spec.serviceNetwork[] }')
  # Clusternetwork of the cluster
  clusternetwork=$(oc get network cluster -o jsonpath='{ .spec.clusterNetwork[].cidr }' | cut -d'/' -f1 | sed -e 's/.$/2/')
}

###########################################################
# getServices(): prepares a list of services
# NOTE: We only care about services of type clusterIP that
# use UDP protocol
###########################################################
function getServices() {
  #filter by protocol=udp and only clusterips
  if [[ -z ${OUTPUTLOG} ]]; then
    echo "# Collecting service info..."
  fi
  OLDIFS=$IFS
  IFS=$'\n'
  for line in $(oc get services -A -o jsonpath='{range .items[?(@.spec.type=="ClusterIP")]}{@.spec.ports[*].protocol}{";"}{@.spec.clusterIP}{";"}{@.spec.ports[*].port}{";"}{"\n"}{end}' | grep -v 'None' | grep UDP); do
    words=$(echo "${line}" | wc -w)
    protos=$(echo "${line}" | cut -d';' -f1)
    ip=$(echo "${line}" | cut -d';' -f2)
    port1=$(echo "${line}" | cut -d';' -f3)
    if [ "${words}" -gt 1 ]; then
      ports=$(echo "${line}" | cut -d';' -f3)
      cports=$(echo "${ports}" | wc -w)
      while [ "${cports}" -gt 0 ]; do
        port=$(echo "${ports}" | cut -d' ' -f"${cports}")
        proto=$(echo "${protos}" | cut -d' ' -f"${cports}")
        if [ "${proto}" = "UDP" ]; then
          services="${services}\n${ip};${port}"
        fi
        cports=$((cports - 1))
      done
    else
      if [ "${protos}" = "UDP" ]; then
        services="${services}\n${ip};${port1}"
      fi
    fi
  done
  IFS=$OLDIFS
  echo -e "Services\n-----------------${services}" >>"${LOG}"
}

###########################################################
# getEndpoints(): prepares a list of endpoints
###########################################################
function getEndpoints() {
  if [[ -z ${OUTPUTLOG} ]]; then
    echo "# Collecting endpoints info..."
  fi
  endpoints=""
  #filter by protocol=udp and only clusterips
  OLDIFS=$IFS
  IFS=$'\n'
  for line in $(oc get endpoints -A -o jsonpath='{range .items[*].subsets[*]}{@.addresses[*].ip}{";"}{@.addresses[*].nodeName}{";"}{@.ports[*].port}{";"}{@.ports[*].protocol}{";"}{"\n"}{end}' | grep UDP); do
    ips=$(echo "${line}" | cut -d';' -f1)
    cips=$(echo "${ips}" | wc -w)
    nodes=$(echo "${line}" | cut -d';' -f2)
    ports=$(echo "${line}" | cut -d';' -f3)
    cports=$(echo "${ports}" | wc -w)
    protocols=$(echo "${line}" | cut -d';' -f4)

    if [ "${cips}" -gt 1 ]; then
      #ep multiple ip multiple ports
      if [ "${cports}" -gt 1 ]; then
        count=1
        while [ ${count} -le "${cips}" ]; do
          ip=$(echo "${ips}" | cut -d' ' -f"${count}")
          countports=1
          node=$(echo "${nodes}" | cut -d' ' -f"${count}")
          while [ ${countports} -le "${cports}" ]; do
            port=$(echo "${ports}" | cut -d' ' -f${countports})
            protocol=$(echo "${protocols}" | cut -d' ' -f${countports})
            if [ "${protocol}" = "UDP" ]; then
              endpoints="${endpoints}\n${ip};${node};${port}"
            fi
            countports=$((countports + 1))
          done
          count=$((count + 1))
        done
        #ep multiple ip 1 port
      else
        count=1
        while [ ${count} -le "${cips}" ]; do
          ip=$(echo "${ips}" | cut -d' ' -f${count})
          node=$(echo "${nodes}" | cut -d' ' -f${count})
          if [ "${protocols}" = "UDP" ]; then
            endpoints="${endpoints}\n${ip};${node};${ports}"
          fi
          count=$((count + 1))
        done

      fi
    else
      #ep 1 ip multiple ports
      if [ "${cports}" -gt 1 ]; then
        count=1
        while [ ${count} -le "${cports}" ]; do
          port=$(echo "${ports}" | cut -d' ' -f${count})
          protocol=$(echo "${protocols}" | cut -d' ' -f${count})
          if [ "${protocol}" = "UDP" ]; then
            endpoints="${endpoints}\n${ips};${nodes};${port}"
          fi
          count=$((count + 1))
        done
      #ep 1 ip 1 port
      else
        if [ "${protocols}" = "UDP" ]; then
          endpoints="${endpoints}\n${ips};${nodes};${ports}"
        fi
      fi
    fi
  done
  IFS=$OLDIFS
  echo -e "\nEndpoints\n-----------------${endpoints}\n" >>"${LOG}"
}

###########################################################
# isContrackInSvcNetwork(): checks if a contrack line fits
#                        the service network of the cluster
###########################################################
function isContrackInSvcNetwork() {
  snline=$1
  snnode=$2
  dst1=$(echo "${snline}" | awk -F"dst=" '{sub(/ .*/,"",$2);print $2}')
  dst1O1=$(echo "${dst1}" | cut -d';' -f1 | cut -d'.' -f1)
  dst1O2=$(echo "${dst1}" | cut -d';' -f1 | cut -d'.' -f2)
  dst1O3=$(echo "${dst1}" | cut -d';' -f1 | cut -d'.' -f3)
  netO1=$(echo "${svcnetwork}" | cut -d'.' -f1)
  netO2=$(echo "${svcnetwork}" | cut -d'.' -f2)
  netO3=$(echo "${svcnetwork}" | cut -d'.' -f3)
  mask=$(echo "${svcnetwork}" | cut -d'/' -f2)
  if [[ ${mask} == "8" ]]; then
    if [[ ${dst1O1} == "${netO1}" && ${dst1O2} == "${netO2}" && ${dst1O3} == "${netO3}" ]]; then
      if eval "${DEBUG}"; then echo "[${snnode}:isContrackInSvcNetwork] ${svcnetwork}: ${snline}" >>"${LOG}"; fi
      return 0
    else
      return 1
    fi
  fi
  if [[ ${mask} == "16" ]]; then
    if [[ ${dst1O1} == "${netO1}" && ${dst1O2} == "${netO2}" ]]; then
      if eval "${DEBUG}"; then echo "[${snnode}:isContrackInSvcNetwork] ${svcnetwork}: ${snline}" >>"${LOG}"; fi
      return 0
    else
      return 1
    fi
  fi
  if [[ ${mask} == "24" ]]; then
    if [[ ${dst1O1} == "${netO1}" ]]; then
      if eval "${DEBUG}"; then echo "[${snnode}:isContrackInSvcNetwork] ${svcnetwork}: ${snline}" >>"${LOG}"; fi
      return 0
    else
      return 1
    fi
  fi
}

###########################################################
# isContrackInServices(): checks if a contrack line fits
#                          one of the services
###########################################################
function isContrackInServices() {
  sline=$1
  snode=$2
  dst1=$(echo "${sline}" | awk -F"dst=" '{sub(/ .*/,"",$2);print $2}')
  dstport1=$(echo "${sline}" | awk -F"dport=" '{sub(/ .*/,"",$2);print $2}')
  OLDIFS=$IFS
  IFS=$'\n'
  services=$(echo -e "${services}" | xargs | sed -e 's/ /\n/g')
  for service in ${services}; do
    srvip=$(echo "${service}" | cut -d';' -f1)
    srvport=$(echo "${service}" | cut -d';' -f2)
    if [[ ${dst1} == "${srvip}" && ${dstport1} == "${srvport}" ]]; then
      if eval "${DEBUG}"; then echo "[${snode}:isContrackInServices] ${dst1}:${dstport1}: ${srvip}:${srvport}" >>"${LOG}"; fi
      return 0
    fi
  done
  IFS=${OLDIFS}
  return 1
}

###########################################################
# isContrackInEndPoints(): checks if the conntrack matches
#                          one of the endpoints source IP
#                          and source port
###########################################################
function isContrackInEndPoints() {
  eline=$1
  enode=$2
  src2=$(echo "${eline}" | awk -F"src=" '{sub(/ .*/,"",$3);print $3}')
  srcport2=$(echo "${eline}" | awk -F"sport=" '{sub(/ .*/,"",$3);print $3}')
  endpoints=$(echo -e "${endpoints}" | xargs | sed -e 's/ /\n/g')
  for endpoint in ${endpoints}; do
    epip=$(echo "${endpoint}" | cut -d';' -f1)
    epport=$(echo "${endpoint}" | cut -d';' -f3)
    if [[ ${epip} == "${src2}" && ${epport} == "${srcport2}" ]]; then
      if eval "${DEBUG}"; then echo "[${enode}:isContrackInEndPoints] ${epip}:${epport}: ${src2}:${srcport2}" >>"${LOG}"; fi
      return 0
    fi
  done
  if eval "${DEBUG}"; then echo "[${enode}:isContrackInEndPoints] NOT found ${epip}:${epport}: ${src2}:${srcport2}" >>"${LOG}"; fi
  return 1
}

############################################################
# isContrackInClusterCIDR: checks if the conntrack src
#                         (2nd tuple) is in the clusterCIDR
############################################################
function isContrackInClusterCIDR() {
  ccline=$1
  ccnode=$2
  src2=$(echo "${ccline}" | awk -F"src=" '{sub(/ .*/,"",$3);print $3}')
  srcoc1=$(echo "${src2}" | cut -d. -f1)
  srcoc2=$(echo "${src2}" | cut -d. -f2)
  cnoc1=$(echo "${clusternetwork}" | cut -d. -f1)
  cnoc2=$(echo "${clusternetwork}" | cut -d. -f2)
  if [[ ${srcoc1} == "${cnoc1}" && ${srcoc2} == "${cnoc2}" ]]; then
    if eval "${DEBUG}"; then echo "[${ccnode}:isContrackInClusterCIDR] ${clusternetwork}: ${src2}" >>"${LOG}"; fi
    if eval "${DEBUG}"; then echo "[${ccnode}:isContrackInClusterCIDR] ${ccline}" >>"${LOG}"; fi
    return 0
  else
    return 1
  fi
}

###########################################################
# generateCommands(): generates the conntrack lines to
#                     remove the faulty line
# Template on how to create the conntracks
# conntrack -D -s A.A.A.A -d B.B.B.B -r C.C.C.C -q A.A.A.A
# conntrack -D -s A.A.A.A -d C.C.C.C
# conntrack -D -s D.D.D.D -d C.C.C.C -r C.C.C.C -q D.D.D.D
#
# Where:
# src=A.A.A.A dst=B.B.B.B sport=42740 dport=5353 src=C.C.C.C
# dst=10.128.2.41 sport=5353 dport=42740 mark=0 secctx=sy...
#
# D.D.D.D is the ovn-k8s-mp0 interface IP.
###########################################################
function generateCommands() {
  gcnode=$1
  gcconn=$2
  gcpod=$3
  src1=$(echo "${gcconn}" | awk -F"src=" '{sub(/ .*/,"",$2);print $2}')
  dst1=$(echo "${gcconn}" | awk -F"dst=" '{sub(/ .*/,"",$2);print $2}')
  src2=$(echo "${gcconn}" | awk -F"src=" '{sub(/ .*/,"",$3);print $3}')
  nodesubnet=$(oc get node "${gcnode}" -o jsonpath='{.metadata.annotations.k8s\.ovn\.org/node-subnets}' | jq .default | xargs | cut -d'/' -f1)
  # shellcheck disable=SC2001
  nodesubnet=$(echo "${nodesubnet}" | sed -e "s/.$/${NODESUBNETIP}/")
  clustername=$(oc whoami --show-console | cut -d. -f3-)
  if [[ -n ${OUTPUTLOG} ]]; then
    # shellcheck disable=SC2129
    echo "# Cluster: ${clustername}" >>"${OUTPUTLOG}"
    echo "# Generating lines for node (${gcnode}) subnet:${nodesubnet}" >>"${OUTPUTLOG}"
    echo "# OVN Pod: ${gcpod}" >>"${OUTPUTLOG}"
    echo "# Raw line: ${gcconn}" >>"${OUTPUTLOG}"
    echo "oc -n openshift-ovn-kubernetes exec pod/${gcpod} -c ovnkube-node -- conntrack -D -s ${src1} -d ${dst1} -r ${src2} -q ${src1}" >>"${OUTPUTLOG}"
    echo "oc -n openshift-ovn-kubernetes exec pod/${gcpod} -c ovnkube-node -- conntrack -D -s ${src1} -d ${src2}" >>"${OUTPUTLOG}"
    echo "oc -n openshift-ovn-kubernetes exec pod/${gcpod} -c ovnkube-node -- conntrack -D -s ${nodesubnet} -d ${src2} -r ${src2} -q ${nodesubnet}" >>"${OUTPUTLOG}"
  else
    echo "# Cluster: ${clustername}"
    echo "# Generating lines for node (${gcnode}) subnet:${nodesubnet}"
    echo "# OVN Pod: ${gcpod}"
    echo "# Raw line: ${gcconn}"
    echo "oc -n openshift-ovn-kubernetes exec pod/${gcpod} -c ovnkube-node -- conntrack -D -s ${src1} -d ${dst1} -r ${src2} -q ${src1}"
    echo "oc -n openshift-ovn-kubernetes exec pod/${gcpod} -c ovnkube-node -- conntrack -D -s ${src1} -d ${src2}"
    echo "oc -n openshift-ovn-kubernetes exec pod/${gcpod} -c ovnkube-node -- conntrack -D -s ${nodesubnet} -d ${src2} -r ${src2} -q ${nodesubnet}"
  fi
  # Saving the commands into the log
  # shellcheck disable=SC2129
  echo "# Generating lines for node (${gcnode}) subnet:${nodesubnet}" >>"${LOG}"
  echo "# OVN Pod: ${gcpod}" >>"${LOG}"
  echo "# Raw line: ${gcconn}" >>"${LOG}"
  echo "oc -n openshift-ovn-kubernetes exec pod/${gcpod} -c ovnkube-node -- conntrack -D -s ${src1} -d ${dst1} -r ${src2} -q ${src1}" >>"${LOG}"
  echo "oc -n openshift-ovn-kubernetes exec pod/${gcpod} -c ovnkube-node -- conntrack -D -s ${src1} -d ${src2}" >>"${LOG}"
  echo "oc -n openshift-ovn-kubernetes exec pod/${gcpod} -c ovnkube-node -- conntrack -D -s ${nodesubnet} -d ${src2} -r ${src2} -q ${nodesubnet}" >>"${LOG}"
}

###########################################################
# getConntrack(): loops over the nodes using the          #
#                 ovnkube-node pods, gets the udp         #
#                 conntrackts, validates them and         #
#                 generates the lines to remove it        #
###########################################################
function getConntrack() {
  if [[ -n ${SINGLENODE} ]]; then
    nodes=$(oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-node -o jsonpath='{range .items[*]}{@.metadata.name}{";"}{@..nodeName}{"\n"}{end}' | grep "${SINGLENODE}")
  else
    nodes=$(oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-node -o jsonpath='{range .items[*]}{@.metadata.name}{";"}{@..nodeName}{"\n"}{end}')
  fi
  # Discarding NotReady nodes
  for n in ${nodes}; do
    onenode=$(echo "${n}" | cut -d';' -f2)
    nodestatus=$(oc get node "${onenode}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    if [ "${nodestatus}" = "True" ]; then
      readynodes="${n} ${readynodes}"
    fi
  done

  if [[ -z ${OUTPUTLOG} ]]; then
    echo "# Building cache for clusterIP services..."
  fi
  if eval "${DEBUG}"; then echo -e "\nConntracks\n-----------------" >>"${LOG}"; fi

  for line in ${readynodes}; do
    # See https://medium.com/@robert.i.sandor/getting-started-with-parallelization-in-bash-e114f4353691
    ((i = i % PARALLELJOBS))
    ((i++ == 0)) && wait
    (
      OLDIFS=$IFS
      IFS=$'\n'
      pod=$(echo "${line}" | cut -d';' -f1)
      node=$(echo "${line}" | cut -d';' -f2)
      conntracks=$(oc -n openshift-ovn-kubernetes exec pod/"${pod}" -c ovnkube-node -- conntrack -L -p udp 2>/dev/null)
      for conntrack in $(echo "${conntracks}" | sed 's/udp/\nudp/g' | sed 's/\[UNREPLIED\]//g' | sed 's/\[ASSURED\]//g' | tr -s ' '); do
        # if not found in the service network or found in services or if not found in clusterCIDR or
        # if found in endpoints, ignore it
        # otherwise generate the commands to remove it
        if isContrackInSvcNetwork "${conntrack}" "${node}"; then
          if isContrackInClusterCIDR "${conntrack}" "${node}"; then
            if isContrackInServices "${conntrack}" "${node}"; then
              if ! isContrackInEndPoints "${conntrack}" "${node}"; then
                echo -e "===> Generating conntrack lines for (${node}:${pod}): $conntrack}" >>"${LOG}"
                generateCommands "${node}" "${conntrack}" "${pod}"
              fi
            fi
          fi
        fi
      done
      wait
      IFS=$OLDIFS
    ) &
  done
}

# Main
while getopts "dhq:k:n:" flag; do
  case "${flag}" in
  n)
    SINGLENODE=${OPTARG}
    ;;
  q)
    OUTPUTLOG=${OPTARG}
    echo "Quiet mode enabled saving output into ${OUTPUTLOG}" >>"${LOG}"
    ;;
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
  *)
    echo >&2 "Invalid option: $*"
    usage
    exit 1
    ;;
  esac
done

# Initialize vars dependent of KUBECONFIG
setup
# Prepare the cluster services data
getServices
# Prepare the cluster endpoints data
getEndpoints
# Loop over the conntrack to find persistent conntracks
# and generate the conntrackt commands to remove it
getConntrack
if [[ -z ${OUTPUTLOG} ]]; then
  echo "# Logged operations into the file ${LOG}"
fi
