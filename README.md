# openshift-checks

A set of scripts to run basic checks on an OpenShift cluster. PRs welcome!

> :warning: This is an unofficial tool, don't blame us if it breaks your cluster

## Usage

```bash
$ ./openshift-checks.sh -h
Usage: openshift-checks.sh [-h]

This script will run a minimum set of checks to an OpenShift cluster

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
--no-info       Disable cluster info commands (default: enabled)
--no-checks     Disable cluster check commands (default: enabled)
```

## How it works

The `openshift-checks.sh` script is just a wrapper around bash scripts located
in the [info](./info) or [checks](./checks) folders.

### Checks

Script | Description
------------ | -------------
[alertmanager](checks/alertmanager) | Checks if there are warning or error alerts firing
[chronyc](checks/chronyc) | Checks if the worker clocks are synced using chronyc
[clusterversion_errors](checks/clusterversion_errors) | Checks if there are clusterversion errors
[csr](checks/csr) | Checks if there are pending csr
[entropy](checks/entropy) | Checks if the workers have enough entropy
[iptables-22623-22624](checks/iptables-22623-22624) | Checks if the nodes iptables rules are blocking 22623/tpc or 22624/tcp
[mcp](checks/mcp) | Checks if there are degraded mcp
[nodes](checks/nodes) | Checks if there are not ready or not schedulable nodes
[notrunningpods](checks/notrunningpods) | Checks if there are not running pods
[operators](checks/operators) | Checks if there are operators in 'bad' state
[restarts](checks/restarts) | Checks if there are pods restarted > `n` times (10 by default)
[terminating](checks/terminating) | Checks if there are pods terminating

### Info

Script | Description
------------ | -------------
[biosversion](info/biosversion) | Show the nodes' BIOS version
[clusteroperators](info/clusteroperators) | Show the clusteroperators
[clusterversion](info/clusterversion) | Show the clusterversion
[mtu](info/mtu) | Show the nodes' MTU for some interfaces
[nodes](info/nodes) | Show the nodes status
[ovs-hostnames](info/ovs-hostnames) | Show the ovs database chassis hostnames
[pods](info/pods) | Show the pods running in the cluster

## Collaborate

Add a new script to get some information or to perform some check in the proper
folder and create a pull request.
