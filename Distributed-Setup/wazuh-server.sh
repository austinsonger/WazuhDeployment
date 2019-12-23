###############################
#
#
# Wazuh Manager
# Filebeat
# Wazuh API
###############################

###############################
# Install Wazuh repo
###############################

echo Install Wazuh repo\n

apt update && apt upgrade -y && apt autoremove -y
apt install curl apt-transport-https lsb-release gnupg2 dirmngr sudo expect net-tools -y
if [ ! -f /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
apt update

###############################
# Install Wazuh manager
###############################
echo Wazuh manager
apt install wazuh-manager -y


###############################
# Install wazuh api
###############################
echo Wazuh api
curl -sL https://deb.nodesource.com/setup_8.x | bash -
apt install nodejs -y
apt install wazuh-api -y

###############################
# Prevent accidental updates
###############################
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
apt update -y

###############################
# Install Filebeat
###############################
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
apt update
apt install filebeat=7.4.0 -y
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

###############################
# Wazuh API Authorization
###############################
cd /var/ossec/api/configuration/auth
echo -e "You need to set a username and password for the Wazuh API."
read -p "Please enter a username : " apiuser
node htpasswd -c user $apiuser
systemctl restart wazuh-api
