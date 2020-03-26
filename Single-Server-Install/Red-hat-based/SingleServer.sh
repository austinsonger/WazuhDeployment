#!/bin/bash
#
# OS: Redhat-based Systems
###########################

echo "--------------------------------------------------------------------------"
echo "$(date)"
echo "Starting Wazuh Made Easy"
echo "Wazuh for Red-Hat-based Systems"
echo "Wazuh Manager - Wazuh API - Elasticsearch - Kibana"
echo "-------------------------------------------------------------------------"

echo "Wazuh Made Easy Status"

echo " System Update..."

sudo yum update && sudo yum upgrade -y && sudo yum autoremove -y

wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u172-b11/a58eab1ec242421181065cdc37240b08/jdk-8u172-linux-x64.rpm"
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u172-b11/a58eab1ec242421181065cdc37240b08/jre-8u172-linux-x64.rpm"
https://download.oracle.com/otn/java/jdk/8u202-b08/1961070e4c9b4e26a04e7f5a083f551e/jdk-8u202-linux-x64.rpm
https://download.oracle.com/otn/java/jdk/8u202-b08/1961070e4c9b4e26a04e7f5a083f551e/jre-8u202-linux-x64.rpm
rpm -ivh jdk-8u172-linux-x64.rpm
rpm -ivh jre-8u172-linux-x64.rpm
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
echo "[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" > /etc/yum.repos.d/elasticsearch.repo

yum update -y
yum -y install elasticsearch-7.6.1 kibana-7.6.1 logstash-7.6.1
chkconfig --add kibana
chkconfig --add logstash
chkconfig --add elasticsearch
chkconfig logstash on
chkconfig elasticsearch on
chkconfig kibana on
/usr/share/logstash/bin/logstash-plugin install logstash-output-email
echo "cluster.name: elk01
node.name: elk01-nodo01
bootstrap.memory_lock: true
network.host: 127.0.0.1" >> /etc/elasticsearch/elasticsearch.yml
sed -i 's/-Xms1g/-Xms32g/g' /etc/elasticsearch/jvm.options
sed -i 's/-Xmx1g/-Xmx32g/g' /etc/elasticsearch/jvm.options

echo "ES_HOME=/usr/share/elasticsearch
CONF_DIR=/etc/elasticsearch
DATA_DIR=/var/lib/elasticsearch
LOG_DIR=/var/log/elasticsearch
PID_DIR=/var/run/elasticsearch
ES_USER=elasticsearch
ES_GROUP=elasticsearch
ES_STARTUP_SLEEP_TIME=5
MAX_OPEN_FILES=9965536" >> /etc/sysconfig/elasticsearch

echo 'server.port: 5601
server.host: "localhost"
server.name: "ELK01"
elasticsearch.url: "http://localhost:9200"
elasticsearch.preserveHost: true
kibana.index: ".kibana"
kibana.defaultAppId: "discover"' >> /etc/kibana/kibana.yml
service elasticsearch start
service kibana start

cat > /etc/yum.repos.d/wazuh.repo <<\EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/3.x/yum/
protect=1
EOF

yum update
yum -y install wazuh-manager
service wazuh-manager status
curl --silent --location https://rpm.nodesource.com/setup_10.x | bash -
yum install -y nodejs
python --version
netstat -tapn | grep LISTEN
yum -y install wazuh-api
service wazuh-api status

curl https://raw.githubusercontent.com/wazuh/wazuh/3.2/extensions/elasticsearch/wazuh-elastic6-template-alerts.json | curl -XPUT 'http://localhost:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/3.2/extensions/logstash/01-wazuh-local.conf
chown logstash:logstash /etc/logstash/conf.d/01-wazuh.conf
usermod -a -G ossec logstash
systemctl daemon-reload
export NODE_OPTIONS="--max-old-space-size=3072"
/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-3.12.0_7.6.1.zip
sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/elasticsearch.repo
node /var/ossec/api/configuration/auth/htpasswd -c /var/ossec/api/configuration/auth/user manager
service wazuh-api restart
echo "PASSWORD" /var/ossec/etc/authd.pass
/var/ossec/bin/ossec-authd -i -P -a
firewall-cmd --permanent --add-port=1515/tcp
firewall-cmd --permanent --add-port=1514/udp
firewall-cmd --reload
service logstash start
service kibana restart
