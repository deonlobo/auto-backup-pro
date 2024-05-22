#!/bin/bash
# Variabls to hold the file number counts
CBW24_COUNT=1
IB24_COUNT=1
DB24_COUNT=1

# Function to perform complete backup
perform_complete_backup() {
    # Set the function arguments passed accordingly
    local backup_prefix=$1
    local tar_location=$2
    local log_file=$3

    local timestamp=$(date +"%a %d %b %Y %r %Z")
    local return_val_ts=$(date +%s)
    local tar_file="${backup_prefix}-$CBW24_COUNT.tar"
    find "$HOME" -mindepth 1 -type f -not -path '*/.*/*' -not -path "$HOME/home/backup/*" -not \( -path "$PWD/backup.log" -a -type f \) -print0 |
    tar -czf "$tar_location/$tar_file" --null -T - --transform='s|.*/||'

    # Update the log file with appropriate message
    echo "$timestamp $tar_file was created" >> "$log_file"
    
    # Increment the file counter
    CBW24_COUNT=$((CBW24_COUNT + 1))
    # Return Timestamp of step 1
    echo "$return_val_ts $CBW24_COUNT"
}

# Function to perform incremental backup and differential backup
perform_conditional_backup() {
    local backup_prefix=$1
    local tar_location=$2
    local log_file=$3
    local base_ts=$4
    local file_count=$5
    local message=$6

    local timestamp=$(date +"%a %d %b %Y %r %Z")
    local return_val_ts=$(date +%s)
    local tar_file="${backup_prefix}-${file_count}.tar"

    # Find files to backup and store them in an array
    local files_to_backup=()
    while inputFS= read -r -d '' file; do
        files_to_backup+=("$file")
    done < <(find "$HOME" -mindepth 1 -type f -not -path '*/.*/*' -not -path "$HOME/home/backup/*" -not \( -path "$PWD/backup.log" -a -type f \) -newermt "@$base_ts" -print0)

    if [ ${#files_to_backup[@]} -eq 0 ]; then
        # If no files found, log appropriate message
        echo "$timestamp $message" >> "$log_file"
    else
        # If files found, create tar archive
        printf '%s\0' "${files_to_backup[@]}" | tar -czf "$tar_location/$tar_file" --null -T - --transform='s|.*/||'
        # Update the log file with appropriate message
        echo "$timestamp $tar_file was created" >> "$log_file"
        # Update the file counter based on incremental and differential backup
        if [[ $backup_prefix == "ibw24" ]]; then
            IB24_COUNT=$((IB24_COUNT + 1))
        elif [[ $backup_prefix == "dbw24" ]]; then
            DB24_COUNT=$((DB24_COUNT + 1))
        fi

    fi
    echo "$return_val_ts $IB24_COUNT $DB24_COUNT"
}


# Function to create backup directories if they don't exist
create_backup_directories() {
    local backup_dirs=("$1" "$2" "$3")

    for dir in "${backup_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
        fi
    done
}

# Create backup directories if they don't exist
create_backup_directories "$HOME/home/backup/cbw24" "$HOME/home/backup/ib24" "$HOME/home/backup/db24"


# Main loop
while true; do

    # STEP 1: Complete backup
    STEP1_RESULT=$(perform_complete_backup "cbw24" "$HOME/home/backup/cbw24" "backup.log")
    # The fist return value will be the timestamp of step 1
    STEP1_TS=$(echo "$STEP1_RESULT" | cut -d' ' -f1)
    # The second return value will be the counter value
    CBW24_COUNT=$(echo "$STEP1_RESULT" | cut -d' ' -f2)
    echo "Step 1 complete"
    # Sleep for 2 minutes
    sleep 120

    # STEP 2: Incremental backup after Step 1
    # Find files modified or created after the stored timestamp
    STEP2_RESULT=$(perform_conditional_backup "ibw24" "$HOME/home/backup/ib24" "backup.log" $STEP1_TS $IB24_COUNT "No changes - Incremental backup was not created")
    STEP2_TS=$(echo "$STEP2_RESULT" | cut -d' ' -f1)
    IB24_COUNT=$(echo "$STEP2_RESULT" | cut -d' ' -f2)
    echo "Step 2 complete"
    # Sleep for 2 minutes
    sleep 120

    # STEP 3: Incremental backup after Step 2
    STEP3_RESULT=$(perform_conditional_backup "ibw24" "$HOME/home/backup/ib24" "backup.log" $STEP2_TS $IB24_COUNT "No changes - Incremental backup was not created")
    STEP3_TS=$(echo "$STEP3_RESULT" | cut -d' ' -f1)
    IB24_COUNT=$(echo "$STEP3_RESULT" | cut -d' ' -f2)
    echo "Step 3 complete"
     # Sleep for 2 minutes
    sleep 120

    # STEP 4: Differential backup after Step 1
    STEP4_RESULT=$(perform_conditional_backup "dbw24" "$HOME/home/backup/db24" "backup.log" $STEP1_TS $DB24_COUNT "No changes - Differential backup was not created")
    STEP4_TS=$(echo "$STEP4_RESULT" | cut -d' ' -f1)
    DB24_COUNT=$(echo "$STEP4_RESULT" | cut -d' ' -f3)
    echo "Step 4 complete"
     # Sleep for 2 minutes
    sleep 120

    # STEP 5: Incremental backup after Step 4
    STEP5_RESULT=$(perform_conditional_backup "ibw24" "$HOME/home/backup/ib24" "backup.log" $STEP4_TS $IB24_COUNT "No changes - Incremental backup was not created")
    STEP5_TS=$(echo "$STEP5_RESULT" | cut -d' ' -f1)
    IB24_COUNT=$(echo "$STEP5_RESULT" | cut -d' ' -f2)
    echo "Step 5 complete"
done
