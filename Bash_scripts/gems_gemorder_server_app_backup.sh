#!/bin/bash
# Script Name: gems_gemorder_server_app_backup.sh
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
gembargains_tar="$backup_dir/gembargains`date +\%Y\%m\%d`.tar.gz"
gemsnydev_tar="$backup_dir/gemsnydev`date +\%Y\%m\%d`.tar.gz"
gemsny_tar="$backup_dir/gemsny`date +\%Y\%m\%d`.tar.gz"
gemsnyco_tar="$backup_dir/gemsnyco`date +\%Y\%m\%d`.tar.gz"
gemsnyuk_tar="$backup_dir/gemsnyuk`date +\%Y\%m\%d`.tar.gz"
gemsnyin_tar="$backup_dir/gemsnyin`date +\%Y\%m\%d`.tar.gz"
gemsnyus_tar="$backup_dir/gemsnyus`date +\%Y\%m\%d`.tar.gz"
gemorder_tar="$backup_dir/gemorder`date +\%Y\%m\%d`.tar.gz"
ssl_tar="$backup_dir/ssl`date +\%Y\%m\%d`.tar.gz"
virtual_host_tar="$backup_dir/virtual_host`date +\%Y\%m\%d`.tar.gz"

# Source public_html folders for tar file
affordable_public_html="/srv/goserone/affordable/public_html"
gembargains_public_html="/srv/goserone/gembargains/public_html"
gemsnydev_public_html="/srv/goserone/gemsnydev/public_html"
gemsny_public_html="/srv/goserone/gemsny/public_html"
gemsnyco_public_html="/srv/goserone/gemsnyco/public_html"
gemsnyuk_public_html="/srv/goserone/gemsnyuk/public_html"
gemsnyin_public_html="/srv/goserone/gemsnyin/public_html"
gemsnyus_public_html="/srv/goserone/gemsnyus/public_html"
gemorder_public_html="/srv/goserone/gemorder/public_html"
ssl="/srv/goserone/ssl"
virtual_host="/etc/httpd/conf.d"

# To create tar file for affordable with some exclusions
echo "Creating Tar file for affordable public html folder..."
tar -czvf $affordable_tar -C $affordable_public_html --exclude='' --exclude='' .
echo "$affordable_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for gembargains with some exclusions
echo "Creating Tar file for gembargains public html folder..."
tar -czvf $gembargains_tar -C $gembargains_public_html --exclude='' --exclude='' .
echo "$gembargains_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for gemsnydev with some exclusions
echo "Creating Tar file for gemsnydev public html folder..."
tar -czvf $gemsnydev_tar -C $gemsnydev_public_html --exclude='' --exclude='' .
echo "$gemsnydev_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for gemsny with some exclusions
echo "Creating Tar file for gemsny public html folder..."
tar -czvf $gemsny_tar -C $gemsny_public_html --exclude='' --exclude='' .
echo "$gemsny_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for gemsnyco with some exclusions
echo "Creating Tar file for gemsnyco public html folder..."
tar -czvf $gemsnyco_tar -C $gemsnyco_public_html --exclude='' --exclude='' .
echo "$gemsnyco_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for gemsnyuk with some exclusions
echo "Creating Tar file for gemsnyuk public html folder..."
tar -czvf $gemsnyuk_tar -C $gemsnyuk_public_html --exclude='' --exclude='' .
echo "$gemsnyuk_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for gemsnyin with some exclusions
echo "Creating Tar file for gemsnyin public html folder..."
tar -czvf $gemsnyin_tar -C $gemsnyin_public_html --exclude='' --exclude='' .
echo "$gemsnyin_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for gemsnyus with some exclusions
echo "Creating Tar file for gemsnyus public html folder..."
tar -czvf $gemsnyus_tar -C $gemsnyus_public_html --exclude='' --exclude='' .
echo "$gemsnyus_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for gemorder with some exclusions
echo "Creating Tar file for gemorder public html folder..."
tar -czvf $gemorder_tar -C $gemorder_public_html --exclude='' --exclude='' .
echo "$gemorder_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for ssl
echo "Creating Tar file for ssl public html folder..."
tar -czvf $ssl_tar -C $ssl .
echo "$ssl_tar file is created."

echo "Sleeping for 5 seconds..."
sleep 5

# To create tar file for virtual_host
echo "Creating Tar file for virtual_host public html folder..."
tar -czvf $virtual_host_tar -C $virtual_host .
echo "$virtual_host_tar file is created."


############################################################################


echo "Sleeping for 30 seconds before cleanup..."
sleep 30

# Count today's backups
today_files=$(ls "$backup_dir"/*"$today".tar.gz 2>/dev/null | wc -l)

# Delete all .tar.gz files from yesterday
if [ "$today_files" -ge 11 ]; then
    echo "[$(date '+%F %T')] Found $today_files backups for today. Deleting yesterday's..."
    rm -f "$backup_dir"/*"$yesterday".tar.gz
    echo "---------Old backups are deleted.------------"
else
    echo "Today's backups not complete. Skipping deletion."
fi


######################### End of Script ####################################