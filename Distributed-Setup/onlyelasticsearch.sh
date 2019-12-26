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


###############################
# Install Elastic Stack
###############################
echo "---- Installing the Elasticsearch Debian Package ----"
sleep 5
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt install elasticsearch=7.5.1
cp /etc/elasticsearch/elasticsearch.yml /tmp/
my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
sed -i "s/^#network.host: 192.168.0.1/network.host: $my_ip/" /etc/elasticsearch/elasticsearch.yml
# echo -e "\n \nFurther configuration will be necessary after changing the network.host option. \nUncomment the following lines in the file /etc/elasticsearch/elasticsearch.yml:\n \n# node.name: <node-1> \n# cluster.initial_master_nodes: \n"
sed -i 's/^#node\.name: node\-1/node\.name: node\-1/'i /etc/elasticsearch/elasticsearch.yml
sed -i 's/^#cluster\.initial_master_nodes: \["node-1", "node-2"]/cluster.initial_master_nodes: ["node-1"]'/i /etc/elasticsearch/elasticsearch.yml
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
echo RESTARTING Elasticsearch.......
sleep 120

# filebeat setup --index-management -E setup.template.json.enabled=false

###############################
# Prevent Unintentable Update
###############################
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
