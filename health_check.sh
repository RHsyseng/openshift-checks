#!/usr/bin/env bash

export errors=0
export restart_threshold=10 #arbitray

function check_terminating() {
  terminating_pods=$(oc get pods -A | grep -c 'Terminating')
  if [[ $terminating_pods -ge 1 ]]; then
    echo "Pods in Terminating state ($terminating_pods):"
    oc get pods -A | grep 'Terminating'
    errors=$(($errors+1))
  fi
}

function check_operators() {
  bad_operators=$(oc get co --no-headers | egrep -civ 'True.*False.*False')
  if [[ $bad_operators -ge 1 ]]; then
    echo "Operators in Bad State ($bad_operators):"
    oc get co --no-headers | egrep -iv 'True.*False.*False'
    errors=$(($errors+1))
  fi
}

function check_machineconfigs() {
  degrated_mcps=$(oc get mcp -o json | jq '.items[] | { name: .metadata.name, status: .status } | select (.status.degradedMachineCount >= 1) | { name: .name, status: .status.degradedMachineCount}')
  if [[ ! -z $degrated_mcps  ]]; then
    echo "MachineConfigProfiles in Degraded State:"
    echo $degrated_mcps | jq .
    errors=$(($errors+1))
  fi
}

function check_nodes() {
  nodes_not_ready=$(oc get nodes -o json | jq '.items[] | { name: .metadata.name, type: .status.conditions[] } | select ((.type.type == "Ready") and (.type.status == "False"))')
  if [[ ! -z $nodes_not_ready ]]; then
    echo "Nodes in NotReady state:"
    echo $nodes_not_ready | jq
    errors=$(($errors+1))
  fi
  disabled_nodes=$(oc get nodes -o json | jq '.items[] | { name: .metadata.name, status: .metadata.labels."kubevirt.io/schedulable" } | select (.status == "false")')
  if [[ ! -z $disabled_nodes ]]; then
    echo "Nodes in Disabled:"
    echo $disabled_nodes | jq
    errors=$(($errors+1))
  fi
  
}

function check_alertmanager() {
  # https://access.redhat.com/solutions/4250221
  alert_url=$(oc -n openshift-monitoring get routes/alertmanager-main -o json | jq -r .spec.host)
  alerts=$(curl -s -k -H "Authorization: Bearer $(oc -n openshift-monitoring sa get-token prometheus-k8s)" https://$alert_url/api/v1/alerts | jq '.data[].labels |  {alert: .alertname, severity: .severity} | select(.severity == "warning")')
  
  if [[ ! -z $alerts ]]; then
    echo "Alerts currently firing:"
    echo $alerts | jq
    errors=$(($errors+1))
  fi

}

function check_restarts() {
  restarts=$(oc get pods -o json -A| jq -r ".items[] | { name: .metadata.name, project: .metadata.namespace, restarts: .status.containerStatuses[].restartCount } | select(.restarts > $restart_threshold)")
  if [[ ! -z $restarts ]]; then
    echo "Pods that have a high restart count (> $restart_threshold):"
    echo $restarts | jq .
    errors=$(($errors+1))
  fi
}

function main() {

  echo "Running basic health checks"

  check_terminating
  check_operators
  check_machineconfigs
  check_nodes
  check_alertmanager
  check_restarts

  echo "Total issues found: $errors"
  

}

main $@
