#!/bin/bash
# Script Name: qa_automation_deployment.sh
# Description: To deploy the latest code on live
# Author: <Rajeev Sharma/Gemsny>
# Date: <2025-09-11>
# Version: 1.1

set -e  # Exit immediately on any command failure

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
NC='\e[0m' # No Color

# Log file (new per run with timestamp)
TIMESTAMP=$(date +"%Y_%m_%d_%H_%M_%S")
LOG_DIR="/var/log/qa_automation"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/qa_automation_deploy_${TIMESTAMP}.log"

# Logging function (colored console + plain log file)
log() {
  local level="$1"; shift
  local message="$*"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  case "$level" in
    info)    echo -e "${YELLOW}[...] $message${NC}" ;;
    success) echo -e "${GREEN}[✔] $message${NC}" ;;
    error)   echo -e "${RED}[✘] $message${NC}" ;;
    *)       echo -e "$message" ;;
  esac | tee -a >(sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" >> "$LOG_FILE")

  # Timestamped plain log line
  echo "$timestamp [$level] $message" >> "$LOG_FILE"
}

# Kill newer npm start processes
log info "Killing newer npm start processes..."
ps -eo pid,lstart,cmd --sort=start_time \
  | grep "npm run qastart" \
  | grep -v grep \
  | awk '{print $1}' \
  | xargs -r kill -9
log success "Killed old npm processes."

# Kill processes on ports 6001 and 6002
log info "Killing processes on ports 6001 and 6002..."
PIDS=$(netstat -tulpn 2>/dev/null | grep -E ':6001|:6002' | awk '{print $7}' | cut -d'/' -f1)
[ -n "$PIDS" ] && kill -9 $PIDS
log success "Port cleanup complete."

# Move to project directory
log info "Switching to project directory..."
cd /srv/goserone/qa_automation/QA_Automation || { log error "Project directory not found"; exit 1; }
log success "Inside project directory."

# Ask user for Git credentials
# read -p "Enter Git username: " GIT_USER
# read -s -p "Enter Git password or token: " GIT_PASS
# echo ""

# Extract remote URL without https://
# REPO_URL=$(git remote get-url origin | sed -e 's#https://##')

# Run git pull with credentials
log info "Pulling latest code from Git..."
git pull origin development || { log error "Git pull failed"; exit 1; }
log success "Code updated."

# Backend
log info "Building Backend qa_automation application..."
cd /srv/goserone/qa_automation/QA_Automation/server || { log error "Backend directory not found"; exit 1; }
npm ci || { log error "npm ci failed in backend"; exit 1; }
npm run build || { log error "npm run build failed in backend"; exit 1; }
nohup npm run qastart > /srv/goserone/qa_automation/QA_Automation/server/qa_backend.log 2>&1 &
log success "Backend started with PID $!"

# Frontend
log info "Building Frontend qa_automation application..."
cd /srv/goserone/qa_automation/QA_Automation/web || { log error "Frontend directory not found"; exit 1; }
npm ci || { log error "npm ci failed in frontend"; exit 1; }
npm run build || { log error "npm run build failed in frontend"; exit 1; }
nohup npm run qastart > /srv/goserone/qa_automation/QA_Automation/web/qa_frontend.log 2>&1 &
log success "Frontend started with PID $!"

log info "Tailing logs..."
tail /srv/goserone/qa_automation/QA_Automation/server/qa_backend.log
sleep 2
tail /srv/goserone/qa_automation/QA_Automation/web/qa_frontend.log

######### End of Script ############