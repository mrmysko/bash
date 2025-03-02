#!/bin/bash

# Run as root
# Installs and configures promtail

PROM_HOST=<url>

mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

apt update && apt install promtail

cat << EOF > /etc/promtail/config.yml
server:
  disable: true
  http_listen_port: 9081
  grpc_listen_port: 0

positions:
  filename: /etc/promtail/positions.yaml

clients:
  - url: http://$PROM_HOST/insert/loki/api/v1/push?_stream_fields=job,host

scrape_configs:
  - job_name: journal
    journal:
      json: false
      labels:
        job: journal
      max_age: 6h

    relabel_configs:
      - source_labels: ['__journal__hostname']
        target_label: host
      - source_labels: ['__journal_priority_keyword']
        target_label: level
      - source_labels: ['__journal__systemd_unit']
        target_label: service
      - source_labels: ['__journal__transport']
        target_label: stream
EOF

systemctl restart promtail
