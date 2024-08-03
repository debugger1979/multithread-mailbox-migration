#!/bin/bash

# mail-mig-process.sh - script for migration of mailboxes from one host to another
# format script parameters:
# mail-mig-process.sh <input_file> <host1> <host2> <threads> <dry>

# variables
#
# input_file - file with users to migrate
# host1 - host of the source mailserver
# host2 - host of the target mailserver
# threads - number of mailsync instances running at the same time
# dry - value "--dry" makes imapsync do nothing for real; it just prints what would be done without --dry. (for debug purposes)

input_file=$1
host1=$2
host2=$3
threads=$4
dry=$5

# !!! IMPORTANT !!!
# Format of the file $input_file (filds separated by tab!!!):
# user1<Tab>$user_auth1<Tab>$password1<Tab>$user2<Tab>$user_auth2<Tab>$password2
# if you not use "admin user" for migration, then you can use empty string for user_auth1 and user_auth2, like this:
# user1<Tab><Tab>$password1<Tab>$user2<Tab><Tab>$password2

# if parameter "threads" not set, then threads=10
if [[ -z $threads ]]; then
    # Example: 10, but you can change it to any number, depends on your hardware. 
    # Value 40 is get my CPU (Core i7-3770, 4 cores, 8 threads) to 75%, and RAM to ~9-10 GB 
    threads=10
fi

# if parameter "dry" not set, then imapsync will be run in the real mode
if [[ $dry != "--dry" ]]; then 
    dry=""
fi

# read from file $input_file
while IFS= read -r line
do
    # parse line to the variables (parameters of imapsync)
    user1=`echo "$line" | cut -d$'\t' -f1`
    user_auth1=`echo "$line" | cut -d$'\t' -f2`
    password1=`echo "$line" | cut -d$'\t' -f3`
    user2=`echo "$line" | cut -d$'\t' -f4`
    user_auth2=`echo "$line" | cut -d$'\t' -f5`
    password2=`echo "$line" | cut -d$'\t' -f6`

    # if set "admin user" for migration, in input file, then it will be used for imapsync:
    if [[ -n $user_auth1 ]]; then
        user_auth1="--authuser1 $user_auth1"
    fi
    if [[ -n $user_auth2 ]]; then
        user_auth2="--authuser2 $user_auth2"
    fi
    
    # infinite loop for running imapsync instances
    while true;
    do
        # get number of imapsync instances running
        imap_process=`ps aux | grep [i]mapsync | wc -l`
        
        if [ $imap_process -lt $threads ];
        then
            # if number of imapsync instances running is less than $threads, then run imapsync
            imapsync "$dry" --logfile "$user2" --host1 "$host1" --user1 "$user1" "$user_auth1" --password1 "$password1" --host2 "$host2" --user2 "$user2" "$user_auth2" --password2 "$password2" &
            break
        else
            # if number of imapsync instances running is more than $threads, then wait for the end of the previous imapsync instance
            continue
        fi
    done
done < $input_file