systemctl stop filebeat
systemctl stop kibana

curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | yum-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/yum stable main" | tee /etc/yum/sources.list.d/elastic-7.x.list


curl -X PUT "localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}
'

curl -X POST "localhost:9200/_flush/synced"


systemctl stop elasticsearch

yum install elasticsearch=7.5.1
systemctl restart elasticsearch
systemctl daemon-reload
systemctl restart elasticsearch

curl -X GET "localhost:9200/_cat/nodes"


curl -X PUT "localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d'
{
  "persistent": {
    "cluster.routing.allocation.enable": null
  }
}
'

curl -X GET "localhost:9200/_cat/health?v"



yum install filebeat=7.5.1
cp /etc/filebeat/filebeat.yml /backup/filebeat.yml.backup
curl -so /etc/filebeat/filebeat.yml https://raw.githubusercontent.com/wazuh/wazuh/v3.11.0/extensions/filebeat/7.x/filebeat.yml
chmod go+r /etc/filebeat/filebeat.yml
curl -s https://packages.wazuh.com/3.x/filebeat/wazuh-filebeat-0.1.tar.gz | sudo tar -xvz -C /usr/share/filebeat/module















