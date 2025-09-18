# Set the base path for the files
$basePath = "\\SHRD-Inventory\G\gemorderDB_backup\"

# Get today's and yesterday's date in YYYYMMDD format
$today = (Get-Date).ToString("yyyyMMdd")
$yesterday = (Get-Date).AddDays(-1).ToString("yyyyMMdd")

# List of database name prefixes
$dbPrefixes = @(
    "admin_app_db_", "db139222657_", "aff_developement_", "AWS_db139222657_",
    "diamond_api_data_all_", "marketing_report_", "stone_tool_", "vendor_diamond_db_",
    "work_allot_", "stone_video_", "stone_tool_dev_", "uat-node-db_",
    "gemsny_", "etm_", "NB_Diamonddb_", "diamond_pair_",
    "dev-node-db_", "dbmigration_", "jtool_", "diamond_api_data_",
    "gemsny_affordables_"
)

# Initialize an array to store the comparison results
$comparisonResults = @()

Write-Host "--- Comparing Database Backup Sizes: Yesterday vs. Today ---"

# Loop through each database prefix to check both dates
foreach ($prefix in $dbPrefixes) {
    # Construct the full file paths for both days
    $yesterdayFile = "$basePath$prefix$yesterday.zip"
    $todayFile = "$basePath$prefix$today.zip"

    # Initialize size and status variables for both files
    $yesterdaySizeBytes = $null
    $todaySizeBytes = $null
    $status = "OK"
    $sizeChange = "N/A"

    try {
        # Get yesterday's file size
        $yesterdayFileInfo = Get-Item -Path $yesterdayFile -ErrorAction Stop
        $yesterdaySizeBytes = $yesterdayFileInfo.Length
    }
    catch {
        $yesterdaySizeBytes = "File Not Found"
        $status = "Yesterday's file not found"
    }

    try {
        # Get today's file size
        $todayFileInfo = Get-Item -Path $todayFile -ErrorAction Stop
        $todaySizeBytes = $todayFileInfo.Length
    }
    catch {
        $todaySizeBytes = "File Not Found"
        if ($status -eq "Yesterday's file not found") {
            $status = "Both files not found"
        } else {
            $status = "Today's file not found"
        }
    }

    # Calculate the change if both files are found
    if (($yesterdaySizeBytes -is [long]) -and ($todaySizeBytes -is [long])) {
        $change = $todaySizeBytes - $yesterdaySizeBytes
        if ($yesterdaySizeBytes -gt 0) {
            $percentageChange = [math]::Round(($change / $yesterdaySizeBytes) * 100, 2)
            $sizeChange = "$percentageChange %"
            if ($change -gt 0) {
                $status = "Increase ($sizeChange)"
            }
            elseif ($change -lt 0) {
                $status = "Decrease ($sizeChange)"
            }
            else {
                $status = "No Change"
                $sizeChange = "0.00 %"
            }
        }
        else {
            $status = "N/A (Yesterday's file size is 0)"
            $sizeChange = "N/A"
        }
    }
    
    # Add the result to the array
    $comparisonResults += [PSCustomObject]@{
        'Database' = $prefix
        'YesterdaySize(MB)' = if ($yesterdaySizeBytes -is [long]) { [math]::Round($yesterdaySizeBytes / 1MB, 2) } else { $yesterdaySizeBytes }
        'TodaySize(MB)' = if ($todaySizeBytes -is [long]) { [math]::Round($todaySizeBytes / 1MB, 2) } else { $todaySizeBytes }
        'Change(%)' = $sizeChange
        'Status' = $status
    }
}

# Output the results to the console in a clear table format
Write-Host "`n--- Comparison Report ---"
$comparisonResults | Format-Table -AutoSize

# Export the detailed report to a CSV file
$outputCsvFilename = "db_size_comparison_report_$today.csv"
try {
    $comparisonResults | Export-Csv -Path $outputCsvFilename -NoTypeInformation -Encoding UTF8
    Write-Host "`nDetailed report saved to '$outputCsvFilename'"
}
catch {
    Write-Host "`nError saving CSV file: $($_.Exception.Message)"
}
