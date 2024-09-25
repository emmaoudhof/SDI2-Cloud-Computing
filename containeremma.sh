#!/bin/bash
# Variabelen
id=100
arch_type=amd64
os_type=ubuntu               # OSType 
hostname=containeremma       # Hostname
cores=1                      # Aantal CPU cores 
memory=1024                  # RAM 
swap=512                     # Swap 
storage="poolemma"           # Ceph pool 'poolemma' als gedeelde opslag
password="emmaoudhof"        # Wachtwoord aangepast
net0_name="eth0"
bridge="vmbr0"
gw="10.24.13.1"                # Gateway
ip="10.24.13.100/24"            # IP-adres
dns="8.8.8.8"                  # DNS
type="veth"
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
 -net0 name=$net0_name,bridge=$bridge,gw=$gw,ip=$ip,type=$type \

# Container starten en wachten
if pct start $id; then
  echo "Container $id succesvol gestart. Wacht $start_wait_time seconden."
  sleep $start_wait_time
  pct exec $id -- ip link set $net0_name up
  pct exec $id -- ip addr add $ip dev $net0_name
  pct exec $id -- bash -c "echo 'nameserver $dns' > /etc/resolv.conf"
  pct exec $id -- ip route add default via $gw
else
  echo "Fout bij het starten van container $id"
  exit 1
fi
