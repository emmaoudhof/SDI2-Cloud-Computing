#!/bin/bash

echo "Hoeveel vms wil je aanmaken?:"
read vm_aantal
echo "Wat is het startnummer voor de server ID?:"
read id_startnummer
echo "Wat is de naam die als basis voor de servers moet worden gebruikt?:"
read vm_naam
echo "Wat is het laatste deel van de IP-adressen van de vm?:"
read ip_eind


# Basisinstellingen
cores=2
memory=2048
disk_size="50G"  
storage="poolemma"  
bridge="vmbr0"
gw="10.24.13.1"
dns="8.8.8.8"
start_wait_time=20
iso_file="/var/lib/vz/template/iso/ubuntu-24.04.1-live-server-amd64.iso"  
key_dir="/root/vm_keys"

# Maak de map aan om sleutels op te slaan als die niet bestaat
mkdir -p $key_dir

# Loop om het opgegeven aantal VMs aan te maken
for ((i=0; i<vm_aantal; i++)); do
    id=$((vmid + i))
    ip="10.24.36.$((last_octet + i))/24"
    hostname="${vm_naam}${i}"

    # Controleer of de VM al bestaat
    if qm status $id &> /dev/null; then
        echo "VM met ID $id bestaat al. Sla over."
        continue
    fi

    echo "VM $id wordt aangemaakt met IP $ip en hostname $hostname"

    qm create $id \
      --name $hostname \
      --memory $memory \
      --cores $cores \
      --net0 virtio,bridge=$bridge \
      --scsihw virtio-scsi-pci \
      --boot c \
      --bootdisk scsi0 \
      --ostype l26

    # Installatie cd, schijf en ip
    qm set $id --cdrom $iso_file
    rbd create ${storage}/vm-${id}-disk-0 --size ${disk_size}
    qm set $id --scsi0 ${storage}:vm-${id}-disk-0
    qm set $id --ipconfig0 ip=$ip,gw=$gw

    # Start de VM
    qm start $id && echo "VM $id is gestart."

    echo "Wachten op het opstarten van de VM..."
    sleep $start_wait_time

done
