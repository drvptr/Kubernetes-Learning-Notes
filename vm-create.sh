#!/bin/sh

ARGC=3

LAN_BRIDGE="br-lan"

echo "$@" | grep -E '(-h|--help)' > /dev/null 2>&1
HELP=$?
if [ $# -gt $ARGC -o $# -le 0 -o $HELP -eq 0 ] ; then
	echo "Usage: $0 <vm-name> [ -s <5G>]"
	exit 1
fi

DISKSZ=5G
if [ $# -eq 3 ] ; then
        if [ "$2" = "-s" ] ; then
                DISKSZ="$3"
        else
                echo "Error: Invalid disk size"
                exit 1
        fi
fi

if [ -z "$VMPTH" ] ; then
	VMPTH="/vm"
fi

VMNAME="$1"
DISK="$VMPTH/$VMNAME.qcow2"

if virsh dominfo "$VMNAME" >/dev/null 2>&1 ; then
        echo "No changes: VM already exists"
        exit 1
fi


qemu-img create -f qcow2 "$DISK" "$DISKSZ" || exit 1

virt-install \
  --name "$VMNAME" \
  --memory 2048 \
  --vcpus 2 \
  --disk path="$DISK",format=qcow2 \
  --cdrom /vm/iso/ubuntu-24.04-live-server-amd64.iso \
  --network bridge=$LAN_BRIDGE,model=virtio \
  --graphics vnc,listen=127.0.0.1,port=-1 \
  --osinfo detect=on,require=off  || exit 1

