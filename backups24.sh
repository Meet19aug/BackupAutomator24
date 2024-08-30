#!/bin/bash
# backup24.sh can have 0-3 arguments
num_of_args=$#
if [ $num_of_args -lt 0 ]|| [ $num_of_args -gt 3 ]; then
    echo "Can have between 0-3 arguments."
    exit 0
fi

my_home="/home/patel4p9"
complete_backup_dir=$my_home"/home/backup/cbup24s"
incremental_backup_dir=$my_home"/home/backup/ibup24s"
differential_backup_dir=$my_home"/home/backup/dbup24s/"
logfile=$my_home"/home/backup/backups.log"  
last_backup_file="$my_home/home/backup/last_backup_time"
outputbackup_dir="$my_home/home/outputbackup"

# Create directories for backup and log file
mkdir -p "$complete_backup_dir"
mkdir -p "$incremental_backup_dir"
mkdir -p "$differential_backup_dir"
mkdir -p "$outputbackup_dir"
mkdir -p "$(dirname "$logfile")"
touch $logfile

touch $outputbackup_dir/output.log
touch $outputbackup_dir/error.log

# Redirect stdout to output.log and stderr to error.log
exec 1>$outputbackup_dir/output.log
exec 2>$outputbackup_dir/error.log

get_formatted_timestamp() {
    date +"%a %d %b %Y %I:%M:%S %p %Z"
}

# Function to generate the archive filename based on a counter and prefix
generate_filename() {
    local prefix="$1"
    local counter=1
    local target_dir=""
    
    # Determine the target directory based on the prefix
    case "$prefix" in
        "cbup24s-")
            target_dir="$complete_backup_dir"
            ;;
        "ibup24s-")
            target_dir="$incremental_backup_dir"
            ;;
        "dbup24s-")
            target_dir="$differential_backup_dir"
            ;;
        *)
            echo "Error: Invalid prefix."
            exit 1
            ;;
    esac
    
    # Generate the filename by checking if the file exists
    while [ -f "$target_dir/$prefix$counter.tar" ]; do
        counter=$((counter + 1))
    done
    echo "$prefix$counter.tar"
}

