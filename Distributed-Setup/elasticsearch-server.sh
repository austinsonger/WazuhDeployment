#!/bin/bash
#
# Author: Austin Songer
#
# OS: Debian-based Systems
############################


apt install curl apt-transport-https lsb-release gnupg2 dirmngr sudo expect net-tools -y
if [ ! -f /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi


############################
# ElasticSearch
# Kibana
# Wazuh App
############################

###############################
# Install Elastic Stack
###############################
echo "---- Installing the Elasticsearch Debian Package ----"
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
apt update
apt install elasticsearch=7.5.1
cp /etc/elasticsearch/elasticsearch.yml /tmp/
my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
sed -i "s/^#network.host: 192.168.0.1/network.host: $my_ip/" /etc/elasticsearch/elasticsearch.yml
# echo -e "\n \nFurther configuration will be necessary after changing the network.host option. \nUncomment the following lines in the file /etc/elasticsearch/elasticsearch.yml:\n \n# node.name: <node-1> \n# cluster.initial_master_nodes: \n"
sed -i 's/^#node\.name: node\-1/node\.name: node\-1/'i /etc/elasticsearch/elasticsearch.yml
sed -i 's/^#cluster\.initial_master_nodes: \["node-1", "node-2"]/cluster.initial_master_nodes: ["node-1"]'/i /etc/elasticsearch/elasticsearch.yml
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

echo RESTARTING Elasticsearch.......
sleep 200
# notes: curl "http://localhost:9200/?pretty"
# curl: (7) Failed to connect to localhost port 9200: Connection refused
# filebeat setup --index-management -E setup.template.json.enabled=false

###############################
# Install Kibana
###############################
echo "---- Installing the Kibana Debian Package ----"
apt install kibana=7.5.1
sudo -u kibana /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-3.11.0_7.5.1.zip
cp /etc/kibana/kibana.yml /tmp/
my_ip=\""$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')\""
sed -i "s/^#server\.host: \"localhost\"/server\.host: $my_ip/" /etc/kibana/kibana.yml
echo -e "Configure the URLs of the Elasticsearch instances to use for all your queries by editing the file /etc/kibana/kibana.yml: \nUncomment server.host and change the ip. \nAlso set elasticsearch.hosts: [http://<elasticsearch.hosts:9200] to the correct ip \nExit nano by pressing F2 then Y"
my_ip="$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'):9200"
sed -i "s/^#elasticsearch\.hosts/elasticsearch.hosts/" /etc/kibana/kibana.yml
sed -i "s/localhost:9200/$my_ip/" /etc/kibana/kibana.yml
systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service
echo Restarting Kibana
sleep 10
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/elastic-7.x.list
apt update

######################################
# Protect Kibana with a reverse proxy
######################################
######################################
# Protect Kibana with a reverse proxy
######################################
apt install nginx -y
mkdir -p /etc/ssl/certs /etc/ssl/private
cp <ssl_pem> /etc/ssl/certs/kibana-access.pem
cp <ssl_key> /etc/ssl/private/kibana-access.key
mkdir -p /etc/ssl/certs /etc/ssl/private
openssl req -x509 -batch -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/kibana-access.key -out /etc/ssl/certs/kibana-access.pem
cat > /etc/nginx/sites-available/default <<\EOF
server {
    listen 80;
    listen [::]:80;
    return 301 https://$host$request_uri;
}
server {
    listen 443 default_server;
    listen            [::]:443;
    ssl on;
    ssl_certificate /etc/ssl/certs/kibana-access.pem;
    ssl_certificate_key /etc/ssl/private/kibana-access.key;
    access_log            /var/log/nginx/nginx.access.log;
    error_log            /var/log/nginx/nginx.error.log;
    location / {
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/conf.d/kibana.htpasswd;
        proxy_pass http://localhost:5601/;
    }
}
EOF
cp /etc/nginx/sites-available/default /tmp/
my_ip="$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'):5601"
sed -i "s/localhost:5601/$my_ip/" /etc/nginx/sites-available/default

apt install apache2-utils -y
clear
echo -e "You need to set a username and password to login."
read -p "Please enter a username : " user
htpasswd -c /etc/nginx/conf.d/kibana.htpasswd $user
systemctl restart nginx
my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
echo "All done! You can login under https://$my_ip"
read -p "Press [Enter] to exit." 
