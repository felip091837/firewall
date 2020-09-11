#!/bin/bash

#Atribuir IP
sudo cat <<EOT > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: yes
    enp0s8:
      dhcp4: no
      addresses: [10.0.0.1/24]
EOT

sudo netplan apply


#configurar servidor DNS
sudo apt install isc-dhcp-server
sudo cat <<EOT > /etc/dhcp/dhcpd.conf
ddns-update-style none;

default-lease-time 600;
max-lease-time 7200;

authoritative;

subnet 10.0.0.0 netmask 255.255.255.0 {
   range 10.0.0.10 10.0.0.50;
   option broadcast-address 10.0.0.255;
   option routers 10.0.0.1;
   option domain-name-servers 8.8.8.8;
}
EOT

sudo cat <<EOT > /etc/default/isc-dhcp-server
INTERFACESv4="enp0s8"
INTERFACESv6=""
EOT


#configurar roteamento
sudo bash -c 'echo "1" > /proc/sys/net/ipv4/ip_forward'

#definir regra de roteamento
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o enp0s3 -j MASQUERADE


#REGRAS CLIENTE
#Definir política de DROP 
sudo iptables -t filter -P FORWARD DROP

#permitir respostas das conexões estabelecidas oriundas das regras de permitir tráfego
sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

#Liberar trafego
sudo iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
sudo iptables -A FORWARD -p tcp --dport ssh -j ACCEPT
sudo iptables -A FORWARD -p udp --dport 53 -j ACCEPT
sudo iptables -A FORWARD -p icmp -j ACCEPT
sudo iptables -A FORWARD -p tcp -m string --string "youtube.com" --algo kmp -j DROP
sudo iptables -A FORWARD -p tcp --dport 21 -j ACCEPT



#REGRAS FIREWALL
#Definir política de DROP
sudo iptables -t filter -P INPUT DROP

#permitir respostas das conexões estabelecidas oriundas das regras de permitir tráfego
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#Liberar SSH
sudo iptables -A INPUT -p tcp --dport ssh -j ACCEPT
