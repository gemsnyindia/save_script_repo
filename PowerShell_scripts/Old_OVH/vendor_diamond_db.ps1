# MySQL connection details
$ConfigFile = "C:\ProgramData\MySQL\MySQL Server 8.0\my.ini"
$DB_NAME = "vendor_diamond_db"

# Backup & Log directory and file
$BACKUP_DIR = "G:\gemorderDB_backup"
$LOG_DIR = "G:\gemorderDB_backup\Logs"
$DATE_FORMAT = Get-Date -Format "yyyyMMdd"
$DATE_FORMAT_WITH_TIME = Get-Date -Format "yyyyMMdd_HHmmss"
$BACKUP_FILE = Join-Path $BACKUP_DIR "$DB_NAME`_$DATE_FORMAT.sql"
$ZIP_FILE = Join-Path $BACKUP_DIR "$DB_NAME`_$DATE_FORMAT.zip"
$LOG_FILE    = Join-Path $LOG_DIR "${DB_NAME}_$DATE_FORMAT_WITH_TIME.log"

# Ensure directories exist
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

# --- Archive Function ---
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Compress-File {
    param(
        [string]$sourceFile,
        [string]$destinationFile
    )

    if (Test-Path $destinationFile) {
        Remove-Item $destinationFile -Force
    }

    $zipFile = [System.IO.Compression.ZipFile]::Open($destinationFile, 'Create')
    try {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipFile, $sourceFile, [System.IO.Path]::GetFileName($sourceFile), [System.IO.Compression.CompressionLevel]::Optimal)
    } finally {
        $zipFile.Dispose()
    }
}

# --- File size function ---
function Get-ReadableSize {
    param([long]$bytes)
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    elseif ($bytes -ge 1MB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    elseif ($bytes -ge 1KB) { return "{0:N2} KB" -f ($bytes / 1KB) }
    else { return "$bytes Bytes" }
}

# --- Start Backup ---
Write-Log "Starting backup for database: $DB_NAME"


# Full mysqldump command (no XAMPP path needed)
$DumpCommand = "mysqldump --defaults-extra-file=`"$ConfigFile`" --defaults-group-suffix=oldovh $DB_NAME --routines --events --triggers --max_allowed_packet=1G --single-transaction --quick --lock-tables=false"

# Run mysqldump
try {
    cmd.exe /c $DumpCommand > "$BACKUP_FILE"
    if ($LASTEXITCODE -ne 0) {
        Write-Log "mysqldump failed with exit code $LASTEXITCODE"
        exit 1
    }
    Write-Log "mysqldump finished: $BACKUP_FILE"
} catch {
    Write-Log "Error running mysqldump: $_"
    exit 1
}

# --- Ensure file is released ---
$maxRetries = 5
$retry = 0
while ($retry -lt $maxRetries) {
    try {
        $stream = [System.IO.File]::Open($BACKUP_FILE, 'Open', 'Read', 'None')
        $stream.Close()
        break
    } catch {
        Write-Log "Backup file still locked... retrying ($retry/$maxRetries)"
        Start-Sleep -Seconds 2
        $retry++
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
            Write-Log "Backup compressed to: $ZIP_FILE"

            # log zip size too
            $ZipInfo = Get-Item $ZIP_FILE
            Write-Log "Compressed file size: $(Get-ReadableSize $ZipInfo.Length)"

            Remove-Item $BACKUP_FILE -Force
            Write-Log "Original SQL removed: $BACKUP_FILE"
        } catch {
            Write-Log "Error compressing/removing file: $_"
	    exit 1
        }
    } else {
        Write-Log "Backup file is empty (0 KB). Removing file."
        Remove-Item $BACKUP_FILE -Force
    }
} else {
    Write-Log "Backup file not created: $BACKUP_FILE"
}

Write-Log "Backup job completed."
