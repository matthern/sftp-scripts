#!/bin/bash
#matthew mcgovern
#needs to run as root
#supply remote server, remote user and list of existing sftp users with SSH keys to scp these to other server and create them on that side. 
#Will need keys exchanged for remote and local user and expects same name for now.

remote_server="$1"
remote_user="$2"

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <remote_server> <remote_user>"
    exit 1
fi

if [ ! -f "$3" ]; then
    echo "Userlist file not found or not provided."
    exit 1
fi

userlist_file="$3"

# Copy id_rsa and id_rsa.pub for each existing user with keys to another server

while IFS= read -r user || [[ -n "$user" ]]; do
    if id "$user" >/dev/null 2>&1; then
        if [ -f "/home/$user/.ssh/id_rsa" ] && [ -f "/home/$user/.ssh/id_rsa.pub" ]; then
            echo "User $user exists with SSH keys, copying id_rsa and id_rsa.pub..."
            scp -i /home/"$remote_user"/.ssh/id_rsa -o StrictHostKeyChecking=no /home/"$user"/.ssh/id_rsa $remote_user@$remote_server:/home/"$remote_user"/id_rsa-"$user" &&
            scp -i /home/"$remote_user"/.ssh/id_rsa -o StrictHostKeyChecking=no /home/"$user"/.ssh/id_rsa.pub $remote_user@$remote_server:/home/"$remote_user"/id_rsa-"$user".pub 
			
        else
            echo "User $user does not have SSH keys, skipping..."
        fi
    else
        echo "User $user does not exist, skipping..."
    fi
done < "$userlist_file"

# Execute a shell script remotely on another server

if [ -n "$remote_script" ]; then
	scp -i /home/"$remote_user"/.ssh/id_rsa -o StrictHostKeyChecking=no "$userlist_file" $remote_user@$remote_server:/home/"$remote_user"/"$userlist_file" &&
	scp -i /home/"$remote_user"/.ssh/id_rsa -o StrictHostKeyChecking=no "$remote_script" $remote_user@$remote_server:/home/"$remote_user"/"$remote_script"
  ssh $remote_user@$remote_server "bash -s" < "$remote_script" "$userlist_file" 
fi
