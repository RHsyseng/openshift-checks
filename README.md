# openshift-checks

A set of scripts to run basic sanity/health checks on an OpenShift cluster. PRs welcome!

## Usage
~~~
$ ./health_check.sh -h
Usage: health_check.sh [-h]

This script will run a minimum set of health checks to an OpenShift cluster

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
--no-info       Disable cluster info commands (default: enabled)
--no-checks     Disable cluster check commands (default: enabled)
##
