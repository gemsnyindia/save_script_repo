# ==============================
# Gemsny AWS MySQL Backup Script
# ==============================
# Author   : Rajeev Sharma / Gemsny
# Date     : 2025-09-15
# Version  : 2.0
# Purpose  : Automates MySQL backup using mysqldump
# ==============================

# --- MySQL connection details ---
$ConfigFile = "C:\ProgramData\MySQL\MySQL Server 8.0\my.ini"
$DB_NAME    = "db139222657"

# --- Backup directory and file paths ---
$BACKUP_DIR = "G:\gemorderDB_backup"
$LOG_DIR    = "G:\gemorderDB_backup\Logs"

$DATE_FORMAT = Get-Date -Format "yyyyMMdd"
$DATE_FORMAT_WITH_TIME = Get-Date -Format "yyyyMMdd_HHmmss"

$BACKUP_FILE = Join-Path $BACKUP_DIR "AWS_${DB_NAME}_$DATE_FORMAT.sql"
$ZIP_FILE    = Join-Path $BACKUP_DIR "AWS_${DB_NAME}_$DATE_FORMAT.zip"
$LOG_FILE    = Join-Path $LOG_DIR "AWS_${DB_NAME}_$DATE_FORMAT_WITH_TIME.log"

# --- Ensure directories exist ---
foreach ($dir in @($BACKUP_DIR, $LOG_DIR)) {
    if (!(Test-Path -Path $dir)) {
        New-Item -Path $dir -ItemType Directory | Out-Null
    }
}

# --- Logging function ---
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Write-Host $logEntry
    Add-Content -Path $LOG_FILE -Value $logEntry
}

# --- Compression function ---
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Compress-File {
    param([string]$sourceFile, [string]$destinationFile)

    if (Test-Path $destinationFile) {
        Remove-Item $destinationFile -Force
    }

    $zipFile = [System.IO.Compression.ZipFile]::Open($destinationFile, 'Create')
    try {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zipFile,
            $sourceFile,
            [System.IO.Path]::GetFileName($sourceFile),
            [System.IO.Compression.CompressionLevel]::Optimal
        )
    } finally {
        $zipFile.Dispose()
    }
}

# --- File size helper ---
function Get-ReadableSize {
    param([long]$bytes)
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    elseif ($bytes -ge 1MB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    elseif ($bytes -ge 1KB) { return "{0:N2} KB" -f ($bytes / 1KB) }
    else { return "$bytes Bytes" }
}

# --- Start Backup ---
Write-Log "=============================="
Write-Log "Starting MySQL backup for DB: $DB_NAME"
Write-Log "Backup file: $BACKUP_FILE"
Write-Log "=============================="

# --- mysqldump command ---
# --- Build mysqldump arguments ---
$DumpArgs = @(
    "--defaults-extra-file=""$ConfigFile"""
    "--defaults-group-suffix=aws"
    "--single-transaction"
    "--quick"
    "--skip-lock-tables"
    "--no-tablespaces"
    "--flush-logs=FALSE"
    "--set-gtid-purged=OFF"
    "--routines"
    "--events"
    "--triggers"
    "--max_allowed_packet=1G"
    $DB_NAME
    "--ignore-table=$DB_NAME.remove_pair"
    "--ignore-table=$DB_NAME.meta_events"
    "--ignore-table=$DB_NAME.diamond_pairs"
    "--ignore-table=$DB_NAME.diamond_pairs_new"
    "--ignore-table=$DB_NAME.gems_item_L"
    "--ignore-table=$DB_NAME.gems_item_NB"
    "--ignore-table=$DB_NAME.gems_item_N"
    "--ignore-table=$DB_NAME.temp_diamond_img_url_cron"
    "--ignore-table=$DB_NAME.tmp_del_dmd"
)

try {
    $process = Start-Process -FilePath "mysqldump" `
                             -ArgumentList $DumpArgs `
                             -RedirectStandardOutput $BACKUP_FILE `
                             -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -ne 0) {
        Write-Log "❌ mysqldump failed with exit code $($process.ExitCode)"
        exit 1
    }
    Write-Log "✅ mysqldump completed successfully."
} catch {
    Write-Log "❌ Error executing mysqldump: $_"
    exit 1
}

# --- Wait until file is released ---
$maxRetries = 5
for ($retry = 1; $retry -le $maxRetries; $retry++) {
    try {
        $stream = [System.IO.File]::Open($BACKUP_FILE, 'Open', 'Read', 'None')
        $stream.Close()
        break
    } catch {
        Write-Log "⚠️ File lock detected... retrying ($retry/$maxRetries)"
        Start-Sleep -Seconds 2
    }
}

# --- Validate backup ---
if (Test-Path $BACKUP_FILE) {
    $FileInfo = Get-Item $BACKUP_FILE
    $sizeText = Get-ReadableSize $FileInfo.Length
    Write-Log "Backup file size: $sizeText"

    if ($FileInfo.Length -gt 0) {
        try {
            Compress-File -sourceFile $BACKUP_FILE -destinationFile $ZIP_FILE
            Write-Log "✅ Backup compressed to: $ZIP_FILE"

            $ZipInfo = Get-Item $ZIP_FILE
            Write-Log "Compressed file size: $(Get-ReadableSize $ZipInfo.Length)"

            Remove-Item $BACKUP_FILE -Force
            Write-Log "🗑️ Removed original SQL file: $BACKUP_FILE"
        } catch {
            Write-Log "❌ Compression failed: $_"
            exit 1
        }
    } else {
        Write-Log "❌ Backup file is empty (0 KB). Removing file."
        Remove-Item $BACKUP_FILE -Force
        exit 1
    }
} else {
    Write-Log "❌ Backup file not created: $BACKUP_FILE"
    exit 1
}

Write-Log "✅ Backup job completed successfully."
Write-Log "=============================="
