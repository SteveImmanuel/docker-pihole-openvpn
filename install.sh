#!/bin/bash


echo "=============================================="
echo "|                                            |"
echo "|        OpenVPN+Pihole AutoInstaller        |"
echo "|                                            |"
echo "=============================================="

echo "Installing dependencies..."

apt update
apt install docker.io
apt install docker-compose

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

echo "Deploying Pihole..."
docker-compose up -d

echo "Installing OpenVPN..."

echo "Configuring OpenVPN..."

echo "Restarting OpenVPN Server..."
service openvpn restart

echo "Installation complete!"