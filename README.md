# AutoBackupPro

## Overview

`AutoBackupPro` is a Bash script designed to run continuously in the background, performing automated backups of files within the `/home/username` directory. The script creates complete, incremental, and differential backups at specified intervals, ensuring that all changes to files are regularly saved.

## Features

- **Complete Backup**: Creates a complete backup of all files in the `/home/username` directory tree.
- **Incremental Backup**: Creates incremental backups of files that have been newly created or modified since the last backup.
- **Differential Backup**: Creates differential backups of files that have been newly created or modified since the last complete backup.
- **Logging**: Maintains a log file (`backup.log`) with timestamps and names of the created backup files.

## Backup Naming Conventions

The backup files are named according to the following pattern:

- Complete Backup: `cbw24-<sequence>.tar`
- Incremental Backup: `ibw24-<sequence>.tar`
- Differential Backup: `dbw24-<sequence>.tar`

The sequence number increments with each backup cycle.

## Backup Schedule

The script performs backups in a continuous loop with 2-minute intervals between each step:

1. Complete backup.
2. Incremental backup since the complete backup.
3. Incremental backup since the last incremental backup.
4. Differential backup since the complete backup.
5. Incremental backup since the last differential backup.
6. Repeat from step 1.

## Log Format

The log file records entries in the following format:
