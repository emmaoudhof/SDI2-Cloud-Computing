#!/bin/bash

echo "Hoeveel vms wil je aanmaken?:"
read vm_aantal
echo "Wat is het startnummer voor de server ID?:"
read id_startnummer
echo "Wat is de naam die als basis voor de servers moet worden gebruikt?:"
read vm_naam
echo "Wat is het laatste deel van de IP-adressen van de vm?:"
read ip_eind
echo "Wat is de node waar de vm's moeten komen?"
read plek_node

source_vm_id=121
ip_oud="10.24.13.121" 
source_node="vm1130"

# SSH sleutels opslaan in deze directory
sshkey_padopslag="~/ssh_keys/ssh_keyvm"  
nodes_cluster=("vm1130" "vm1131" "vm1132") 

# Loop om het opgegeven aantal VM's aan te maken
for ((i=0; i<vm_aantal; i++)); do
    vmid_nieuw=$((id_startnummer + i))
    ip_nieuw="10.24.13.$((ip_eind + i))"
    naam_nieuw="${vm_naam}${vmid_nieuw}"

    echo "Klonen vm id: ${source_vm_id} (template) van ${source_node} naar ${plek_node}. Hij heet: ${naam_nieuw} en het ip is: ${ip_nieuw}"
    qm clone ${source_vm_id} ${vmid_nieuw} --name ${naam_nieuw} --full --target ${plek_node}
    qm start ${vmid_nieuw}
    
    echo "Even wachteeennnnnn, vm ${vmid_nieuw} start nu op......"
    sleep 200

    # Connect met de gekloonde VM en pas settings aan
    echo "Connecten naar de gekloonde vm met (${ip_oud}) met gebruiker emma en deze ssh key: ${sshkey_padopslag}"

    # netplan en gebruiker info
    echo "Het nieuwe ip is: ${ip_nieuw} in /etc/netplan/50-cloud-init.yaml"
    ssh -i ${sshkey_padopslag} emma@${ip_oud} "sudo sed -i 's/  - 10.24.13\.[0-9]\{1,3\}\/24/  - ${ip_nieuw}\/24/' /etc/netplan/50-cloud-init.yaml"
    echo "De nieuwe naam is: ${naam_nieuw}"
    ssh -i ${sshkey_padopslag} emma@${ip_oud} "sudo hostnamectl set-hostname ${naam_nieuw}"
    ssh -i ${sshkey_padopslag} emma@${ip_oud} "sudo sed -i 's/127.0.1.1.*/127.0.1.1 ${naam_nieuw}/' /etc/hosts"
    ssh -i ${sshkey_padopslag} emma@${ip_oud} "echo '${naam_nieuw}' | sudo tee /etc/hostname"
    # Git-repository klonen
    qm reset ${vmid_nieuw}
    sleep 200

    echo "Klonen van eigen git"
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} "git clone https://github.com/emmaoudhof/SDI2-Cloud-Computing.git"
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} "cd SDI2-Cloud-Computing/ansible"
    
    # Voer Ansible-playbooks uit
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} "cd SDI2-Cloud-Computing/ansible && sudo ansible-playbook -i localhost, docker_install_playbook.yml"
   
   
    echo "Alles is gelukt nu weer even wachhhtteeennn"
    sleep 200
done
