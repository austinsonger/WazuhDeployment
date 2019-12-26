#!/bin/bash
#
# Author: Austin Songer
# OS: Debian-based Systems
#===========================

echo "--------------------------------------------------------------------------"
echo "$(date)"
echo "Starting Wazuh Made Easy - Only Elasticsearch"
echo "Wazuh for Debian-based Systems"
echo "Elasticsearch"
echo "-------------------------------------------------------------------------"
echo -e "Wazuh Made Easy - Only Elasticsearch Status"
echo " System Update..."

#############
# Preparing
#############
sudo -n true
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
sudo apt install curl apt-transport-https lsb-release gnupg2 dirmngr sudo expect net-tools -y
if [ ! -f /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi


###############################
# Install Elastic Stack
###############################
echo "---- Installing the Elasticsearch Debian Package ----"
sleep 5

# Source List Install
#curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
#echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
#sudo apt install elasticsearch=7.5.1

# Direct Install
sudo wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.5.1-amd64.deb
sudo dpkg -i elasticsearch-7.5.1-amd64.deb
sudo rm elasticsearch*

sudo cp /etc/elasticsearch/elasticsearch.yml /tmp/
my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
sudo sed -i "s/^#network.host: 192.168.0.1/network.host: $my_ip/" /etc/elasticsearch/elasticsearch.yml
# echo -e "\n \nFurther configuration will be necessary after changing the network.host option. \nUncomment the following lines in the file /etc/elasticsearch/elasticsearch.yml:\n \n# node.name: <node-1> \n# cluster.initial_master_nodes: \n"
sudo sed -i 's/^#node\.name: node\-1/node\.name: node\-1/'i /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/^#cluster\.initial_master_nodes: \["node-1", "node-2"]/cluster.initial_master_nodes: ["node-1"]'/i /etc/elasticsearch/elasticsearch.yml
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
echo RESTARTING Elasticsearch.......
sleep 120

# filebeat setup --index-management -E setup.template.json.enabled=false

###############################
# Prevent Unintentable Update
###############################
sudo sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
