#!/bin/bash
# Variabelen
# Test kijken of github update???
id=100
arch_type=amd64
os_type=ubuntu               # OSType 
hostname=container1          # Hostname
cores=1                      # Aantal CPU cores 
memory=1024                  # RAM 
swap=512                     # Swap 
storage=poolemma             # Ceph pool 'poolemma' als gedeelde opslag
password='emmaoudhof'        # Wachtwoord aangepast
net0_name=e1000
bridge=vmbr0
gw=10.24.13.1                # Gateway
ip=10.24.13.10/24            # IP-adres 
type=veth
start_wait_time=10

# Container aanmaken
pct create $id /var/lib/vz/template/cache/ubuntu-24.04-standard_24.04-2_amd64.tar.zst \
 -arch $arch_type \
 -ostype $os_type \
 -hostname $hostname \
 -cores $cores \
 -memory $memory \
 -swap $swap \
 -storage $storage \
 -password $password \
 -net0 name=$net0_name,bridge=$bridge,gw=$gw,ip=$ip,type=$type

# Container starten en wachten
if pct start $id; then
  echo "Container $id succesvol gestart. Wacht $start_wait_time seconden."
  sleep $start_wait_time
else
  echo "Fout bij het starten van container $id"
  exit 1
fi

