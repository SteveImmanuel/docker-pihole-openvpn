#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run the script as root"
    exit 1
fi

echo "=============================================="
echo "|                                            |"
echo "|        OpenVPN+Pihole AutoInstaller        |"
echo "|                                            |"
echo "=============================================="

echo "Installing dependencies..."
apt update
apt install -y docker.io
apt install -y docker-compose

echo "Setting up Pihole..."
IFS=' ' read -ra IP <<< "$(hostname -I)"

read -p "Enter private/internal IP (${IP[0]}):" INTERNAL_IP

if [ "$INTERNAL_IP" == "" ]; then
    INTERNAL_IP=${IP[0]}
fi

read -s -p "Pihole Web Admin Password:" PIHOLE_PASS
echo
read -s -p "(Confirm) Pihole Web Admin Password:" PIHOLE_PASS_CONFIRM
echo

if [ "$PIHOLE_PASS" != "$PIHOLE_PASS_CONFIRM" ]; then
    echo "Mismatch password, aborting operation"
    exit 1
fi

cp docker-compose.template.yml docker-compose.yml
sed -i "s/<INTERNAL_IP>/$INTERNAL_IP/g" docker-compose.yml
sed -i "s/<PIHOLE_PASS>/$PIHOLE_PASS/g" docker-compose.yml

echo "Deploying Pihole..."
docker-compose -f docker-compose.yml up -d
DOCKER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pihole)

echo "Installing OpenVPN..."
wget https://git.io/vpn -O openvpn-install.sh
chmod +x openvpn-install.sh
./openvpn-install.sh
echo "Configuring OpenVPN..."
sed -i '/push \"dhcp-option DNS/d' /etc/openvpn/server/server.conf
sed -i "15 i push \"dhcp-option DNS $DOCKER_IP\"" /etc/openvpn/server/server.conf

echo "Restarting OpenVPN Server..."
service openvpn restart

echo "Installation complete!"