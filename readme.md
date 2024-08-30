# BackupAutomator24

## Overview

BackupAutomator24 is a bash script designed for continuous backup automation on a Linux server. The script, `backup24.sh`, performs regular full, incremental, and differential backups for specified file types, ensuring that all changes within the user's home directory are securely stored and logged.

### Features
- **Continuous Backup**: The script runs in the background, performing backups at regular intervals.
- **Full Backup**: Creates a complete tar archive of specified file types.
- **Incremental Backup**: Captures only the files that were created or modified since the last backup.
- **Differential Backup**: Captures files modified since the last full backup.
- **Logging**: Detailed logging of all backup operations, including timestamps and file names.

### Project Structure
- **`backup24.sh`**: The main bash script that performs all backup operations.
- **`backup.log`**: A log file that tracks all backup activities, including timestamps and the names of created tar files.

### Usage

#### Command Syntax
```bash
backup24.sh [file_type_1] [file_type_2] [file_type_3]
```
- **file_type_1, file_type_2, file_type_3**: Optional arguments specifying the file types to back up. If no arguments are provided, all file types are considered.

#### Examples
- Backup `.c`, `.txt`, and `.pdf` files:
  ```bash
  ./backup24.sh .c .txt .pdf
  ```
- Backup all file types:
  ```bash
  ./backup24.sh
  ```

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/BackupAutomator24.git
   cd BackupAutomator24
   ```

2. **Make the script executable**:
   ```bash
   chmod +x backup24.sh
   ```

3. **Run the script**:
   ```bash
   ./backup24.sh [file_type_1] [file_type_2] [file_type_3]
   ```

### Logging

The script maintains a detailed log file (`backup.log`) which records every backup operation. The log entries include:
- Timestamp of the operation
- Type of backup performed (full, incremental, differential)
- Name of the tar file created (if any)

### Acknowledgments
Developed as part of the COMP 8567 course, Summer 2024.
