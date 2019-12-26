#!/bin/bash
#
# OS: Debian-based Systems
############################

###########################
# Wazuh Deployment CleanUp
# (Run Script with Sudo)
###########################

apt remove --purge wazuh-manager
apt remove --purge nodejs
apt remove --purge filebeat
apt remove --purge elasticsearch
apt remove --purge kibana
apt autoremove
cd
cd ../../
cd /var/lib
sudo rm -R -f elasticsearch
cd ../../
cd etc
sudo rm -R -f elasticsearch
cd ../
cd /var/lib
sudo rm -R -f kibana
cd ../../
cd etc
sudo rm -R -f kibana
cd ../../
cd /var/lib
sudo rm -R -f filebeat
cd ../../
cd etc
sudo rm -R -f filebeat
cd
