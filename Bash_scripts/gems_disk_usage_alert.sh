#!/bin/bash
# Script Name: gems_disk_usage_alert.sh
# Description: To send an alert while disk usage is high
# Author: <Rajeev Sharma/Gemsny>
# Date: <2025-07-28>
# Version: 1.1

# ------------ CONFIGURATION ------------
THRESHOLD=80
EMAILS="cloud@gemsny.in,ratnesh@gemsny.com,navneet@gemsny.in"
#EMAILS="cloud@gemsny.in"
LOGFILE="/var/log/disk_alert.log"
# ------------ END CONFIGURATION --------

ALERTS=""

# Check disk usage
while read -r line; do
    USAGE=$(echo "$line" | awk '{print $1}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $2}')

    if [ "$USAGE" -gt "$THRESHOLD" ]; then
        ALERTS+="ALERT: Disk usage on $MOUNT is at ${USAGE}%.\n"
    fi
done < <(df -h --output=pcent,target | tail -n +2)

# If we have alerts, send one consolidated email
if [ -n "$ALERTS" ]; then
    {
      echo "To: $EMAILS"
      echo "From: cloud@gemsny.in"
      echo "Subject: Disk Usage Alert on $(hostname)"
      echo
      echo -e "$ALERTS"
    } | msmtp --debug --logfile=/var/log/msmtp.log -a default $EMAILS

    echo "$(date): Disk usage alerts sent." >> "$LOGFILE"
fi