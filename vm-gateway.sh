#!/bin/bash

# Firstly, we have to check a few things about the situation
# i.e, first, which port did the user connect to?
# Firstly, and this is important, we need to make sure that
# the $SSH_CLIENT variable is set, if it is not, immediately
# terminate the connection if it is not set.
# we assume that this is a zero trust environment, the user
# will have access to execute this file, but not read it.

if [ -z "$SSH_CLIENT" ]; then # Exit if te SSH_CLIENT has not been set.
	exit
fi


PORT="${SSH_CLIENT##* }"
if [ "$PORT" -gt "35" ] || [ "$PORT" -lt "31" ] ; then
   source exit # If the given port range is greater
                    # or smaller than 30-35 (the allocated port range for SSH connections)
                    # We assume the user is malicious and terminate the connection.
fi # past this point, we assume the user is genuinely attempting to connect.
# Because the numbers start at 31 and end up 35 but the actual VM numbers are 1-5 & IPs are 10-15
# We must declare two different variables, firstly, the VM number, secondly, the IP.

VM_NUMBER=$(($PORT-30))
VM_SUFFIX=$(($PORT-20))
VM_IP="192.168.122.$VM_SUFFIX"
VM_HOST="192.168.122.1"

echo "Designated VM number: $VM_NUMBER"
echo "IP: $VM_IP"
echo "Checking if the host is up..."

if ping -c 1 -W 0.5 $VM_IP>/dev/null ;then
   # If it is alive, we can just pipe this session to the host after setting the hostname.
   # So, let's do that now.
   echo "Host is up, setting up host settings..."
   ssh -i /home/vm/.ssh/id_rsa "root@$VM_IP" "hostnamectl set-hostname deb0$VM_NUMBER-vm"
   ssh -i /home/vm/.ssh/id_rsa "root@$VM_IP"
   source exit
else
   # Okay, so the host is NOT up. Lets create the host.
   echo "Host is not up. Setting up"
   ssh -i /home/vm/.ssh/id_rsa "vmcontrol@$VM_HOST" "exec /home/vmcontrol/vm-on-demand/create-new-vm.sh $VM_NUMBER"

   echo "VM created"
   sleep 2
   echo "Attempting to connect..."
   for i in {1..5}; do
      if ping -c 1 -W 2 $VM_IP>/dev/null ; then
         break
      fi
      sleep 2
   done
      # Now that the VM is running (NB! this is not yet guaranteed as we do not have an "exit" state defined
      # We should ssh to the actual VM and then change the hostnamee.
      ssh -i /home/vm/.ssh/id_rsa "root@$VM_IP" "hostnamectl set-hostname deb0$VM_NUMBER-vm"
      ssh -i /home/vm/.ssh/id_rsa "root@$VM_IP"
      # Once the user exits this part, everything should be done. Let's clean up:
      ssh -i /home/vm/.ssh/id_rsa "vmcontrol@$VM_HOST" "exec /home/vmcontrol/vm-on-demand/destroy-vm.sh $VM_NUMBER"

fi
