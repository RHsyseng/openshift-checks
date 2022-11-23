# info

| Script                                                         | Description                                                       |
| -------------------------------------------------------------- | ----------------------------------------------------------------- |
| [info/ovs-hostnames](info/ovs-hostnames)                       | Show the ovs database chassis hostnames                           |
| [info/node-versions](info/node-versions)                       | Show node components versions such as kubelet, crio, kernel, etc. |
| [info/container-images-running](info/container-images-running) | Show the images of the containers running in the cluster          |
| [info/01-clusteroperators](info/01-clusteroperators)           | Show the clusteroperators                                         |
| [info/00-clusterversion](info/00-clusterversion)               | Show the clusterversion                                           |
| [info/03-pods](info/03-pods)                                   | Show the pods running in the cluster                              |
| [info/02-nodes](info/02-nodes)                                 | Show the nodes status                                             |
| [info/04-machineset](info/04-machineset)                       | Show the machinesets status                                       |
| [info/bmh-machine-node](info/bmh-machine-node)                 | Show the node,machine and bmh relationship                        |
| [info/biosversion](info/biosversion)                           | Show the nodes' BIOS version                                      |
| [info/container-images-stored](info/container-images-stored)   | Show the container images stored in the cluster hosts             |
| [info/ethtool-firmware-version](info/ethtool-firmware-version) | Show the nodes' NIC firmware version using ethtool                |
| [info/locks](info/locks)                                       | List all pods with locks on each node                             |
| [info/mtu](info/mtu)                                           | Show the nodes' MTU for some interfaces                           |

# pre

| Script                                                               | Description                                                 |
| -------------------------------------------------------------------- | ----------------------------------------------------------- |
| [pre/00-install-config-valid-yaml](pre/00-install-config-valid-yaml) | Checks if the install-config.yaml file is a valid yaml file |
| [pre/dns-hostnames](pre/dns-hostnames)                               | Checks if the api and wildcard DNS entries are correct      |

# ssh

| Script                         | Description                                                                            |
| ------------------------------ | -------------------------------------------------------------------------------------- |
| [ssh/bz1941840](ssh/bz1941840) | Checks if the authentication-operator is using excessive RAM -> hung kubelet BZ1941840 |

# checks

| Script                                                               | Description                                                                                |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [checks/pvc](checks/pvc)                                             | Checks if there are persistent volume claims that are not bound                            |
| [checks/entropy](checks/entropy)                                     | Checks if the workers have enough entropy                                                  |
| [checks/mellanox-firmware-version](checks/mellanox-firmware-version) | Checks if the nodes' Mellanox Connect-4 firmware version is below the recommended version. |
| [checks/port-thrashing](checks/port-thrashing)                       | Checks if there are OVN pods thrashing                                                     |
| [checks/alertmanager](checks/alertmanager)                           | Checks if there are warning or error alerts firing                                         |
| [checks/restarts](checks/restarts)                                   | Checks if there are pods restarted > n times (10 by default)                               |
| [checks/clusterversion_errors](checks/clusterversion_errors)         | Checks if there are clusterversion errors                                                  |
| [checks/terminating](checks/terminating)                             | Checks if there are pods terminating                                                       |
| [checks/pdb](checks/pdb)                                             | Checks if there are PodDisruptionBudgets with 0 disruptions allowed                        |
| [checks/ovn-pods-memory-usage](checks/ovn-pods-memory-usage)         | Checks if the memory usage of the OVN pods is under the LIMIT threshold                    |
| [checks/mcp](checks/mcp)                                             | Checks if there are degraded mcp                                                           |
| [checks/notrunningpods](checks/notrunningpods)                       | Checks if there are not running pods                                                       |
| [checks/csr](checks/csr)                                             | Checks if there are pending csr                                                            |
| [checks/ctrlnodes](checks/ctrlnodes)                                 | Checks if any controller nodes have had the NoSchedule taint removed                       |
| [checks/sriov](checks/sriov)                                         | Checks if the SR-IOV network state is synced                                               |
| [checks/bz1948052](checks/bz1948052)                                 | Checks for BZ 1948052 based on kernel version                                              |
| [checks/nodes](checks/nodes)                                         | Checks if there are not ready or not schedulable nodes                                     |
| [checks/operators](checks/operators)                                 | Checks if there are operators in 'bad' state                                               |
| [checks/chronyc](checks/chronyc)                                     | Checks if the worker clocks are synced using chronyc                                       |
| [checks/iptables-22623-22624](checks/iptables-22623-22624)           | Checks if the nodes iptables rules are blocking 22623/tpc or 22624/tcp                     |
| [checks/zombies](checks/zombies)                                     | Checks if more than 5 zombie processes exist on the hosts                                  |
