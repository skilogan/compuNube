#!/usr/bin/env bash

echo "***Actualizando e instalando paquetes vagrantVM2"
apt-get update && apt-get upgrade

echo "***Instalando lxd 4.0 vagrantVM2"
snap install lxd --channel=4.0/stable
newgrp lxd

echo "***Crear preseed vagrantVM2"
cat > /home/vagrant/preseed.yaml <<EOF
config:
  core.https_address: 192.168.100.22:8443
networks:
- config:
    bridge.mode: fan
    fan.underlay_subnet: 192.168.100.0/24
  description: ""
  managed: true
  name: lxdfan0
  type: bridge
profiles:
- config: {}
  description: ""
  devices: {}
  name: default
cluster:
  server_name: vma2
  enabled: true
  member_config: []
  cluster_address: 192.168.100.21:8443

  cluster_certificate: "-----BEGIN CERTIFICATE-----
  -----END CERTIFICATE-----"
  server_address: "192.168.100.22:8443"
  cluster_password: admin
EOF

echo "***Obtener certificado vagrantVM2"
sed '22r /home/vagrant/carpetaCompartida/claveCertificado.txt' /home/vagrant/preseed.yaml > /home/vagrant/preseedCertificado.yaml

echo "***Envio de preseed vagrantVM2"
cat /home/vagrant/preseedCertificado.yaml | lxd init --preseed



echo "***Creando contenerdo web1"
sleep 10
lxc launch ubuntu:20.04 web1 --target vma2
sleep 10
echo "***Instalando apache2 en web1"
lxc exec web1 -- apt update && apt upgrade
lxc exec web1 -- apt-get install apache2 -y
lxc exec web1 -- systemctl enable apache2

echo "***Creando index web1"
cat > /home/vagrant/index.html <<INDEX
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
			border-top-color:orange;
			color:orange;
		}
	</style>
		<h1>COMPUTACION EN LA NUBE - WEB1</h1>
		<img id ="img1" src="https://image.freepik.com/foto-gratis/concepto-computacion-nube-conectese-nube-empresario-o-tecnologo-informacion-icono-computacion-nube_99433-519.jpg" width="20%" alt="CompuNube">
	</body>
</html>
INDEX

echo "***Enviando index al contenedor web1"
lxc file push /home/vagrant/index.html web1/var/www/html/index.html

echo "***Iniciando apache2 en web1"
lxc exec web1 -- systemctl start apache2
lxc exec web1 -- systemctl restart apache2



echo "***Creando contenerdo web2Backup"
lxc launch ubuntu:20.04 web2Backup --target vma2
sleep 10
echo "***Instalando apache2 en web2Backup"
lxc exec web2Backup -- apt update && apt upgrade
lxc exec web2Backup -- apt-get install apache2 -y
lxc exec web2Backup -- systemctl enable apache2

echo "***Creando index web2Backup"
cat > /home/vagrant/indexweb2Backup.html <<INDEX
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
			border-top-color:orange;
			color:orange;
		}
	</style>
		<h1>COMPUTACION EN LA NUBE - WEB2 BACKUP</h1>
		<img id ="img1" src="https://image.freepik.com/foto-gratis/concepto-computacion-nube-conectese-nube-empresario-o-tecnologo-informacion-icono-computacion-nube_99433-519.jpg" width="20%" alt="CompuNube">
	</body>
</html>
INDEX

echo "***Enviando index al contenedor web2Backup"
lxc file push /home/vagrant/indexweb2Backup.html web2Backup/var/www/html/index.html

echo "***Iniciando apache2 en web2Backup"
lxc exec web2Backup -- systemctl start apache2
lxc exec web2Backup -- systemctl restart apache2
