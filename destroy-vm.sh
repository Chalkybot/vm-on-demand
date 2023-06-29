

# This is the script that's run when a user disconnects from a vm.
if  [ -z "$1" ]; then
    echo "No VM number was declared."
    exit 1
fi


NEW_VM_NAME="deb0$1-vm"
NEW_VM_IMG_PATH="/mnt/vm images/on-demand-images/$NEW_VM_NAME.qcow2"

sudo virsh destroy $NEW_VM_NAME > /dev/null && echo "Virtual machine $NEW_VM_NAME destroyed."
sudo virsh undefine $NEW_VM_NAME > /dev/null && echo "Virtual machine $NEW_VM_NAME undefined."

rm -f "$NEW_VM_IMG_PATH" && echo "Removed old disk image." || exit 1 
echo "Clean up was succesful."