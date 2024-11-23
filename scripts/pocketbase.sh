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
