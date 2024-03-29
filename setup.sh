#!/bin/bash

# Docker install
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    curl \
    lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker post-install
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker
docker network create traefik

# Create directories
## filebrowser
mkdir -p filebrowser/database
touch filebrowser/database/filebrowser.db
## traeafik
mkdir -p traefik/letsencrypt
touch traefik/letsencrypt/acme.json
chmod 600 traefik/letsencrypt/acme.json
## jellyfin shared folders 
mkdir -p shared/movies
mkdir -p shared/tvseries

# Disable systemd-resolved caching DNS stub resolver.
# Reference: https://github.com/pi-hole/docker-pi-hole#installing-on-ubuntu
sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf'
systemctl restart systemd-resolved

# Start all services
declare -a services=("traefik" "heimdall" "jellyfin" "nextcloud" "transmission" "filebrowser" "pihole")

for service in "${services[@]}"
do
  cd "$service"
  docker compose up -d
  cd .. 
done
