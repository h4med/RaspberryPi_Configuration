#!/bin/bash
mac0="70:b3:d5:04:c8:3c"
mac1="70:b3:d5:04:c8:3d"

echo "Setting new MAC on eth0: "$mac0
ip link set dev eth0 down
ip link set dev eth0 address $mac0
ip link set dev eth0 up
echo "MAC eth0 set done."

echo "Setting new MAC on eth1: "$mac1
ip link set dev eth1 down
ip link set dev eth1 address $mac1
ip link set dev eth1 up
echo "MAC eth1 set done."
echo ""
