#!/bin/bash
# Script Name: gems_memory_usage_alert.sh
# Description: Send an alert if memory usage is high using msmtp
# Author: Rajeev Sharma/Gemsny
# Date: 2025-07-28
# Version: 1.0

# ------------ CONFIGURATION ------------
THRESHOLD=80
EMAILS="cloud@gemsny.in ratnesh@gemsny.com navneet@gemsny.in"
LOGFILE="/var/log/mem_alert.log"
# ------------ END CONFIGURATION --------

# Function to get current memory usage in percentage
get_memory_usage() {
    free | awk '/Mem:/ { printf("%.0f\n", ($3/$2) * 100) }'
}

# Function to send alert via msmtp
send_alert() {
    local usage=$1
    local message="High memory usage detected: ${usage}% used on $(hostname) at $(date)"

    # Log the message
    echo "$message" >> "$LOGFILE"

    # Compose and send email using msmtp
    {
        echo "To: ${EMAILS}"
        echo "From: cloud@gemsny.in"
        echo "Subject: [ALERT] High Memory Usage on $(hostname)"
        echo
        echo "$message"
    } | msmtp --debug --logfile=/var/log/msmtp.log -a default $EMAILS
}

# MAIN
current_usage=$(get_memory_usage)

if [ "$current_usage" -ge "$THRESHOLD" ]; then
    send_alert "$current_usage"
fi
