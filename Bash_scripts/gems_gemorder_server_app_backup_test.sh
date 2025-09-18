#!/bin/bash
# Script Name: gems_gemorder_server_app_backup_test.sh
# Description: To create tar files for all the application's public_html folders including their SSL and Virtual host files
# Author: <Rajeev Sharma/Gemsny>
# Date: <2025-07-25, e.g., YYYY-MM-DD>
# Version: 1.0


# Environment for delete the tar files of 1 day back
backup_dir="/srv/gosertwo/backup_files"
yesterday=$(date -d "yesterday" +"%Y%m%d")
today=$(date +"%Y%m%d")

# Environment for tar files name
affordable_tar="$backup_dir/affordable`date +\%Y\%m\%d`.tar.gz"

# Source public_html folders for tar file
affordable_public_html="/srv/goserone/affordable/public_html"

# To create tar file for affordable with some exclusions
echo "Creating Tar file for affordable public html folder..."
tar -czvf $affordable_tar -C $affordable_public_html --exclude='' --exclude='' .
echo "$affordable_tar file is created."


############################################################################


echo "Sleeping for 5 seconds before cleanup..."
sleep 5

# Count today's backups
today_files=$(ls "$backup_dir"/*"$today".tar.gz 2>/dev/null | wc -l)

# Delete all .tar.gz files from yesterday
if [ "$today_files" -ge 1 ]; then
    echo "[$(date '+%F %T')] Found $today_files backups for today. Deleting yesterday's..."
    rm -f "$backup_dir"/*"$yesterday".tar.gz
    echo "---------Old backups are deleted.------------"
else
    echo "Today's backups not complete. Skipping deletion."
fi


######################### End of Script ####################################