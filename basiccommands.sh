#!/bin/bash

# Basic Docker Networking Commands

echo "Alle docker netwerken die draaien:"
sudo docker network ls
echo ""

echo "Alle docker containers:"
sudo docker container ps -a
echo ""

# Controle containernaam 
function check_container_exists() {
    sudo docker ps -a --format "{{.Names}}" | grep -q "^$1$"
}

# Wat is de containernaam 
while true; do
    echo "Welke container moet worden verbonden?:"
    read container_naam

    # Bestaat de container al?
    if check_container_exists "$container_naam"; then
        echo "Container ${container_naam} gevonden."
        break
    else
        echo "Deze container bestaat niet: ${container_naam}."
    fi
done

# Bestaat netwerk al?
network_naam="multi-host-network"
if ! docker network ls --format "{{.Name}}" | grep -q "^${network_naam}$"; then
    echo "Netwerk ${network_naam} bestaat niet. Er wordt nu een netwerk aangemaakt."
    
    
    sudo docker network create --subnet=10.24.14.0/24 ${network_naam}
    echo "Netwerk ${network_naam} is aangemaakt met subnet 10.24.14.0/24."
else
    echo "Netwerk ${network_naam} bestaat al."
fi

# Als container al verbonden is maak hem los
if sudo docker inspect "$container_naam" | grep -q "\"$network_naam\""; then
    echo "Deze container is al verbonden met ${network_naam}."
    sudo docker network disconnect ${network_naam} $container_naam
fi


# Vraag naar laatste octet
echo "Voer het laatste octet (X) in van IP-adres (10.24.13.X):"
read ip_eind
nieuw_ip="10.24.13.$ip_eind"

# Alias container
echo "Wat is de alias naam?"
read alias

# Container wordt verbonden met alias
echo "De container wordt verbonden:"
sudo docker network connect --ip ${ip_nieuw} --alias ${alias} ${network_naam} $container_naam
echo "Container IP ${ip_nieuw} en alias ${alias} is nu verbonden."
echo ""

echo "Alles is gelukt!!!"
