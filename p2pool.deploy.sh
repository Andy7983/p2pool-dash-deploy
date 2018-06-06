#!/bin/bash
# Author: Chris Har
# Thanks to all who published information on the Internet!
#
# Disclaimer: Your use of this script is at your sole risk.
# This script and its related information are provided "as-is", without any warranty, 
# whether express or implied, of its accuracy, completeness, fitness for a particular 
# purpose, title or non-infringement, and none of the third-party products or information 
# mentioned in the work are authored, recommended, supported or guaranteed by The Author. 
# Further, The Author shall not be liable for any damages you may sustain by using this 
# script, whether direct, indirect, special, incidental or consequential, even if it 
# has been advised of the possibility of such damages. 
#

#
# NOTE:
# This script is based on:
# - Git Commit: 18dc987 => https://github.com/dashpay/p2pool-dash
# - Git Commit: 20bacfa => https://github.com/dashpay/dash
#
# You may have to perform your own validation / modification of the script to cope with newer 
# releases of the above software.
#
# Tested with Ubuntu 17.10
#

#
# Variables
# UPDATE THEM TO MATCH YOUR SETUP !!
#
PUBLIC_IP=<192.168.1.87>
EMAIL=<s701156@gmail.com>
PAYOUT_ADDRESS=<XjY6TyJfAxG5E9JWA5Pb2bX1vnJ7JoPiff>
USER_NAME=<Andy7983>
RPCUSER=<Andy7983>
RPCPASSWORD=<Jongho6661>

FEE=0.5
DONATION=0.5
DASH_WALLET_URL=https://github.com/dashpay/dash/releases/download/v0.12.2.3/dashcore-0.12.2.3-linux64.tar.gz
DASH_WALLET_ZIP=dashcore-0.12.2.3-linux64.tar.gz
DASH_WALLET_LOCAL=dashcore-0.12.2
P2POOL_FRONTEND=https://github.com/justino/p2pool-ui-punchy
P2POOL_FRONTEND2=https://github.com/johndoe75/p2pool-node-status
P2POOL_FRONTEND3=https://github.com/hardcpp/P2PoolExtendedFrontEnd

#
# Install Prerequisites
#
cd ~
sudo apt-get --yes install python-zope.interface python-twisted python-twisted-web python-dev
sudo apt-get --yes install gcc g++
sudo apt-get --yes install git

#
# Get latest p2pool-DASH
#
mkdir git
cd git
git clone https://github.com/dashpay/p2pool-dash
cd p2pool-dash
git submodule init
git submodule update
cd dash_hash
python setup.py install --user

#
# Install Web Frontends
#
cd ..
mv web-static web-static.old
git clone $P2POOL_FRONTEND web-static
mv web-static.old web-static/legacy
cd web-static
git clone $P2POOL_FRONTEND2 status
git clone $P2POOL_FRONTEND3 ext

#
# Get specific version of DASH wallet for Linux
#
cd ~
mkdir dash
cd dash
wget $DASH_WALLET_URL
tar -xvzf $DASH_WALLET_ZIP
rm $DASH_WALLET_ZIP

#
# Copy DASH daemon
#
sudo cp ~/dash/$DASH_WALLET_LOCAL/bin/dashd /usr/bin/dashd
sudo cp ~/dash/$DASH_WALLET_LOCAL/bin/dash-cli /usr/bin/dash-cli
sudo chown -R $USER_NAME:$USER_NAME /usr/bin/dashd
sudo chown -R $USER_NAME:$USER_NAME /usr/bin/dash-cli

#
# Prepare DASH configuration
#
mkdir ~/.dashcore
cat <<EOT >> ~/.dashcore/dash.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
alertnotify=echo %s | mail -s "DASH Alert" $EMAIL
server=1
daemon=1
EOT

#
# Get latest DASH core
#
cd ~/git
git clone https://github.com/dashpay/dash

#
# Install DASH daemon service and set to Auto Start
#
cd /etc/systemd/system
sudo ln -s /home/$USER_NAME/git/dash/contrib/init/dashd.service dashd.service
sudo sed -i 's/User=dashcore/User='"$USER_NAME"'/g' dashd.service
sudo sed -i 's/Group=dashcore/Group='"$USER_NAME"'/g' dashd.service
sudo sed -i 's/\/var\/lib\/dashd/\/home\/'"$USER_NAME"'\/.dashcore/g' dashd.service
sudo sed -i 's/\/etc\/dashcore\/dash.conf/\/home\/'"$USER_NAME"'\/.dashcore\/dash.conf/g' dashd.service
sudo systemctl daemon-reload
sudo systemctl enable dashd
sudo service dashd start

#
# Prepare p2pool startup script
#
cat <<EOT >> ~/p2pool.start.sh
python ~/git/p2pool-dash/run_p2pool.py --external-ip $PUBLIC_IP -f $FEE --give-author $DONATION -a $PAYOUT_ADDRESS
EOT

if [ $? -eq 0 ]
then
echo
echo Installation Completed.
echo You can start p2pool instance by command:
echo
echo bash ~/p2pool.start.sh
echo
echo NOTE: you will need to wait until DASH daemon has finished
echo blockchain synchronization before the p2pool instance is usable.
echo
fi
