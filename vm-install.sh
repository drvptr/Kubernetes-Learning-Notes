#!/bin/sh

#Script for fast install worker-nodes. If you want to install router you can use manual command 'virsh-instal'

LAN_BRIDGE="br-lan"

if ! ip a show "$LAN_BRIDGE" ; then
	echo "Error: bridge $LAN_BRIDGE not exists. Please specify it: LAN_BRIDGE=vm_br_name $0"
	exit 1
fi

echo "$@" | grep -E '(-h|--help)' >/dev/null 2>&1
HELP=$?

if [ $# -ne 2 -a $# -ne 4 ] || [ $HELP -eq 0 ] ; then
        echo "Usage: $0 <vm-name> <iso-image> [ -s <5G> ]"
        exit 1
fi

VMNAME="$1"
ISO="$2"

DISKSZ="8G"

if [ $# -eq 4 ] ; then
        if [ "$3" = "-s" ] ; then
                DISKSZ="$4"
        else
                echo "Error: Invalid disk size argument"
                exit 1
        fi
fi

if [ -z "$VMPTH" ] ; then
	VMPTH="/vm"
	if ! [ -d "$VMPTH" ] ; then
		echo "Error: $VMPTH directory not exists. Please specify vm directory: VMPTH=/path-to-vm $0"
		exit 1
	fi
fi

if ! [ -f "$ISO" ] ; then
        echo "Error: No such image $ISO"
        exit 1
fi

if virsh dominfo "$VMNAME" >/dev/null 2>&1 ; then
        echo "No changes: VM already exists"
        exit 1
fi

DISK="$VMPTH/$VMNAME.qcow2"

qemu-img create -f qcow2 "$DISK" "$DISKSZ" || exit 1

virt-install \
  --name "$VMNAME" \
  --memory 2048 \
  --vcpus 2 \
  --disk path="$DISK",format=qcow2 \
  --cdrom "$ISO" \
  --network bridge=$LAN_BRIDGE,model=virtio \
  --graphics vnc,listen=127.0.0.1,port=-1 \
  --osinfo detect=on,require=off
