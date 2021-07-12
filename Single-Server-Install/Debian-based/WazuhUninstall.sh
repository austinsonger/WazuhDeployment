#!/bin/bash
#
# OS: Debian-based Systems
############################

###########################
# Wazuh Deployment CleanUp
# (Run Script with Sudo)
###########################

apt remove --purge wazuh-manager
apt-get remove --purge filebeat
apt-get remove --auto-remove opendistroforelasticsearch
apt-get remove --purge opendistroforelasticsearch-kibana
apt autoremove
cd ~
sudo rm -rf /var/lib/elasticsearch
sudo rm -rf /etc/elasticsearch
sudo rm -rf /var/lib/kibana
sudo rm -rf /etc/kibana
sudo rm -rf /var/lib filebeat
sudo rm -rf /etc/filebeat
sudo rm -rf /usr/share/filebeat/
