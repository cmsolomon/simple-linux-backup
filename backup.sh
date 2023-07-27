#!/bin/bash
set -e # Exit on first error

# Backup Manager
# Will maintain the specified number of backups.
# If there are too many backups, the oldest will be deleted.
# If there are fewer backups than specified a new backup will be made (this takes longer as all data has to be archived).
# If there are the specified number of backups, the oldest will be updated (incremental update only has to copy the changes, so is faster).
# The backup in progress has a special "work in progress" name. If a backup is found with this name, that backup will be assumed to be
# the oldest and will be resumed (unless there are too many)
# The work in progress backup will be renamed to the backup prefix + the epoch timestamp in seconds.

# NOTE: If the BACKUP_PREFIX doesn't contain the $USER, then data can be lost if multiple users use the backup manager

# Configuration Section
readonly MAX_BACKUPS=3
readonly BACKUP_PREFIX="backup/"$USER"/"
readonly COMPRESS_DATA_DURING_TRANSFER="false"

readonly FOLDER_TO_BACKUP=$HOME

# Add patterns for files or folders to exclude to this list, e.g.
# readonly EXCLUSION_LIST=(
#     "$FOLDER_TO_BACKUP/folder_to_exclude/"
#     "$FOLDER_TO_BACKUP/file_to_exclude"
#)
readonly EXCLUSION_LIST=()

# Constants - change them and it's your responsibility to ensure nothing breaks :) 
readonly BACKUP_IN_PROGRESS="$BACKUP_PREFIX""WIP"
readonly RSYNC_VANISHED_FILE_EXIT=24

# *****************************************************************************

echo Backup Manager running...

# Check if backup WIP exists
backupInProgress="false"
if [ -d "$BACKUP_IN_PROGRESS" ]; then
    backupInProgress="true"
fi

# Find backup folders
declare -a bups=()
for backup in "$BACKUP_PREFIX"*/; do
    bups+=("$backup")
done
backups=($(echo ${bups[*]}| tr " " "\n" | sort -n))

if [ "$backupInProgress" == "true" ]; then
    # If there are too many backups, remove the WIP backup as that will be the oldest
    if [ "${#backups[@]}" -gt "$MAX_BACKUPS" ]; then
        printf "Removing previous WIP backup, as there are more backups (%s) than defined number (%s)...\n\r" ${#backups[@]} $MAX_BACKUPS 
        rm -rf "$BACKUP_IN_PROGRESS"
        # The wip backup dir is always last
        unset 'backups[-1]'
        backupInProgress="false"
    else
        echo Resuming previously interrupted backup...
    fi
fi

# If number of backup folders is greater than number of backups to maintain, remove oldest until within limits
while [ "${#backups[@]}" -gt "$MAX_BACKUPS" ]; do
    printf "Removing old backup %s as there are more backups (%s) than the defined number (%s)...\n\r" ${backups[0]} ${#backups[@]} $MAX_BACKUPS
    rm -rf "${backup[0]}"
    unset 'backups[0]'
done

# Now we have to get the WIP directory ready - if there is a backup in progress we can skip this part
if [ "$backupInProgress" == "false" ]; then
    # If we have the maximum number of backups allowable, rename the oldest to WIP
    if [ "${#backups[@]}" -eq "$MAX_BACKUPS" ]; then
        echo Renaming ${backups[0]} to $BACKUP_IN_PROGRESS...
        mv ${backups[0]} "$BACKUP_IN_PROGRESS"
    else
        # Else create the new backup folder
        printf "Defined number of backups (%s) not reached (only have %s backups), creating new backup...\n\r" $MAX_BACKUPS ${#backups[@]}
        mkdir -p "$BACKUP_IN_PROGRESS"
    fi
fi

# Now set up the Flags to use for the backup

# Default Flags:
# h - human readable sizes (KB, MG, GB), rather than everything in bytes.
# u - update
# a - Archive, implying:
#                      recusive (r),
#                      copy simlinks (l),
#                      preserve permissions (p),
#                      preserve modification times (t),
#                      preserve group (g),
#                      preserve owner (o),
#                      preserve special device files and special files (D)
# --no-inc-recursive - disable incremental recursion (calculate whole changeset before starting, not one dir at a time) - improves progress percentage accuracy. 
# --delete - delete files that are missing from the destination on update
# --force  - delete non-empty directories, if they are missing from destination on update
# --info=progress2 - display the new overall progress indicator
# --ignore-missing-args - do not fail on files that have vanished between the file list being created and the copy operation
# --delete-excluded - remove any thing that has previously been copied to the destination that now matches the excluded list
FLAGS="-hua --no-inc-recursive --delete --force --info=progress2 --ignore-missing-args --delete-excluded"

# Optionally enable compression during transport
if [ "$COMPRESS_DATA_DURING_TRANSFER" = "true" ]; then
    FLAGS+=" --compress"
fi

# Add the exclusions (if any)
for EXCLUDED_ITEM in "${EXCLUSION_LIST[@]}"; do
    FLAGS+=" --exclude=\"${EXCLUDED_ITEM}\""
done

# Now finally run the backup into the WIP directory
echo Running backup...
result=0
rsync $FLAGS $FOLDER_TO_BACKUP/ $BACKUP_IN_PROGRESS || result=$?

# Ignore the vanished file error, but fail with error on any other error
if [ $result != 0 ] && [ $result != $RSYNC_VANISHED_FILE_EXIT ]; then
    printf "rsync exited with error code %d - backup failed\n" $result
    exit $result
fi

# Finally rename the WIP folder to using the epoch timestamp
readonly newBackupName="$BACKUP_PREFIX""$(date +%s)"
echo Renaming "$BACKUP_IN_PROGRESS" to "$newBackupName"...
mv "$BACKUP_IN_PROGRESS" "$newBackupName"

# Ensure the modification time is updated to match the timestamp in the name (for easy human reading)
touch "$newBackupName"

echo Backup complete.
