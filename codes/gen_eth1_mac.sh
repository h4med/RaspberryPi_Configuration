#!/bin/bash

# This script extracts the MAC from OTP and adds plus one (+1) to it
# and assigns this new MAC to eth1. This new MAC should also be printed
# on the MAC label of the Pi-Tron.

#------------------------------------------------------------------------
# Check the OTP registers
#------------------------------------------------------------------------
otpreg=$( vcgencmd otp_dump | grep "64:")
otpreg2=$( vcgencmd otp_dump | grep "65:")
if [ -z $(echo $otpreg | grep "00000000") ]
then
    echo ""
    echo " OTP registers have a MAC address programed!"
    # Combine both register to create one string
    otpreg3=$otpreg2$otpreg
    # Cut off unwanted parts
    mactomake=${otpreg3/65:}
    mactomake=${mactomake/64:}
    # Extract the MAC address
    mactomake=${mactomake:0:12}
    # Turn the MAC address string from a hex value into an integer
    macint=$((0x${mactomake}))
    # Add plus one (1) to the MAC address
    macintnew=$(($macint+1))
    # Convert the MAC address back in to a hex value
    macnew=$( printf "%x" $macintnew )
    # Turn all letters into capital letters
    macbig=${macnew^^}
    # Add the colons after every 2 numbers
    macfinal=$( echo $macbig | sed "s/\(..\)/\1:/g;s/:$//" )
else
    echo ""
    echo " ERROR: OTP registers are empty! This script is not needed!"
    exit 0
fi

#------------------------------------------------------------------------
# Set eth1 new MAC address
#------------------------------------------------------------------------
echo " Setting new MAC on eth1: "$macfinal
echo ""
# Deactivate eth1
ip link set dev eth1 down
# Set the new eth1 MAC address
ip link set dev eth1 address $macfinal
# Activate eth1 again
ip link set dev eth1 up
#------------------------------------------------------------------------

exit 0