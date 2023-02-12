#!/bin/bash

VMS="control-plane-0 worker-node-0 worker-node-1"
SLEEPYTIME=5

start_VMs() {
  for VM in $VMS
  do
    echo "Starting $VM"
    sudo virsh start $VM; sleep $SLEEPYTIME
  done
}

case $1 in 
  start)
    start_VMs
  ;;
esac

