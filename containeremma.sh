#!/bin/bash
# Aanmaken van x containers
echo "Hoeveel containers wil je aanmaken?:"
read container_aantal
echo "Wat is het startnummer voor de server ID?:"
read id_startnummer
echo "Wat is de naam die als basis voor de servers moet worden gebruikt?:"
read server_naam
echo "Wat is het laatste deel van de IP-adressen van de containers?:"
read ip_eind

# Variabelen voor containerscript
arch_type=amd64
os_type=ubuntu               # OSType
cores=1                      # Aantal CPU cores
memory=1024                  # RAM
swap=512                     # Swap
storage="poolemma"           # Ceph pool 'poolemma' als gedeelde opslag
password="emmaoudhof"        # Wachtwoord aangepast
bridge="vmbr0"
gw="10.24.13.1"              # Gateway
dns="8.8.8.8"                # DNS
start_wait_time=10
rate=50000                   # Snelheid netwerk

# Een loop om de x aantal containers te maken die is aangevraagd
for ((i=0; i<container_aantal; i++)); do
    id=$((id_startnummer + i))
    ip="10.24.13.$((ip_eind + i))/24"
    hostname="${server_naam}${i}"
    net0_name="eth$id"

    # Container al aanwezig!
    if pct status $id &> /dev/null; then
        echo "Container $id is aanwezig, deze wordt niet aangemaakt."
        continue
    fi

    echo "De container $id wordt nu aangemaakt. Het bijbehoorende IP is $ip en de hostname is $hostname"

    # Container(s) aanmaken
    pct create $id /var/lib/vz/template/cache/ubuntu-24.04-standard_24.04-2_amd64.tar.zst \
      -arch $arch_type \
      -ostype $os_type \
      -hostname $hostname \
      -cores $cores \
      -memory $memory \
      -swap $swap \
      -storage $storage \
      -password $password \
      -net0 name=$net0_name,bridge=$bridge,gw=$gw,ip=$ip,rate=$rate \
      && echo "De container $id is aangemaakt."

    # Container starten en wachten
    if pct start $id; then
        echo "Container $id succesvol gestart. Wacht $start_wait_time seconden."
        sleep $start_wait_time
        pct exec $id -- ip link set $net0_name up
        pct exec $id -- ip addr add $ip dev $net0_name
        pct exec $id -- bash -c "echo 'nameserver $dns' > /etc/resolv.conf"
        pct exec $id -- ip route add default via $gw

        # Update pakketlijsten van de package manager binnen de container
        pct exec $id -- apt-get update

        # Installeer het 'locales' pakket om taalinstellingen (locales) te kunnen configureren
        pct exec $id -- apt-get install -y locales

        # Genereer de 'en_US.UTF-8' locale voor de container (nodig voor taalondersteuning)
        pct exec $id -- locale-gen en_US.UTF-8

        # Stel 'en_US.UTF-8' in als de standaardtaal (locale) binnen de container
        pct exec $id -- update-localess LANG=en_US.UTF-8

        # Installeer OpenSSH-server, sudo en Git binnen de container
        pct exec $id -- apt-get install -y openssh-server sudo git

        # Schakel de SSH-service in zodat deze automatisch start bij het opstarten van de container
        pct exec $id -- systemctl enable ssh

        # Start de SSH-service zodat SSH-toegang direct mogelijk is
        pct exec $id -- systemctl start ssh

        # Schakel 'nesting' in voor de container, zodat je in de container andere containers kunt draaien (LXC in LXC)
        pct set $id --features nesting=1
        pct exec $id -- apt-get install -y software-properties-common
        pct exec $id -- apt-add-repository --yes --update ppa:ansible/ansible
        pct exec $id -- apt-get install -y ansible
        pct exec $id -- git clone https://github.com/emmaoudhof/SDI2-Cloud-Computing.git /SDI2-Cloud-Computing
        pct exec $id -- ansible-playbook -i localhost, /SDI2-Cloud-Computing/ansible/playbookwordpress.yml
        pct exec $id -- systemctl daemon-reload
        pct exec $id -- systemctl restart apache2
    else
        echo "Fout bij het starten van container $id"
        exit 1
    fi
done
