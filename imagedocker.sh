#!/bin/bash

# Directory aanmaken voor de Dockerfile
mkdir -p ~/simplidocker
cd ~/simplidocker

# Schrijven van de dockerfile
cat <<EOF > Dockerfile
FROM ubuntu:24.04
MAINTAINER simplilearn
RUN apt-get update && apt-get install -y curl vim
CMD ["echo", "Welcome to Simplilearn"]
EOF

# Docker image 
echo "Docker image aan het maken"
docker build -t simplilearn_image .

# Aanmaken container docker en het starten ervan 
echo "Container met docker is in de maak..."
docker run --name simplilearn_container simplilearn_image

echo "Docker container is nu aan het lopen"
