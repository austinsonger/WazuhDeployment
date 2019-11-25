# Install Wazuh repo
echo Install Wazuh repo\n

apt update && apt upgrade -y && apt autoremove -y
apt install curl apt-transport-https lsb-release gnupg2 dirmngr sudo expect net-tools -y
if [ ! -f /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt update

# Install Wazuh manager
echo Wazuh manager
apt install wazuh-manager

# Install wazuh api
echo Wazuh api
curl -sL https://deb.nodesource.com/setup_8.x | bash -
apt install nodejs -y
apt install wazuh-api -y

# Prevent accidental updates
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
apt update

# Install Filebeat
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
apt update
apt install filebeat=7.4.0
curl -so /etc/filebeat/filebeat.yml https://raw.githubusercontent.com/wazuh/wazuh/v3.10.2/extensions/filebeat/7.x/filebeat.yml
curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/v3.10.2/extensions/elasticsearch/7.x/wazuh-template.json
curl -s https://packages.wazuh.com/3.x/filebeat/wazuh-filebeat-0.1.tar.gz | sudo tar -xvz -C /usr/share/filebeat/module
cp /etc/filebeat/filebeat.yml /tmp/
my_ip="$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'):9200"
sed -i "s/YOUR_ELASTIC_SERVER_IP:9200/$my_ip/" /etc/filebeat/filebeat.yml
systemctl daemon-reload
systemctl enable filebeat.service
systemctl start file
beat.service
curl https://raw.githubusercontent.com/wazuh/wazuh/v3.10.2/extensions/elasticsearch/7.x/wazuh-template.json | curl -X PUT "http://192.168.0.68:9200/_template/wazuh" -H 'Content-Type: application/json' -d @-
systemctl restart filebeat.service

# Install Elastic Stack
echo Elastic Stack
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
apt update
apt install elasticsearch=7.4.0
cp /etc/elasticsearch/elasticsearch.yml /tmp/
my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
sed -i "s/^#network.host: 192.168.0.1/network.host: $my_ip/" /etc/elasticsearch/elasticsearch.yml
# echo -e "\n \nFurther configuration will be necessary after changing the network.host option. \nUncomment the following lines in the file /etc/elasticsearch/elasticsearch.yml:\n \n# node.name: <node-1> \n# cluster.initial_master_nodes: \n"
sed -i 's/^#node\.name: node\-1/node\.name: node\-1/'i /etc/elasticsearch/elasticsearch.yml
sed -i 's/^#cluster\.initial_master_nodes: \["node-1", "node-2"]/cluster.initial_master_nodes: ["node-1"]'/i /etc/elasticsearch/elasticsearch.yml
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

# Wait for Elastic to start, my server is realy slow, so I'll wait 5 minutes
echo sleeping for 5 minutes
sleep 300
# notes: curl "http://localhost:9200/?pretty"
# curl: (7) Failed to connect to localhost port 9200: Connection refused
# filebeat setup --index-management -E setup.template.json.enabled=false

# Install Kibana
apt install kibana=7.4.0
sudo -u kibana /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-3.10.2_7.4.0.zip
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
echo sleeping for 10 seconds
sleep 10
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/elastic-7.x.list
apt update

# Protect Kibana with a reverse proxy
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
cd /var/ossec/api/configuration/auth
echo -e "You need to set a username and password for the Wazuh API."
read -p "Please enter a username : " apiuser
node htpasswd -c user $apiuser
systemctl restart wazuh-api
my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
echo "All done! You can login under https://$my_ip"
read -p "Press [Enter] to exit." 

