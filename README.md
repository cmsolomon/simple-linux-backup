# simple-linux-backup
Simple script to create backups of your files in linux.

## Why does this exist
There are lots of backup products out there, so why did I write this script?
I made this because I am too lazy to wade through the instructions on the more fully featured products out there.

## Prerequisites 
bash, rsync, tr, sort
Should be preinstalled, or simply installable, for most distros.


## What it does
This backup script creates uncompressed copies of the files in the selected directory (recursively), into a timestamp named backup folder.
The script manages rotation of an arbitrary number of backups, updating the oldest.
If the backup is interrupted (unexpected reset, crash or whatever) it will resume the incomplete backup (rather than moving on to the next oldest).

The backups are uncompressed copies, so there is no 'restore' option - if you want to get a file back that you've lost, just get it from the backup folder.

## Configuration
### MAX_BACKUPS
You can configure the number of backups you want to maintain. If you specify 4 and you run the backup once per week, you will have 1 month of backups (but it will require 4 times the size of one backup).

### BACKUP_PREFIX
You can specify where the backup folders should be stored. You can specify a different location to the media that's hosting the script.
If the BACKUP_PREFIX doesn't contain $USER and more than one user runs the backup script (e.g. several people using the same removable drive) then backups will be lost because only MAX_BACKUPS will be maintained.
If you do include $USER, then each user will have MAX_BACKUPS seperately.

### FOLDER_TO_BACKUP
You can specify the folder to backup. By default, the $USERs home directory.

### COMPRESS_DATA_DURING_TRANSFER
If you are backing up over a network, e.g. to a NAS, enabling compression during the transfer will speed things up as the network traffic will be reduced.
Do not enable for local backups (e.g. to an external drive) as this will pointlessly compress then copy then decompress, hence slower and with higher CPU usage.

## How to use it
### Quickstart
Copy the backup.sh script to the partition you want to backup to.
Run the script
./backup.sh
A backup of your whole home directory will be made on the drive you ran the script on.
(Don't run it in a folder in your home director, or things could get interesting.)

