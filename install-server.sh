#!/bin/sh
# This script will install SoftEther VPN, enable Secure NAT, and add 1 Hub and 1 User
# Run this on Debian 10 or Debian 9
# 4-Feb-2020
# github.com/sk3dd

# Set parameters
read -p 'Set VPN user password (Please only use letters and numbers [a-zA-Z0-9], periods [.], and exclamation marks [!]): ' PASSWD
USERNM=unchainVpnUser
HUB=vhub
USERNMLC=$(echo "$USERNM" | tr '[:upper:]' '[:lower:]')

echo "That's it. Starting setup in 3…"; sleep 1; echo "2…"; sleep 1; echo "1…"

# Download packages
apt-get install sudo build-essential libreadline-dev libssl-dev libncurses-dev zlib1g-dev git cmake -y
if [ $? -ne 0 ]; then
	echo "Failed to download packages. Run 'apt update' and try again."
	exit 1
fi

# Add user to run service in user space
adduser --disabled-password --gecos '' $USERNMLC
usermod -aG sudo $USERNMLC
#printf "$PASSWD\n$PASSWD" | passwd $USERNMLC
sed -i -e '$i '"$USERNMLC"' ALL = NOPASSWD : ALL\n' /etc/sudoers

# Install SoftEther VPN
git clone https://github.com/SoftEtherVPN/SoftEtherVPN_Stable.git
cd ./SoftEtherVPN_Stable
./configure
make
make install

# Start and setup SoftEther VPN
sudo -u "$USERNMLC" -H sh -c "
sudo vpnserver start &&
sleep 1 &&
sudo vpncmd /SERVER localhost /CMD HubCreate ""\"$HUB\""" /PASSWORD:""\"$PASSWD\""" >/dev/null &&
sudo vpncmd /SERVER localhost /HUB:""\"$HUB\""" /PASSWORD:""\"$PASSWD\""" /CMD SecureNatEnable &&
sudo vpncmd /SERVER localhost /HUB:""\"$HUB\""" /PASSWORD:""\"$PASSWD\""" /CMD UserCreate $USERNM /GROUP:none /REALNAME:none /NOTE:none &&
sudo vpncmd /SERVER localhost /HUB:""\"$HUB\""" /PASSWORD:""\"$PASSWD\""" /CMD UserPassword $USERNM /PASSWORD:""\"$PASSWD\""" >/dev/null
"
retVal=$?

# Exit
if [ $retVal -ne 0 ]; then
	echo "Error occured."
elif [ $retVal -eq 0 ]; then
	echo "Hub created successfully."
	echo "User created successfully."
	echo "VPN is ready."
	exit $retVal
fi
if [ $retVal -eq 57 ]; then
	echo "A Virtual Hub with the specified name already exists on the server."
	exit $retVal
fi
if [ $retVal -eq 66 ]; then
	echo "A user with the specified name already exists for this Virtual Hub."
	exit $retVal
fi