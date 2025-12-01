#!/bin/bash
# Script Name: gems_folder_monitor.sh
# Description: Real-time monitoring of folder changes (create/modify/delete/permission change)
# Author: <Rajeev Sharma / GemsNY>
# Updated On: <2025-11-11>
# Version: 2.1

# ============ CONFIGURATION ============
TEST_FOLDER="/srv/goserone/gemorder/public_html/stonetool/uploads"
EMAILS1="cloud@gemsny.in,navneet@gemsny.in,ratnesh@gemsny.in"
LOGFILE="/var/log/folder_monitor.log"
AUDIT_KEY="upload_folder_monitor_stonetool"   # Must match: auditctl -k test_folder
# =======================================

command -v inotifywait >/dev/null 2>&1 || {
  echo "inotify-tools not installed. Install using: yum install inotify-tools -y"
  exit 1
}

echo "Monitoring started on $TEST_FOLDER ....."
echo "$(date): Monitoring started." >> "$LOGFILE"

inotifywait -m -r \
  -e create -e delete -e attrib \
  --exclude '(\.swp$|\.swpx$|\.tmp$|\.swx$)' \
  --format '%e|%w%f' "$TEST_FOLDER" | while IFS='|' read -r event file
do
    EVENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")   # Capture timestamp
    sleep 1  # Allow auditd to record event (important)

# Fetch last audit event
#AUDIT_DATA=$(ausearch -k "$AUDIT_KEY" -ts recent --interpret 2>/dev/null | tail -20)
AUDIT_DATA=$(ausearch -k "$AUDIT_KEY" -ts "$EVENT_TIME" --interpret 2>/dev/null | grep -E "SYSCALL|PATH|comm=")

# Extract UID (actual user performing action)
FILE_UID=$(echo "$AUDIT_DATA" | grep -oP 'uid=\K[0-9]+' | head -1)

# Convert UID → Username
USERNAME=$(getent passwd "$FILE_UID" | cut -d: -f1)

# Extract process name
PROCESS=$(echo "$AUDIT_DATA" | grep -oP 'comm="\K[^"]+' | head -1)

# If username or process is empty, assign default
[[ -z "$USERNAME" ]] && USERNAME="Unknown"
[[ -z "$PROCESS" ]] && PROCESS="Unknown"

    # Log entry
    echo "$(date): $event on $file by $USERNAME ($PROCESS)" >> "$LOGFILE"

    # Send email notification
    {
      echo "To: $EMAILS1"
      echo "From: cloud@gemsny.in"
      echo "Subject: [ALERT] Folder Change Detected on $(hostname)"
      echo
      echo "Folder Monitoring Alert"
      echo "--------------------------------------"
      echo "Event         : $event"
      echo "File          : $file"
      echo "User          : $USERNAME"
      echo "Process       : $PROCESS"
      echo "Timestamp     : $(date)"
      echo "Server        : $(hostname)"
      echo "Path Monitored: $TEST_FOLDER"
      echo "--------------------------------------"
    } | msmtp --debug --logfile=/var/log/msmtp.log -a default $EMAILS1

done
