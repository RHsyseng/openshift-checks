# openshift-check tools

A set of scripts to run basic checks on an OpenShift cluster. PRs welcome!

This >:warning: is an unofficial tool, don't blame us if it breaks your cluster

## ovn_cleanConntrack.sh

### Usage

```bash
$ ./ovn_cleanConntrack.sh -h
This script gives the potential list of commands to clean up wrong conntracks
It only supports UDP stale entries
It only considers clusterIP services
It only works on IPV4 single stack env
Assumes node subnet is the default /24 cidr (it also works for /23)
Assumes Cluster CIDR is /16
Checks for the Service CIDR to have one of the networks /8 /16 or /24

        Usage: ovn_cleanConntrack.sh
        Help: ovn_cleanConntrack.sh -h
        Save extra DEBUG lines into the log: ovn_cleanConntrack.sh -d
        Limit the execution to a single node: ovn_cleanConntrack.sh -n node
        Set the KUBECONFIG env var to /kubeconfig/file: ovn_cleanConntrack.sh -k /kubeconfig/file
        Set the mode to quiet and save the output to /tmp/output.file: ovn_cleanConntrack.sh -q /tmp/output.file

After the execution a logfile will be generated with the name ovn_cleanConntrack.DATE.log
```

### Examples

Saving extra debug lines in the log file:

```bash
$ ./ovn_cleanConntrack.sh -d
```

Single node execution:

```bash
$ ./ovn_cleanConntrack.sh -s my.node.com
```

For the -k parameter, the original behavior is still the same but if you want to analyze different clusters from the same bastion you can do it using the -k parameter to pass the kubeconfig file to the script, for example:

```bash
$ ./ovn_cleanConntrack.sh -k /home/kni/clusterconfigs/cluster1/auth/kubeconfig
$ ./ovn_cleanConntrack.sh -k /home/kni/clusterconfigs/cluster2/auth/kubeconfig
$ ./ovn_cleanConntrack.sh -k /home/kni/clusterconfigs/cluster3/auth/kubeconfig
```

In the previous example, the script will analyse the clusters indicated by the kubeconfig files on `/home/kni/clusterconfigs/cluster1/kubeconfig`, `/home/kni/clusterconfigs/cluster2/kubeconfig` and `/home/kni/clusterconfigs/cluster3/kubeconfig`
If no -k is indicated the script expects to have the KUBECONFIG variable exported in the system otherwise it will give an error because it can't connect.

For the -q parameter, instead of printing the output to the standard output now you can indicate the file were to save the output of the script, to cover the commented use case for running on batch mode:

```bash

$ ./ovn_cleanConntrack.sh -k /home/kni/clusterconfigs/cluster1/auth/kubeconfig -q /tmp/cluster1.output
$ ./ovn_cleanConntrack.sh -k /home/kni/clusterconfigs/cluster2/auth/kubeconfig -q /tmp/cluster2.output
$ ./ovn_cleanConntrack.sh -k /home/kni/clusterconfigs/cluster3/auth/kubeconfig -q /tmp/cluster3.output
```

If no conntracks with issues are found the files `/tmp/cluster?.output` won't be created. If no `-q` is indicated, the script will print the results in the standard output.

Here is an example of how to configure a cronjob to run the script every hour (you can place it on `/etc/cron.d/1conntracks`).
This example uses the parameters `-k` and `-q` indicating the kubeconfig and the file to save the output:

```bash
# Run hourly
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
MAILTO=root
0 * * * * kni /usr/local/bin/ovn_cleanConntrack.sh -k /home/kni/clusterconfigs/cluster1/auth/kubeconfig -q /tmp/ovnconntracks_cluster1.log
10 * * * * kni /usr/local/bin/ovn_cleanConntrack.sh -k /home/kni/clusterconfigs/cluster2/auth/kubeconfig -q /tmp/ovnconntracks_cluster2.log
20 * * * * kni /usr/local/bin/ovn_cleanConntrack.sh -k /home/kni/clusterconfigs/cluster3/auth/kubeconfig -q /tmp/ovnconntracks_cluster3.log
```

In that example, the debug log is still being generated using the LOG var inside the script, but that is a debug log file in case we need to debug the script behavior, and it can be modified according to bastion space and needs.

## recover-northd.sh

### Usage

```bash
$ ./recover-northd.sh -h
This script checks if northd is stuck and optionally intervene

        Usage: recover-northd.sh
        Help: recover-northd.sh -h
        Save extra DEBUG lines into the log: recover-northd.sh -d
        Set the KUBECONFIG env var to /kubeconfig/file: recover-northd.sh -k /kubeconfig/file
 				Remediate the issue: recover-northd.sh -r
```

After the execution, a logfile will be generated with the name `recover-northd.DATE.log`

### Examples

Saving extra debug lines in the log file:

```bash
$ ./recover-northd.sh -d
```

For the -k parameter, the original behavior is still the same but if you want to analyse different clusters from the same bastion you can do it using the -k parameter to pass the kubeconfig file to the script, for example:

```bash
$ ./recover-northd.sh -k /home/kni/clusterconfigs/cluster1/auth/kubeconfig
$ ./recover-northd.sh -k /home/kni/clusterconfigs/cluster2/auth/kubeconfig
$ ./recover-northd.sh -k /home/kni/clusterconfigs/cluster3/auth/kubeconfig
```

In the previous example, the script will analyse the clusters indicated by the kubeconfig files on `/home/kni/clusterconfigs/cluster1/kubeconfig`, `/home/kni/clusterconfigs/cluster2/kubeconfig` and `/home/kni/clusterconfigs/cluster3/kubeconfig`

If no `-k` is indicated the script expects to have the KUBECONFIG variable exported in the system otherwise it will give an error because it can't connect.

For the `-r` parameter, the script will send an exit to the northd container for OVN to elect a new leader:

```bash
$ ./recover-northd.sh -k /home/kni/clusterconfigs/cluster1/auth/kubeconfig -r
```
