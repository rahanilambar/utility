## `rename_unique_hash_script.ps1`

It is a PowerShell script designed to rename Image and Video format files based on the "Date Taken" / "Media Created" timestamp. It supports common image (`.jpg`, `.jpeg`, `.png`, `.heic`, `.dng`, `.raw`, `.bmp`, `.tif`, `.tiff`, `.cr2`, `.nef`, `.arw`) and video (`.mov`, `.mp4`, `.m4v`, `.3gp`, `.avi`, `.mkv`, `.wmv`) formats.

If "Date Taken" / "Media Created" is not found or cannot be retrieved from metadata, it renames the file based on "Date Modified".  
If a file is already renamed in this particular format, it skips the rename operation for that file.

#### Rename format

- **Image:** `IMG_YYYYMMDDHHmmss_xxxx.EXTENSION`
- **Video:** `VID_YYYYMMDDHHmmss_xxxx.EXTENSION`

> **Note:** `xxxx` signifies a 4-character SHA hash.
