#!/bin/bash

# OKAY, so, we assume that we are passed the VM number as $1
# if it is not passed, we can declare a failure and exit
if  [ -z "$1" ]; then
    echo "No VM number was declared."
    exit 1
fi


# Lets declare the static variables we'll use throughout the script 
VM_NAME="base-debian-vm"
NEW_VM_NAME="deb0$1-vm"
ORIGINAL_VM_IMG_PATH="/mnt/vm images/$VM_NAME.qcow2"
NEW_VM_IMG_PATH="/mnt/vm images/on-demand-images/$NEW_VM_NAME.qcow2"
ORIGINAL_XML="/home/vmcontrol/tmp/original.xml" # We have to create this in /home as /tmp doesn't grant rwx rights for user created files (to be fixed)


# Now that we know that the VM # was declared, we can get down to business.
# First, we should sanity check and make sure that a VM with the same name is not running already.
# The login checks are done on the gateway, so we can assume this request has been verified.

if  sudo virsh list --all | grep $NEW_VM_NAME >/dev/null ; then
	echo "a VM with the same name already exists. Attempting to destroy and undefine it."
	sudo virsh destroy $NEW_VM_NAME > /dev/null && echo "Virtual machine $NEW_VM_NAME destroyed."
	sudo virsh undefine $NEW_VM_NAME > /dev/null && echo "Virtual machine $NEW_VM_NAME undefined."
fi	
# Now, let's make sure there is no VM image that exists. There should not be one.

if [ -e "$NEW_VM_IMG_PATH" ];then
	rm -f "$NEW_VM_IMG_PATH" && echo "Removed old disk image." || exit 1 # if this fails, there's an issue with permissions etc.
fi

# Finally, lets begin creating the new VM.

qemu-img create -f qcow2 -F qcow2 -b "$ORIGINAL_VM_IMG_PATH" "$NEW_VM_IMG_PATH" >/dev/null && echo "Cloned original disk image."

# Okay, so now that we've got a new vm image to boot up, we need to work 
# on the actual xml file in order to change the mac address and the boot up image.
# First, lets load the xml to a tmp file:

sudo virsh dumpxml "$VM_NAME" > "$ORIGINAL_XML"  && echo "Copied original XML."

# Lets generate some of the new information we'll need for the VM XML
NEW_UUID=$(uuidgen)     	# UUID for the machine
NEW_MAC="52:54:00:ca:d8:$1"   	# $1 for the last part as the MACs have been assigned static IPs in DHCP.

# Now we have to edit the file
sed -i "s/<name>.*<\/name>/<name>$NEW_VM_NAME<\/name>/g" $ORIGINAL_XML 
sed -i "s|<uuid>.*</uuid>|<uuid>$NEW_UUID</uuid>|g" $ORIGINAL_XML 
sed -i "s/\(<mac address='\).*\('\/>\)/\1$NEW_MAC\2/g" $ORIGINAL_XML 
sed -i "s/<name>.*<\/name>/<name>$NEW_VM_NAME<\/name>/g" $ORIGINAL_XML 
sed -i "s|$ORIGINAL_VM_IMG_PATH|$NEW_VM_IMG_PATH|g" $ORIGINAL_XML


# Define the new VM
sudo virsh define "$ORIGINAL_XML" >/dev/null &&\
	{ echo "Defined $NEW_VM_NAME.";rm "$ORIGINAL_XML"; } || sudo virsh list --all # || is for debugging. If everything works, this should never trigger.

# Now, lets just start the VM.
sudo virsh start $NEW_VM_NAME > /dev/null && echo "Started $NEW_VM_NAME."
