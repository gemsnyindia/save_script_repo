# Folder to clean
$BackupDir = "G:\gemorderDB_backup"

# Get today's date
$Today = Get-Date

# List all .sql files in the backup directory
$Files = Get-ChildItem -Path $BackupDir -Filter "*.sql" | Where-Object { -not $_.PSIsContainer }

foreach ($File in $Files) {
    $FileDate = $File.CreationTime.Date
    $FormattedDate = $FileDate.ToString("yyyy-MM-dd")

    # Condition 1: File is older than 15 days
    $OlderThan15Days = ($Today - $FileDate).Days -gt 15

    # Condition 2: File is NOT from 1st of any month
    $NotFirstOfMonth = $FileDate.Day -ne 1

    if ($OlderThan15Days -and $NotFirstOfMonth) {
        Write-Host "Deleting: $($File.FullName) | Created: $FormattedDate"
        Remove-Item -Path $File.FullName -Force
    } else {
        Write-Host "Keeping:  $($File.FullName) | Created: $FormattedDate"
    }
}
