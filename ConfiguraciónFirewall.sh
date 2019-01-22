#!/bin/sh 
# Script cortafuegos.sh para la configuración de iptables 
# 
# Primero borramos todas las reglas previas que puedan existir
 iptables -F 

 
# Después definimos que la politica por defecto sea ACEPTAR 
iptables -P INPUT ACCEPT 
iptables -P OUTPUT ACCEPT 
iptables -P FORWARD ACCEPT
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT 
 
# Para evitar errores en el sistema, debemos aceptar
# todas las comunicaciones por la interfaz lo (localhost) 
iptables -A INPUT -i lo -j ACCEPT 
 
 # Aceptar loopback input
iptables -A INPUT -i lo -p all -j ACCEPT

#Permitir Handshake de tres vias&lt;
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
 
# Aceptamos SMTP, POP3 y FTP (correo electrónico y ftp) 
iptables -A FORWARD -s 10.0.0.0/8 -p tcp --dport 25 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -p tcp --dport 110 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -p tcp --dport 20 -j ACCEPT 
iptables -A FORWARD -s 10.0.0.0/8 -p tcp --dport 21 -j ACCEPT 

#Detener Ataques Enmascarados;
iptables -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j DROP
iptables -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j DROP
iptables -A INPUT -p icmp -m icmp -m limit --limit 1/second -j ACCEPT
 
#Descartar Paquetes Inválidos
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP
iptables -A OUTPUT -m state --state INVALID -j DROP
 
 #Descartar paquetes RST Excesivos para Evitar Ataques Enmascarados
iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT
 
#Cualquier IP que intente un Escaneo de Puertos sera Bloqueada por 24 Horas.
iptables -A INPUT -m recent --name portscan --rcheck --seconds 86400 -j DROP
iptables -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP
 
#Pasadas las 24 Horas, remover la IP Bloqueada por Escaneo de Puertos
iptables -A INPUT -m recent --name portscan --remove
iptables -A FORWARD -m recent --name portscan --remove
 
#Esta Regla agrega el Escaner de Puertos a la Lista de PortScan y Registra el Evento.
iptables -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"
iptables -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP
 
iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"
iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP
 
 #Permitir estos puertos desde Fuera
# smtp
iptables -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT
# http
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
# https
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
# ssh &amp; sftp
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
 
 #Permitir el Ping
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
 
#OUTPUT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#Descartar cualquier otra Salida
iptables -A OUTPUT -j REJECT
 
#No Permitir Forward
iptables -A FORWARD -j REJECT

#Descartar cualquier otra Entrada
iptables -A INPUT -j REJECT
# Hacemos NAT si IP origen 10.0.0.0/8 y salen por eth0
 iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o eth0 -j MASQUERADE  
 
# Activamos el enrutamiento
echo 1 > /proc/sys/net/ipv4/ip_forward 
 
# Comprobamos cómo quedan las reglas 
iptables -L –n 
 
