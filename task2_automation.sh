#!/bin/bash

set -Eeuo pipefail

# Detect current user
USER=$(whoami)
BASE_DIR="$HOME/devops-test-huawei"
CRON_DIR="/home/cron"

# step 1: create /home/cron and set permissions
sudo timedatectl set-timezone Asia/Jakarta
sudo mkdir -p "$CRON_DIR"
sudo chown -R "$USER:$USER" "$CRON_DIR"
sudo chmod -R 755 "$CRON_DIR"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# step 2: create collect_data.py
cat > collect_data.py << EOL
#!/usr/bin/env python3
import subprocess
import csv
import datetime
import os

output_dir = "$CRON_DIR"

# generate filename: cron_DDMMYYYY_HH.MM.csv
now = datetime.datetime.now()
date_str = now.strftime("%d%m%Y")
hour_str = now.strftime("%H.%M")
filename = f"cron_{date_str}_{hour_str}.csv"
filepath = os.path.join(output_dir, filename)

# Collect real data from system resources
def get_cpu_usage():
    return subprocess.getoutput("top -bn1 | grep '%Cpu'").strip() or "N/A"

def get_memory_usage():
    return subprocess.getoutput("free -h").strip() or "N/A"

def get_disk_usage():
    return subprocess.getoutput("df -h").strip() or "N/A"
# Data
data = {
    "Timestamp": now.strftime("%Y-%m-%d %H:%M:%S"),
    "CPU Usage": get_cpu_usage(),
    "Memory Usage": get_memory_usage(),
    "Disk Usage": get_disk_usage()
}

# save to CSV
with open(filepath, 'w', newline='') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=data.keys())
    writer.writeheader()
    writer.writerow(data)

print(f"[{now.strftime('%Y-%m-%d %H:%M:%S')}] Data collected and saved to {filepath}")
EOL
chmod +x collect_data.py

# step 3: create clean_data.sh
cat > clean_data.sh << EOL
#!/bin/bash

set -Eeuo pipefail

# path
dir="$CRON_DIR"

# current date-time
now=\$(date +"%Y-%m-%d %H:%M:%S")

# Delete CSV files older than 30 days without confirmation, print file name + time
find "\$dir" -name "*.csv" -type f -mtime +30 -printf "[\$now] Old files (%p) cleaned up\\n" -exec rm -f {} \;
EOL
chmod +x clean_data.sh

# step 4: configure crontab for collect data
cat > cron_collect_temp << EOL
# Collect data at 08:00, 12:00, and 15:00 WIB daily
0 8,12,15 * * * /usr/bin/python3 $BASE_DIR/collect_data.py >> $BASE_DIR/collector.log 2>&1
EOL
crontab cron_collect_temp
rm cron_collect_temp
echo "Your cronjob for collect data has been added"

# step 5: configure crontab for data cleansing
cat > cron_clean_temp << EOL
# Automatic data cleansing
* * * * * /usr/bin/bash $BASE_DIR/clean_data.sh >> $BASE_DIR/cleanup.log 2>&1
EOL
crontab -l > cron_current
cat cron_clean_temp >> cron_current
crontab cron_current
rm cron_clean_temp cron_current
echo "Your cronjob for data cleansing has been added"

sudo systemctl restart cron

echo "Setup completed."