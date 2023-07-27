# simple-linux-backup
Simple script to create backups of your files in linux.

## Why does this exist
There are lots of backup products out there, so why did I write this script?
I made this because I am too lazy to wade through the instructions on the more fully featured products out there.
On a more serious note, most other packages do things like store the backups compressed (not really required since storage is so cheap), or use hardlinks so you only end up with one copy of a file to save space (which means is anything alters that file all backups are impacted, and not necessary, since storage is cheap).

## Prerequisites 
bash, rsync, tr, sort
Should be pre-installed, or simply installable, for most distros.


## What it does
This backup script is essentially a simple backup manager, where the backups are created using rsync.
It creates uncompressed copies of the files in the selected directory (recursively), into a timestamp named backup folder.
The script manages rotation of an arbitrary number of backups, updating the oldest.
If the backup is interrupted (unexpected reset, crash or whatever) it will resume the incomplete backup (rather than moving on to the next oldest).

The backups are uncompressed copies, so there is no 'restore' option - if you want to get a file back that you've lost, just get it from the backup folder.

This can be set up to run on a schedule using cron or a systemd timer, but this is left as an exercise for the user.

## Configuration
### MAX_BACKUPS
You can configure the number of backups you want to maintain. If you specify 4 and you run the backup once per week, you will have 1 month of backups (but it will require 4 times the size of one backup).

### BACKUP_PREFIX
You can specify where the backup folders should be stored. You can specify a different location to the media that's hosting the script.
If the BACKUP_PREFIX doesn't contain $USER and more than one user runs the backup script (e.g. several people using the same removable drive) then backups will be lost because only MAX_BACKUPS will be maintained.
If you do include $USER, then each user will have MAX_BACKUPS separately.

### COMPRESS_DATA_DURING_TRANSFER
If you are backing up over a network, e.g. to a NAS, enabling compression during the transfer will speed things up as the network traffic will be reduced.
Do not enable for local backups (e.g. to an external drive) as this will pointlessly compress then copy then decompress, hence slower and with higher CPU usage.

### FOLDER_TO_BACKUP
You can specify the folder to backup. By default, the $USERs home directory.

### EXCLUSION_LIST
This is a list of patterns for files or folders to exclude from the backup.
Should include the folder to backup as the root, e.g.
```sh
readonly EXCLUSION_LIST=(
    "$FOLDER_TO_BACKUP/folder_to_exclude/"
    "$FOLDER_TO_BACKUP/file_to_exclude"
)
```

## How to use it
### Quickstart
Copy the backup.sh script to the partition you want to backup to.
Run the script
./backup.sh
A backup of your whole home directory will be made on the drive you ran the script on.
(Don't run it in a folder in your home director, or things could get interesting.)

