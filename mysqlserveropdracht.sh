#!/bin/bash
# Create networks
docker network create --subnet=192.168.20.0/24 mysql-network1
docker network create --subnet=192.168.30.0/24 mysql-network2

# Run the MySQL containers in their respective subnets
docker run -d --name mysql-server1 --network=mysql-network1 --ip=192.168.20.7 -e MYSQL_ROOT_PASSWORD=root mariadb
docker run -d --name mysql-server2 --network=mysql-network2 --ip=192.168.30.7 -e MYSQL_ROOT_PASSWORD=root mariadb

# Cross-Subnet communication (DOCKER-USER is made by Docker)
# Allow VM subnet to Docker subnets
sudo iptables -A FORWARD -s 10.24.13.0/24 -d 192.168.20.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 10.24.13.0/24 -d 192.168.30.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.20.0/24 -d 10.24.13.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.30.0/24 -d 10.24.13.0/24 -j ACCEPT

# Allow communication between the two MySQL subnets
sudo iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.30.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.30.0/24 -d 192.168.20.0/24 -j ACCEPT

# General acceptance rules for communication within MySQL subnets
sudo iptables -A FORWARD -s 192.168.20.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.30.0/24 -j ACCEPT
sudo iptables -A FORWARD -d 192.168.20.0/24 -j ACCEPT
sudo iptables -A FORWARD -d 192.168.30.0/24 -j ACCEPT

echo "MySQL-servers zijn succesvol aangemaakt en geconfigureerd voor communicatie tussen subnets."
