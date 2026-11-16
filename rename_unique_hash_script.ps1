param (
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Paths
)

# Fallback to the current working directory if no paths were passed
if (-not $Paths -or $Paths.Count -eq 0) {
    $Paths = @((Get-Location).Path)
}

$shell = New-Object -ComObject Shell.Application
$imageExtensions = @('.jpg', '.jpeg', '.png', '.heic', '.dng', '.raw', '.bmp', '.tif', '.tiff', '.cr2', '.nef', '.arw')
$videoExtensions = @('.mov', '.mp4', '.m4v', '.3gp', '.avi', '.mkv', '.wmv')

foreach ($rawPath in $Paths) {
    if (-not (Test-Path -LiteralPath $rawPath -PathType Container)) {
        Write-Warning "Folder not found or is not a directory, skipping: '$rawPath'"
        continue
    }

    $targetDir = (Resolve-Path -LiteralPath $rawPath).Path
    $folder = $shell.Namespace($targetDir)

    if ($null -eq $folder) {
        Write-Warning "Could not access Shell namespace for folder, skipping: '$targetDir'"
        continue
    }

    # Dynamically locate property indices for both Photos and Videos
    $dateTakenIdx = $null
    $mediaCreatedIdx = $null

    for ($i = 0; $i -le 320; $i++) {
        $header = $folder.GetDetailsOf($null, $i)
        if ($header -eq 'Date taken' -or $header -match 'Date taken') {
            $dateTakenIdx = $i
        }
        if ($header -eq 'Media created' -or $header -match 'Media created') {
            $mediaCreatedIdx = $i
        }
    }

    if ($null -eq $dateTakenIdx) { $dateTakenIdx = 12 }
    if ($null -eq $mediaCreatedIdx) { $mediaCreatedIdx = 208 }

    Write-Host "`nScanning directory: $targetDir" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------"

    # Snapshot the directory file list with @(...) before renaming to prevent double-looping
    @(Get-ChildItem -LiteralPath $targetDir -File) | ForEach-Object {
        $file = $_
        $fileName = $file.Name
        $baseName = $file.BaseName
        $origExt = $file.Extension
        $extLower = $origExt.ToLower()

        # Determine prefix (skip unsupported file extensions)
        $prefix = $null
        if ($imageExtensions -contains $extLower) {
            $prefix = "IMG_"
        } elseif ($videoExtensions -contains $extLower) {
            $prefix = "VID_"
        } else {
            return
        }

        # 1. Skip if already formatted as IMG_YYYYMMDDHHmmss_xxxx or VID_YYYYMMDDHHmmss_xxxx
        if ($baseName -match "^${prefix}\d{14}_[a-f0-9]{4}(_\d+)?$") {
            Write-Host "Skipped (Already renamed): '$fileName'" -ForegroundColor DarkGray
            return
        }

        $item = $folder.ParseName($fileName)
        $ts = $null
        $sourceTag = ""

        # 2A. Try embedded metadata first ("Media created" for videos, "Date taken" for photos)
        if ($item) {
            $raw = ""

            if (($videoExtensions -contains $extLower) -and ($null -ne $mediaCreatedIdx)) {
                $raw = $folder.GetDetailsOf($item, $mediaCreatedIdx)
                if (-not [string]::IsNullOrWhiteSpace($raw)) { $sourceTag = "Media created" }
            }

            if ([string]::IsNullOrWhiteSpace($raw) -and ($null -ne $dateTakenIdx)) {
                $raw = $folder.GetDetailsOf($item, $dateTakenIdx)
                if (-not [string]::IsNullOrWhiteSpace($raw)) { $sourceTag = "Date taken" }
            }

            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $cleanDate = ($raw -replace '[\u200E\u200F\u202A-\u202E\u00A0]', '').Trim()
                [DateTime]$parsedDate = [DateTime]::MinValue
                if ([DateTime]::TryParse($cleanDate, [ref]$parsedDate)) {
                    $ts = $parsedDate.ToString("yyyyMMddHHmmss")
                }
            }
        }

        # 2B. Fallback to "Date modified" if embedded metadata is unavailable
        if ([string]::IsNullOrEmpty($ts)) {
            if ($null -ne $file.LastWriteTime -and $file.LastWriteTime -gt [DateTime]::MinValue) {
                $ts = $file.LastWriteTime.ToString("yyyyMMddHHmmss")
                $sourceTag = "Date modified"
            }
        }

        # 3. Strict rename: Only rename if a valid 14-digit timestamp was obtained
        if ($ts -and ($ts -match '^\d{14}$')) {
            $shortHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.Substring(0, 4).ToLower()
            $targetBase = "${prefix}${ts}_${shortHash}"
            $newName = "${targetBase}${origExt}"
            $targetPath = Join-Path $targetDir $newName

            # Safety fallback in case of hash collision or exact duplicate file
            if (Test-Path -LiteralPath $targetPath) {
                $count = 1
                while (Test-Path -LiteralPath $targetPath) {
                    $newName = "${targetBase}_${count}${origExt}"
                    $targetPath = Join-Path $targetDir $newName
                    $count++
                }
            }

            Write-Host "Renamed [$sourceTag]: '$fileName' -> '$newName'" -ForegroundColor Green
            Rename-Item -LiteralPath $file.FullName -NewName $newName
        } else {
            Write-Host "Skipped (No valid date metadata): '$fileName'" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n----------------------------------------------------"
Write-Host "All media processing complete." -ForegroundColor Cyan