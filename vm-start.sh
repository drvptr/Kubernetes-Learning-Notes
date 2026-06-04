#!/bin/sh

VM_NETWORK="10.0.0.0/24"
WAN_MAC="52:54:00:66:bf:48"

if [ -z "$VMPTH" ] ; then
	VMPTH="/vm"
	if [ -d "$VMPTH" ] ; then
		echo "Error: $VMPTH directory not exists. Please specify vm directory: VMPAPTH=/path-to-vm $0"
		exit 1
	fi
fi

CHANGED=0
for VM in $(ls /vm/*.qcow2) ; do
	VM_NAME="$(basename $VM | rev | cut -d '.' -f 2- | rev)"
	if virsh list --all | grep $VM_NAME | grep 'shut off' 1>&2 > /dev/null; then
	       	virsh start $VM_NAME
	fi
	CHANGED=1
done

if [ $CHANGED -eq 1 ] ; then
	sleep 20
fi

WAN_IP="$(arp-scan --interface=br-wan --localnet 2> /dev/null | grep '52:54:00:66:bf:48' | cut  -f 1,1)"

if [ -n "$WAN_IP" ] ; then
	if ! ip r | grep $VM_NETWORK 1>&2 > /dev/null ; then
	       	ip route add "$VM_NETWORK" via "$WAN_IP"
	fi
else
	printf "Warning:\n\tLAN route is not added.\n\tEnsure that WAN MAC is correct in $0 file\n\tYou can find out it by the next command:\n\t\t virsh dumpxml <router_vm_name> | grep 'mac address'"
fi

