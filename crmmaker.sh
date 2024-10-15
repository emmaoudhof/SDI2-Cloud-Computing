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
echo "Wat het IP-adres van de monitoring server:"
read monitor_ip

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
    
    # Zabbix repository toevoegen en de agent installeren
    echo "Zabbix repository toevoegen en de agent installeren op VM ${vmid_nieuw}"
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} << EOF
    echo "deb https://repo.zabbix.com/zabbix/7.0/ubuntu \$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/zabbix.list
    wget https://repo.zabbix.com/zabbix-official-repo.key
    sudo apt-key add zabbix-official-repo.key
    sudo apt-get update
    sudo apt-get install zabbix-agent -y
EOF

    # Zabbix-agent configureren
    echo "Zabbix-agent configureren voor VM ${vmid_nieuw}"
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} << EOF
    sudo sed -i 's/^Server=.*/Server=${monitor_ip}/' /etc/zabbix/zabbix_agentd.conf
    sudo sed -i 's/^ServerActive=.*/ServerActive=${monitor_ip}/' /etc/zabbix/zabbix_agentd.conf
    sudo sed -i 's/^Hostname=.*/Hostname=${naam_nieuw}/' /etc/zabbix/zabbix_agentd.conf
    sudo systemctl restart zabbix-agent
    sudo systemctl enable zabbix-agent
EOF

    # Voer Ansible-playbooks uit
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} "cd SDI2-Cloud-Computing/ansible && sudo ansible-playbook -i localhost, crmplaybook.yml"
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} "cd SDI2-Cloud-Computing/ansible && sudo ansible-playbook -i localhost, firewallplaybook.yml"
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} "cd SDI2-Cloud-Computing/ansible && sudo ansible-playbook -i localhost, zabbixplaybookagent.yml --extra-vars 'zabbix_server_ip=${monitor_ip} host_metadata=crm'"

    echo "Alles is gelukt nu weer even wachhhtteeennn"
    sleep 200

    # Nieuwe gebruiker aanmaken en SSH-sleutel genereren
    gebruiker_nieuw="user_${naam_nieuw}"
    sshkey_padopslag_nieuw="~/.ssh/sshkey_${naam_nieuw}"

    mkdir -p ~/.ssh  # Maak zeker dat de map bestaat
    ssh-keygen -t rsa -b 2048 -f ${sshkey_padopslag_nieuw} -N "" -C "${naam_nieuw}"
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} "echo '$(cat ${sshkey_padopslag_nieuw}.pub)' | sudo tee /home/${gebruiker_nieuw}/.ssh/authorized_keys"
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} "sudo chmod 600 /home/${gebruiker_nieuw}/.ssh/authorized_keys"
    ssh -i ${sshkey_padopslag} emma@${ip_nieuw} "sudo chown -R ${gebruiker_nieuw}:${gebruiker_nieuw} /home/${gebruiker_nieuw}/.ssh"
    
    # ssh andere nodes
    echo "Distributing the new SSH key for user ${gebruiker_nieuw} to other nodes in the cluster..."
    for node in "${cluster_nodes[@]}"; do
        scp "${sshkey_padopslag_nieuw}" root@${node}:/home/${gebruiker_nieuw}/.ssh/
        scp "${sshkey_padopslag_nieuw}.pub" root@${node}:/home/${gebruiker_nieuw}/.ssh/
    done

   
