#!/bin/bash

# ./pocketbase.sh NAME="timesheet" PORT="8090" VERSION="0.22.3"

for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)
   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"
   export "$KEY"="$VALUE"
done

if [ -z "$NAME" ]; then
  echo "Error: NAME variable is not set."
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION variable is not set."
  exit 1
fi

if [ -z "$PORT" ]; then
  echo "Error: PORT variable is not set."
  exit 1
fi

if [ -z "$DOMAIN" ]; then
  echo "Error: DOMAIN variable is not set."
  exit 1
fi

if [ -z "$EMAIL" ]; then
  echo "Error: EMAIL variable is not set."
  exit 1
fi

WORKDIR="/mnt/pocketbase/$NAME"

# Create folder if not exists
if [ ! -d "$WORKDIR" ]; then
  mkdir -p "$WORKDIR"
fi

cd $WORKDIR

# Delete service and executable if already exists
if systemctl list-unit-files --type=service | grep -q "^${NAME}"; then
    # Stop the service if it's running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME"
    else
        echo "Service ${SERVICE_NAME} is not running."
    fi
fi

# Download executable
sudo wget -O pocketbase_source.zip "https://github.com/pocketbase/pocketbase/releases/download/v$VERSION/pocketbase_${VERSION}_linux_amd64.zip"
sudo unzip -o pocketbase_source.zip
sudo rm -rf pocketbase_source.zip

# Set up systemd service
sudo touch /lib/systemd/system/$NAME.service
echo "[Unit]
Description = $NAME

[Service]
Type           = simple
User           = root
Group          = root
LimitNOFILE    = 4096
Restart        = always
RestartSec     = 5s
StandardOutput = append:$WORKDIR/errors.log
StandardError  = append:$WORKDIR/errors.log
ExecStart      = $WORKDIR/pocketbase serve --http="0.0.0.0:$PORT"

[Install]
WantedBy = multi-user.target" | sudo tee -a "/lib/systemd/system/$NAME.service"

sudo systemctl enable $NAME.service
sudo systemctl start $NAME

# Set up cronjob to automatically update
echo "0 1 * * 1 sudo $WORKDIR/pocketbase update && sudo systemctl restart $NAME" | sudo tee -a /etc/crontab

# Make sure we stop nginx from any previous script runs
sudo systemctl stop nginx

# Set up port 80 to generate certificate
sudo bash -c "echo 'server {
  listen 80;
  server_name $DOMAIN;
  client_max_body_size 10M;

  location / {
    # check http://nginx.org/en/docs/http/ngx_http_upstream_module.html#keepalive
    # proxy_set_header Connection "";
    proxy_http_version 1.1;
    proxy_read_timeout 360s;

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    # enable if you are serving under a subpath location
    # rewrite /yourSubpath/(.*) /$1  break;

    proxy_pass http://127.0.0.1:$PORT;
  }
}
' > /etc/nginx/conf.d/$NAME.conf"

sudo systemctl enable nginx
sudo systemctl start nginx


sudo /usr/local/bin/certbot --nginx -n --agree-tos -m $EMAIL --cert-name $DOMAIN --domains $DOMAIN

# Set a cron job to automatically renew the certificate
echo '0 0 1 1,3,5,7,9,11 * /usr/local/bin/certbot renew --quiet' | sudo tee -a /etc/crontab

# Update the nginx config after a certificate has been generated
sudo systemctl stop nginx

sudo bash -c "echo 'server {
  listen 80;
  server_name $DOMAIN;
  return 301 https://\$server_name\$request_uri;
}

server {
  listen 443 ssl;
  server_name $DOMAIN;

  ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

  client_max_body_size 10M;

  location / {
    proxy_http_version 1.1;
    proxy_read_timeout 360s;

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_pass http://127.0.0.1:$PORT;
  }
}
' > /etc/nginx/conf.d/$NAME.conf"

sudo systemctl restart nginx
