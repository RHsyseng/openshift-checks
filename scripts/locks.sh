#!/usr/bin/env bash

declare -A ns_pods
ORIG_IFS=$IFS
IFS=$(echo -en "\n\b")

for line in $(sudo lslocks | egrep -v '(unknown)' | awk '{print $2}' | sort -nr | uniq -c | sort -nr | egrep -v 'unknown|-1' | grep -v PID); do
  count=$(echo $line | awk '{print $1}');
  pid=$(echo $line | awk '{print $2}');
  orig_pid=$pid
  ppid=$(grep PPid /proc/${pid}/status | awk '{print $2}')
  while [[ $ppid -gt 1 ]]; do
    pid=$ppid
    ppid=$(grep PPid /proc/${pid}/status | awk '{print $2}')
  done
  if [[ $ppid -eq 1 ]]; then
    ppid=$pid
  fi
  if [[ $(ps -hp $ppid -o cmd | grep -c conmon) -eq 1 ]]; then
    ns=$(ps -hp $ppid -o cmd | grep conmon | awk '{print $9}' | awk -F/ '{print $5}' | awk -F_ '{print $1}')
    pod=$(ps -hp $ppid -o cmd | grep conmon | awk '{print $9}' | awk -F/ '{print $5}' | awk -F_ '{print $2}')
    if [ ${ns_pods["${ns}/${pod}"]} ]; then
      ns_pods["${ns}/${pod}"]=`expr ${ns_pods["${ns}/${pod}"]} + $count`
    else
      ns_pods["${ns}/${pod}"]=$count
    fi
  fi
done
for pod in "${!ns_pods[@]}"; do
  echo $pod ${ns_pods[$pod]}
done | sort -nr -k2 | column -t 

IFS=$ORIG_IFS
