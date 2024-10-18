#!/bin/bash

# Kijken of de swarm al ergens is in een node
if docker info | grep -q "Swarm: active"; then
    echo "Deze node zit al in een swarm, nu wordt die verlaten."
    sudo docker swarm leave --force

    if [ $? -eq 0 ]; then
        echo "Goed de swarm verlaten!"
    else
        echo "Er is iets niet goed gegaan."
        exit 1
    fi
else
    echo "Deze node maakt geen deel uit van een swarm. Verdergaan met het initialiseren van een nieuwe swarm."
fi

# Ip
ip_address=$(hostname -I | awk '{print $1}')
echo "Initialiseren docker swarm op $ip_address..."

# Manager
sudo docker swarm init --advertise-addr $ip_address

# Controle
if [ $? -eq 0 ]; then
    echo "Succes op $ip_address. Deze vm is nu de manager."
else
    echo "Er is iets fout gegaan ."
    exit 1
fi

# Status
sudo docker node ls

# Service
echo "helloworld..."
sudo docker service create --name HelloWorld alpine ping docker.com

# Status service
echo "Luisteren naar docker serivces"
sudo docker service ls

echo "Swarm geslaagd op $ip_address!"
