#!/bin/bash


# For debugging, we want to list as much information as possible
# Firstly, we want to load the current reserved IPs and clientids:
case "$1" in 
        "--info")
            # Retrieve network information and list of virtual machines
            net_info=$(sudo virsh net-dhcp-leases default)
            vms=$(sudo virsh list --all)

            # Display table header
            printf "%-20s %-11s %-11s %-16s %s\n" "Name" "State" "Hostname" "IP" "mac"
            echo "-------------------------------------------------------------------------------"


            # Iterate over each virtual machine and extract relevant information
            for VM in $( echo "$vms" | grep --color=None -oP '^\s*(\d+|-)\s+\K([a-zA-Z0-9-\s]+)(?=\s+running|\s+shut off)');do 
		    vm_mac=$(sudo virsh domiflist $VM|grep --color=None -Eo "([a-zA-Z0-9]{2}:?){4,8}$" )
                vm_ips=$(echo "$net_info" |grep "$vm_mac" |grep -Eo "[0-9.]{12,99}"|head -n 1)
                vm_hostname=$(echo "$net_info" |grep $vm_mac|grep -Eo "\/[0-9]{1,2}\s+[a-zA-Z0-9-]*"|grep -Eo "[a-zA-Z0-9-]*$"|head -n 1)
                vm_status=$(sudo virsh domstate $VM )
                
                # Print formatted information for each virtual machine
                printf "%-20s %-11s %-11s %-16s %s\n" "$VM" "$vm_status" "$vm_hostname" "$vm_ips" "$vm_mac"
            done
        ;;

        "--restart")
            # Restart all running virtual machines
            for i in $(sudo virsh list --name --state-running)
                do sudo virsh reboot "$i">/dev/null && echo "Virtual machine $i is being rebooted" || echo "Failure rebooting $1"
            done
        ;;
        "--down")
            echo "Every VM will be shut down gracefully."
            read -r -p "Are you sure? [y/N] " response
            case "$response" in
                [yY][eE][sS]|[yY]) 
                # Gracefully shut down all running virtual machines by iterating through them
                for i in $(sudo virsh list --name --state-running)
                    do sudo virsh shutdown "$i">/dev/null && echo "Virtual machine $i has been shutdown." || echo "Failure shutting down $1"
                done
                    ;;
                *)
                    exit 0
                ;;
            esac
        ;;
        "--up")
            echo "Every VM will be turned on."
            read -r -p "Are you sure? [y/N] " response
            case "$response" in
                [yY][eE][sS]|[yY]) 
                for i in $(sudo virsh list --name --state-shutoff)
                    do sudo virsh start "$i">/dev/null && echo "Virtual machine $i has been started." || echo "Failure starting $1"
                done
                    ;;
                *)
                    exit 0
                ;;
            esac
        ;;

        "--net-refresh")
            list_of_vms=$(sudo virsh list --name --state-running)
            
            echo "Machines currently up: 
$list_of_vms"
            echo "Machines will be restarted."
            read -r -p "Continue refreshing network? [y/N] " response
            case "$response" in
                # Restart all running virtual machines and refresh network
                [yY][eE][sS]|[yY]) 
                    for i in $(echo $list_of_vms)
                        do sudo virsh shutdown "$i">/dev/null && echo "Virtual machine $i has been shutdown." || echo "Failure shutting down $1"
                    done
                    sudo virsh net-destroy default && echo "Network turned off succesfully"
                    sudo virsh net-start default && echo "Network up"
                    for i in $(echo $list_of_vms)
                        do sudo virsh start "$i">/dev/null && echo "Virtual machine $i has been brought back up." || echo "Failure starting $1"
                    done
                    ;;
                *)
                    exit 0
                    ;;
            esac
        ;;

        "--purge")
            list_of_vms=$(sudo virsh list --all --name|grep --color=None -E "[a-zA-Z]{3}[0-9]{2}\-vm")
            echo -e "The following machines will be purged: 
$list_of_vms"
            read -r -p "Are you sure? [y/N] " response

            case "$response" in
                [yY][eE][sS]|[yY]) 
                    for i in $(echo $list_of_vms)
                        do sudo virsh destroy "$i" >/dev/null 
                           sudo virsh undefine "$i"
                           rm -f "/mnt/vm images/on-demand-images/$1.qcow2"
                    done
                    ;;
                *)
                    exit 0
                    ;;
            esac
        ;;

        # General usage
        *)
    echo "This script provides operations for managing virtual machines using the 'virsh' command.
 Usage: debug.sh [OPTION]

 Options:
   --info         Display information about running virtual machines.
   --restart      Restart all running virtual machines.
   --down         Gracefully shut down all running virtual machines.
   --up           Starts every VM in the swarm.
   --net-refresh  Refresh the network by restarting all running virtual machines and restarting the network DHCP controller.
   --purge        Purge (remove) temporary virtual machines.
"       ;;
        esac