complete_backup() {

    search_dir="/home/patel4p9"
    filename=$(generate_filename "cbup24s-")
    if [ $# -eq 0 ]; then
        echo all files will be taken to consider.
    elif [ $# -eq 1 ]; then
        find_args="\( -name \"*$1\" \)"
    elif [ $# -eq 2 ]; then
        find_args="\( -name \"*$1\" -o -name \"*$2\" \)"
    elif [ $# -eq 3 ]; then
        find_args="\( -name \"*$1\" -o -name \"*$2\" -o -name \"*$3\" \)"
    else
        echo "Error: Maximum 3 arguments are allowed."
        exit 1
    fi

    echo find_args is $find_args

    find_command="find $search_dir $find_args -type f "
    # Display the constructed command for debugging purposes
    echo "Running: $find_command"

    # Execute the find command and capture its output
    find_output=$(eval "$find_command")
    timestamp=$(get_formatted_timestamp)

    # Display the constructed command for debugging purposes
    echo "Running: $find_command | tar -cvpf $complete_backup_dir/$filename -T -"

    # Execute the find command and pipe it to tar
    eval "$find_command" | tar -cvpf "$complete_backup_dir/$filename" -T -

    # Save the current timestamp after a successful complete backup
    date +"%Y-%m-%d %H:%M:%S" > "$complete_backup_dir/last_complete_backup_time.txt"
    
    #echo "Backup created at: $complete_backup_dir/$filename" >> $logfile
    echo "$timestamp - Complete backup created: $filename" >> "$logfile"   
}

incremental_backup() {
    search_dir="/home/patel4p9"
    filename=$(generate_filename "ibup24s-")
    
    # Determine if this is the final incremental backup based on differential backup
    if [ $flag = true ]; then
        # Use the last differential backup timestamp
        if [ -f "$differential_backup_dir/last_differential_backup_time.txt" ]; then
            last_backup_time=$(cat "$differential_backup_dir/last_differential_backup_time.txt")
            echo last_backup_time is : $last_backup_time.
        else
            echo "No previous differential backup found. Exiting."
            return
        fi
    else
        # Use the last incremental or complete backup timestamp
        if [ -f "$incremental_backup_dir/last_incremental_backup_time.txt" ]; then
            last_backup_time=$(cat "$incremental_backup_dir/last_incremental_backup_time.txt")
        elif [ -f "$complete_backup_dir/last_complete_backup_time.txt" ]; then
            last_backup_time=$(cat "$complete_backup_dir/last_complete_backup_time.txt")
        else
            echo "No previous backups found. Starting fresh."
            last_backup_time=""
        fi
    fi
    echo last_backup_time: out: $last_backup_time.
    # Determine the find arguments based on input
    if [ $# -eq 0 ]; then
        echo "All files modified since the last backup will be considered."
        find_args="-name \"*\""
    elif [ $# -eq 1 ]; then
        find_args="\( -name \"*$1\" \)"
    elif [ $# -eq 2 ]; then
        find_args="\( -name \"*$1\" -o -name \"*$2\" \)"
    elif [ $# -eq 3 ]; then
        find_args="\( -name \"*$1\" -o -name \"*$2\" -o -name \"*$3\" \)"
    else
        echo "Error: Maximum 3 arguments are allowed."
        exit 1
    fi
    
    # Construct the find command
    if [ -n "$last_backup_time" ]; then
        find_command="find $search_dir $find_args -type f -newermt \"$last_backup_time\""
    else
        find_command="find $search_dir $find_args -type f "
    fi

    # Display the constructed command for debugging purposes
    echo "Running: $find_command"
    timestamp=$(get_formatted_timestamp)
    # Execute the find command and capture its output
    find_output=$(eval "$find_command")

    # Check if the find command returned any files
    if [ -z "$find_output" ]; then
        echo "$timestamp - No changes - Incremental backup was not created." >> $logfile
        # Save the current timestamp after a successful complete backup
        date +"%Y-%m-%d %H:%M:%S" > "$incremental_backup_dir/last_incremental_backup_time.txt"
    else
        # If files were found, create the tar archive
        echo "$find_output" | tar -cvpf "$incremental_backup_dir/$filename" -T -
        
         # Execute the find command and pipe it to tar
        eval "$find_command" | tar -cvpf "$incremental_backup_dir/$filename" -T -

        # Save the current timestamp after a successful incremental backup
        date +"%Y-%m-%d %H:%M:%S" > "$incremental_backup_dir/last_incremental_backup_time.txt"
        
        echo "$timestamp - Incremental backup created: $filename" >> "$logfile"
    fi
}

differential_backup() {
    search_dir="/home/patel4p9"
    filename=$(generate_filename "dbup24s-")
    
    # Check for the last complete backup time
    if [ -f "$complete_backup_dir/last_complete_backup_time.txt" ]; then
        last_backup_time=$(cat "$complete_backup_dir/last_complete_backup_time.txt")
    else
        echo "No complete backup found. Cannot create differential backup."
        exit 1
    fi
    
    # Determine the find arguments based on input
    if [ $# -eq 0 ]; then
        echo "All files modified since the last complete backup will be considered."
        find_args="-name \"*\""
    elif [ $# -eq 1 ]; then
        find_args="\( -name \"*$1\" \)"
    elif [ $# -eq 2 ]; then
        find_args="\( -name \"*$1\" -o -name \"*$2\" \)"
    elif [ $# -eq 3 ]; then
        find_args="\( -name \"*$1\" -o -name \"*$2\" -o -name \"*$3\" \)"
    else
        echo "Error: Maximum 3 arguments are allowed."
        exit 1
    fi
    timestamp=$(get_formatted_timestamp)
    # Construct the find command with the last complete backup time
    find_command="find $search_dir $find_args -type f -newermt \"$last_backup_time\""
    
    # Display the constructed command for debugging purposes
    echo "Running: $find_command"
    
    # Execute the find command and capture its output
    find_output=$(eval "$find_command")
    
    # Check if the find command returned any files
    if [ -z "$find_output" ]; then
        echo "$timestamp - No changes - Differential backup was not created." >> "$logfile"
        # Save the current timestamp after a successful complete backup
        date +"%Y-%m-%d %H:%M:%S" > "$differential_backup_dir/last_differential_backup_time.txt"
    else
        # If files were found, create the tar archive
        eval "$find_command" | tar -cvpf "$differential_backup_dir/$filename" -T -
        
        # Save the current timestamp after a successful differential backup
        date +"%Y-%m-%d %H:%M:%S" > "$differential_backup_dir/last_differential_backup_time.txt"
        
        # echo "Differential backup created at: $differential_backup_dir/$filename" >> "$logfile"
        echo "$timestamp - Differential backup created: $filename" >> "$logfile"
    fi
}

backup_dir="/home/patel4p9/home/backup"
stopfile="$backup_dir/stopfile"

while true; do
    complete_backup "$@"
    echo "Sleeping for 120 seconds..."
    sleep 120
    echo "Waking up..."
    
    # Check if the stopfile exists to exit the loop
    if [ -f "$stopfile" ]; then
        echo "Stopfile detected. Exiting loop."
        exit 0
        break
    fi

    incremental_backup "$@"
    echo "Sleeping for 120 seconds..."
    sleep 120
    echo "Waking up..."
    
    # Check if the stopfile exists to exit the loop
    if [ -f "$stopfile" ]; then
        echo "Stopfile detected. Exiting loop."
        exit 0
        break
    fi

    incremental_backup "$@"
    echo "Sleeping for 120 seconds..."
    sleep 120
    echo "Waking up..."
    # Check if the stopfile exists to exit the loop
    if [ -f "$stopfile" ]; then
        echo "Stopfile detected. Exiting loop."
        exit 0
        break
    fi

    differential_backup "$@"
    echo "Sleeping for 120 seconds..."
    sleep 120
    echo "Waking up..."
    
    # Check if the stopfile exists to exit the loop
    if [ -f "$stopfile" ]; then
        echo "Stopfile detected. Exiting loop."
        exit 0
        break
    fi
    flag=true
    incremental_backup "$@"
    echo "Sleeping for 120 seconds..."
    sleep 120
    echo "Waking up..."
    flag=false
    # Check if the stopfile exists to exit the loop
    if [ -f "$stopfile" ]; then
        echo "Stopfile detected. Exiting loop."
        exit 0
        break
    fi
done