
helm plugin install https://github.com/komodorio/helm-dashboard.git

kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml


export HD_BIND=0.0.0.0
export HD_PORT=8081

sudo nano /etc/systemd/system/helm-dashboard.service
"
[Unit]
Description=Helm Dashboard
After=network.target

[Service]
User=<your-username>
Group=<your-group>
ExecStart=/usr/local/bin/helm dashboard --bind=0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
"

sudo systemctl daemon-reload
sudo systemctl enable helm-dashboard.service
sudo systemctl start helm-dashboard.service


