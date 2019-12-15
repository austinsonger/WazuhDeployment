###############################
# Wazuh Deployment CleanUp
# (Run Script with Sudo)
###############################

apt remove --purge wazuh-manager
apt remove --purge nodejs
apt remove --purge filebeat
apt remove --purge elasticsearch
apt remove --purge kibana
apt autoremove
cd ../../
cd var
cd lib
rm -R -f elasticsearch
cd ../../
cd etc
rm -R -f elasticsearch
cd ../
cd var
cd lib
rm -R -f kibana
cd ../../
cd etc
rm -R -f kibana
cd
