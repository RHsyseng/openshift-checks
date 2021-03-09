# openshift-checks

A set of scripts to run basic checks on an OpenShift cluster. PRs welcome!

> :warning: This is an unofficial tool, don't blame us if it breaks your cluster

## Usage

```bash
$ ./openshift-checks.sh -h
Usage: openshift-checks.sh [-h]

This script will run a minimum set of checks to an OpenShift cluster

Available options:

-h, --help                        Print this help and exit
-v, --verbose                     Print script debug info
-l, --list                        Lists the available checks
-s <script>, --single <script>    Executes only the provided script
--no-info                         Disable cluster info commands (default: enabled)
--no-checks                       Disable cluster check commands (default: enabled)

With no options, it will run all checks and info commands with no debug info
```

### Container

You can build your own container with all the scripts with the included [Containerfile](Containerfile)

```bash
$ podman build --tag foobar/openshiftchecks .
STEP 1: FROM registry.redhat.io/ubi8/ubi:latest
...
```

Then, run it with a proper kubeconfig attached and use any flag you need:

```bash
$ podman run -it --rm -v /home/foobar/kubeconfig:/kubeconfig:Z -e KUBECONFIG=/kubeconfig foobar/openshiftchecks:latest -h
Usage: openshift-checks.sh [-h]
...
```

You can even create a handy alias:

```bash
$ alias openshift-checks="podman run -it --rm -v /home/foobar/kubeconfig:/kubeconfig:Z -e KUBECONFIG=/kubeconfig foobar/openshiftchecks:latest"
$ openshift-checks -s info/00-clusterversion
Using default/api-foobar-example-com:6443/system:admin context
...
```

### CronJob

The checks can be scheduled to run periodically in an OpenShift cluster by
creating a CronJob.

Check the [cronjob.yaml](cronjob.yaml) example.

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
[ctrlnodes](checks/ctrlnodes) | Checks if any controller nodes have had the NoSchedule taint removed
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
[clusterversion](info/00-clusterversion) | Show the clusterversion
[clusteroperators](info/01-clusteroperators) | Show the clusteroperators
[nodes](info/02-nodes) | Show the nodes status
[pods](info/03-pods) | Show the pods running in the cluster
[biosversion](info/biosversion) | Show the nodes' BIOS version
[ethtool-firmware-version](info/ethtool-firmware-version) | Show the nodes' NIC firmware version using ethtool
[mellanox-firmware-version](info/mellanox-firmware-version) | Show the nodes' Mellanox Connect-4 firmware version
[intel-firmware-version](info/intel-firmware-version) | Reports firmware versions of supported Intel cards if any are found
[mtu](info/mtu) | Show the nodes' MTU for some interfaces
[ovs-hostnames](info/ovs-hostnames) | Show the ovs database chassis hostnames

### Environment variables

Environment variable | Default value | Description
------------ | ------------- | -------------
OCDEBUGIMAGE | registry.redhat.io/rhel8/support-tools:latest | Used by `oc debug`.
OSETOOLSIMAGE | registry.redhat.io/openshift4/ose-tools-rhel8:latest | Used by `oc debug` in [ethtool-firmware-version](info/ethtool-firmware-version)
RESTART_THRESHOLD | 10 | Used by the [restarts](checks/restarts) script.
INTEL_IDS | 8086:158b | Intel device IDs to check for firmware. Can be overridden for non-supported NICs.

### About firmware version

The current [intel-firmware-version](info/intel-firmware-version) and
[mellanox-firmware-version](info/mellanox-firmware-version) checks only check
the firmware version of the SRIOV operator supported NICs ([in 4.6](https://docs.openshift.com/container-platform/4.6/networking/hardware_networks/about-sriov.html#supported-devices_about-sriov)).

You can add your own device ID if needed by modifying the script (hint, the
variable is called `IDS` and the format is `vendorID_A:deviceID_A vendorID_B:deviceID_B`)

## Collaborate

Add a new script to get some information or to perform some check in the proper
folder and create a pull request.

## Tips & Tricks

### Send an email if some check fails

You can pipe the script to `mail` and if there are any errors, an email will be
sent.

First you can configure postfix (already included in RHEL8) as relay host
(see https://access.redhat.com/solutions/217503). As an example:

* Append the following settings in `/etc/postfix/main.cf`:

```bash
myhostname = kni1-bootstrap.example.com
relayhost = smtp.example.com
```

* Restart the postfix service:

```bash
sudo systemctl restart postfix
```

* Test it:

```bash
echo "Hola" | mail -s 'Subject' johndoe@example.com
```

Then, run the script as:

```bash
/openshift-checks.sh > /tmp/oc-errors 2>&1 || mail -s "Something has failed" johndoe@example.com < /tmp/oc-errors
```

As a bonus you can include this in a cronjob for periodic checks.
