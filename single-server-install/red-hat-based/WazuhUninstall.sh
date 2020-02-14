#!/bin/bash
#
# OS: RedHat-based Systems (Yum)
############################

###########################
# Wazuh Deployment CleanUp
# (Run Script with Sudo)
###########################

yum remove wazuh-manager
yum remove nodejs
yum remove filebeat
yum remove elasticsearch
yum remove kibana
yum autoremove
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
