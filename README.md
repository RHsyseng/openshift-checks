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

### Info

Script | Description
------------ | -------------
[clusteroperators](info/clusteroperators) | Show the clusteroperators

## Collaborate

Add a new script to get some information or to perform some check in the proper
folder and create a pull request.
