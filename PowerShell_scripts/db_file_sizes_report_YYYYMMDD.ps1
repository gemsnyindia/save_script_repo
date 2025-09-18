# Get today's date in YYYYMMDD format
$today = (Get-Date).ToString("yyyyMMdd")

# Define the base directory where the files are located
$basePath = "G:\gemorderDB_backup\"

# Define the list of file name prefixes
# The date and .sql extension will be appended dynamically
$baseFileNames = @(
    "diamond_pair_",
    "diamond_api_data_all_",
    "dev-node-db_",
    "diamond_api_data_",
    "gemsny_affordables_",
    "dbmigration_",
    "admin_app_db_",
    "db139222657_",
    "aff_developement_",
    "marketing_report_",
    "stone_tool_",
    "vendor_diamond_db_",
    "work_allot_",
    "stone_tool_dev_",
    "stone_video_",
    "uat-node-db_",
    "gemsny_",
    "jtool_",
    "NB_Diamonddb_",
    "etm_"
)

# Construct the full file paths with the dynamic date
$files = @()
foreach ($fileName in $baseFileNames) {
    $files += "$basePath$fileName$today.sql"
}

# Define the output CSV file name, including today's date
$outputCsvFilename = "db_file_sizes_report_$today.csv"

# Initialize an array to hold the results for CSV export
$resultsForCsv = @()

Write-Host "Checking file sizes for today's date ($today) in $basePath..."
Write-Host "-------------------------------------------------------------------"

foreach ($file in $files) {
    $fileStatus = ""
    $sizeBytes = $null
    $sizeKB = $null
    $sizeMB = $null
    $sizeGB = $null

    try {
        # Get-Item retrieves file information. -ErrorAction Stop ensures exceptions are thrown.
        $fileInfo = Get-Item -Path $file -ErrorAction Stop
        $sizeBytes = $fileInfo.Length

        # Calculate sizes in KB, MB, GB
        $sizeKB = [math]::Round($sizeBytes / 1KB, 2)
        $sizeMB = [math]::Round($sizeBytes / 1MB, 2)
        $sizeGB = [math]::Round($sizeBytes / 1GB, 2)

        $fileStatus = "OK"
        Write-Host "'$file': $($sizeKB) KB ($($sizeMB) MB, $($sizeGB) GB)"
    }
    catch [System.IO.FileNotFoundException] {
        $fileStatus = "File not found."
        Write-Host "'$file': File not found."
    }
    catch {
        # Catch any other specific or general errors
        $fileStatus = "An error occurred: $($_.Exception.Message)"
        Write-Host "'$file': An error occurred - $($_.Exception.Message)"
    }

    # Create a custom object for each file's data and add to the results array
    $resultsForCsv += [PSCustomObject]@{
        'File Path' = $file
        'Size (Bytes)' = $sizeBytes
        'Size (KB)' = $sizeKB
        'Size (MB)' = $sizeMB
        'Size (GB)' = $sizeGB
        'Status/Error' = $fileStatus
    }
}

Write-Host "`n--- Summary ---"
# Output summary to console for quick review
foreach ($item in $resultsForCsv) {
    if ($item.'Status/Error' -eq "OK") {
        Write-Host "'$($item.'File Path')': $($item.'Size (KB)') KB"
    } else {
        Write-Host "'$($item.'File Path')': $($item.'Status/Error')"
    }
}

# Export the results to a CSV file
try {
    $resultsForCsv | Export-Csv -Path $outputCsvFilename -NoTypeInformation -Encoding UTF8
    Write-Host "`nResults saved to '$outputCsvFilename'"
}
catch {
    Write-Host "`nError saving CSV file: $($_.Exception.Message)"
}
