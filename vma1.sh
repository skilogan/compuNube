#!/usr/bin/env bash
echo "***Actualizando e instalando paquetes vagrantVM1"
#apt-get update && apt-get upgrade -y

echo "***Instalando lxd 4.0 vagrantVM1"
snap install lxd --channel=4.0/stable
newgrp lxd

echo "***Inicializando nodo vagrantVM1"
cat > /home/vagrant/preseed.yaml <<EOF
config:
  core.https_address: 192.168.100.21:8443
  core.trust_password: admin
networks:
- config:
    bridge.mode: fan
    fan.underlay_subnet: 192.168.100.0/24
  description: ""
  managed: false
  name: lxdfan0
  type: ""
storage_pools:
- config: {}
  description: ""
  name: local
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdfan0
      type: nic
    root:
      path: /
      pool: local
      type: disk
  name: default
cluster:
  server_name: vma1
  enabled: true
  member_config: []
  cluster_address: ""
  cluster_certificate: ""
  server_address: ""
  cluster_password: ""
EOF

echo "***Envio de preseed vagrantVM1"
cat /home/vagrant/preseed.yaml | lxd init --preseed

echo "***Obtener certificado vagrantVM1"
sudo -i sed ':a;N;$!ba;s/\n/\n\n/g' /var/snap/lxd/common/lxd/server.crt > /home/vagrant/carpetaCompartida/certificado.txt

echo "***Obtener clave certificado vagrantVM1"
sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{/-----BEGIN CERTIFICATE-----\|-----END CERTIFICATE-----/!p;}' /home/vagrant/carpetaCompartida/certificado.txt > /home/vagrant/carpetaCompartida/claveCertificado.txt

echo "***Creando contenerdo haproxy"
lxc launch ubuntu:20.04 haproxy
sleep 10
echo "***Instalando haproxy"
lxc exec haproxy -- apt update && apt upgrade
lxc exec haproxy -- apt-get install haproxy -y
lxc exec haproxy -- systemctl enable haproxy

echo "***Configurando haproxy.cfg"
cat > /home/vagrant/backfront <<A

backend web-backend
        balance roundrobin
        stats enable
        stats auth haproxy:admin
        stats uri /haproxy?stats

        server web1 web1.lxd:80 check
        server web1Backup web1Backup.lxd:80 check backup
        server web2 web2.lxd:80 check        
        server web2Backup web2Backup.lxd:80 check backup
frontend http
        bind *:80
        default_backend web-backend
A

lxc exec haproxy -- cat /etc/haproxy/haproxy.cfg > haproxyInicial.cfg
cat haproxyInicial.cfg backfront > haproxyConfigurado.cfg
lxc file push /home/vagrant/haproxyConfigurado.cfg haproxy/etc/haproxy/haproxy.cfg


echo "***Modificando pagina de error 503"
cat > /home/vagrant/503.http <<A
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<!DOCTYPE html>
<html>
	<body>
	<style>
		body{
			background-color:black;
			color:white;
			text-align: center;
		}

		h1{
			margin:1% 15%;
			text-align: center;
			border-bottom:solid;
			border-top:solid;
			border-top-color:red;
			color:red;
		}
	</style>
		<h1>SERVIDORES NO DISPONIBLES</h1>
		<img id ="img1" src="https://em.wattpad.com/b033cb1a0e098bb53edfb9d221d54d2be9524bb1/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f776174747061642d6d656469612d736572766963652f53746f7279496d6167652f637143385178757a33794b5344673d3d2d3731303539393833312e313538656338316438313632636462613835333737333036343135352e676966?s=fit&w=720&h=720" width="20%" alt="CompuNube">
	</body>
</html>
A

lxc file push /home/vagrant/503.http haproxy/etc/haproxy/errors/503.http
lxc restart haproxy

echo "***Configurando redireccionamiento de puerto 1025"
lxc config device add haproxy myport1025 proxy listen=tcp:192.168.100.21:1025 connect=tcp:127.0.0.1:80
