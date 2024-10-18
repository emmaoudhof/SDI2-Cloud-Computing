#!/bin/bash

# Download Docker compose
echo "Instaleren docker compose"
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Docker runnen
sudo chmod +x /usr/local/bin/docker-compose

# Versie Docker
docker-compose --version

echo "Docker Compose is geinstalleerd!"
