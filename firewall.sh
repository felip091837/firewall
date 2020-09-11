#!/bin/bash

#Atribuir IP
cat <<EOT > /etc/netplan/01-netcfg.yaml
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
cat <<EOT > /etc/netplan/01-netcfg.yaml
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

cat <<EOT > /etc/default/isc-dhcp-server
INTERFACESv4="enp0s8"
INTERFACESv6=""
EOT


#configurar roteamento
sudo bash -c 'echo "1" > /proc/sys/net/ipv4/ip_forward'

#definir regra de roteamento
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o enp0s3 -j MASQUERADE



#REGRAS CLIENTE
#Definir política de DROP 
iptables -t filter -P FORWARD DROP

#permitir respostas das conexões estabelecidas oriundas das regras de permitir tráfego
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

#Liberar trafego
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp --dport ssh -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p icmp -j ACCEPT
iptables -A FORWARD -p tcp -m string --string "youtube.com" --algo kmp -j DROP
iptables -A FORWARD -p tcp --dport 21 -j ACCEPT



#REGRAS FIREWALL
#Definir política de DROP
iptables -t filter -P INPUT DROP

#permitir respostas das conexões estabelecidas oriundas das regras de permitir tráfego
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#Liberar SSH
iptables -A INPUT -p tcp --dport ssh -j ACCEPT
