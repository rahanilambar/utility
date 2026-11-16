## `rename_unique_hash_script.ps1`

It is a PowerShell script designed to rename Image and Video format files based on the "Date Taken" / "Media Created" timestamp. It supports common image (`.jpg`, `.jpeg`, `.png`, `.heic`, `.dng`, `.raw`, `.bmp`, `.tif`, `.tiff`, `.cr2`, `.nef`, `.arw`) and video (`.mov`, `.mp4`, `.m4v`, `.3gp`, `.avi`, `.mkv`, `.wmv`) formats.

If "Date Taken" / "Media Created" is not found or cannot be retrieved from metadata, it renames the file based on "Date Modified".  
If a file is already renamed in this particular format, it skips the rename operation for that file.

#### Rename format

- **Image:** `IMG_YYYYMMDDHHmmss_xxxx.EXTENSION`
- **Video:** `VID_YYYYMMDDHHmmss_xxxx.EXTENSION`

> **Note:** `xxxx` represents the first 4 characters of the file's SHA-256 hash.

#### How to run (In Powershell)

### 1. No Path (Current Directory)

Processes all supported media files in the current working directory by default:

```powershell
powershell -ExecutionPolicy Bypass -File .\rename_unique_hash_script.ps1
```

### 2. Single Path

Processes all supported media files in one specified directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\rename_unique_hash_script.ps1 "C:\Users\YourName\Pictures\Vacation"
```

### 3. Multiple Paths

Processes multiple directories sequentially in a single run by passing space-separated paths:

```powershell
powershell -ExecutionPolicy Bypass -File .\rename_unique_hash_script.ps1 "C:\Photos\Trip 1" "D:\Videos\2026" ".\Subfolder"
```
