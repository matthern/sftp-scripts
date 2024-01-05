#!/bin/bash
#matthew mcgovern 2023
#add username to create sftp user, add keys from remote server and authorisedkeys of admin and create chroot location with in and out dir. 

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 [<userlist_file> | <user1>]"
    exit 1
fi

userlist_file="$1"

# Check if the userlist file exists
if [ ! -f "$userlist_file" ]; then
    echo "Userlist file '$userlist_file' not found. Assuming a single username."
    echo "$@" > /var/tmp/temp_users.txt
    userlist_file="/var/tmp/temp_users.txt"
fi

# Process the usernames from the file or arguments
while IFS= read -r username || [[ -n "$username" ]]; do
    # Check if the user already exists
    if id "$username" &>/dev/null; then
        echo "User '$username' already exists. Skipping..."
        continue  # Skip this user and proceed to the next one
    fi
	
	echo "Processing user: $username"
    # Create the user
    sudo useradd -m -d "/home/$username" -s /sbin/nologin -G sftpusers "$username" 

        # Create ~/.ssh directory and set permissions if it doesn't exist
    if [ ! -d "/home/$username/.ssh" ]; then
        sudo mkdir -v "/home/$username/.ssh"
        sudo chmod 700 "/home/$username/.ssh"
    fi

    # Create sftpchroot directory if it doesn't exist
    if [ ! -d "/sftpchroot/$username" ]; then
        sudo mkdir -v "/sftpchroot/$username"
    fi

    # Create in/out directories and set permissions if they don't exist
    if [ ! -d "/sftpchroot/$username/in" ]; then
        sudo mkdir -v "/sftpchroot/$username/in"
        sudo chown "$username":"sftpusers" "/sftpchroot/$username/in"
    fi
    
    if [ ! -d "/sftpchroot/$username/out" ]; then
        sudo mkdir -v "/sftpchroot/$username/out"
        sudo chown "$username":"sftpusers" "/sftpchroot/$username/out"
    fi
    
    # Copy keys and set ownership/permissions if they exist
    if [ -f "$id_rsa_directory/id_rsa-$username" ]; then
        sudo cp "$id_rsa_directory/id_rsa-$username" "/home/$username/.ssh/id_rsa"
        sudo chmod 600 "/home/$username/.ssh/id_rsa"
        sudo chown "$username":"sftpusers" "/home/$username/.ssh/id_rsa"
    fi
    
    if [ -f "$id_rsa_directory/id_rsa-$username.pub" ]; then
        sudo cp "$id_rsa_directory/id_rsa-$username.pub" "/home/$username/.ssh/id_rsa.pub"
        sudo chmod 644 "/home/$username/.ssh/id_rsa.pub"
        sudo chown "$username":"sftpusers" "/home/$username/.ssh/id_rsa.pub"
    fi

    # Append public keys to authorized_keys if they exist
    if [ -f "$id_rsa_directory/id_rsa-$username.pub" ]; then
        sudo cat "$id_rsa_directory/id_rsa-$username.pub" >> "/home/$username/.ssh/authorized_keys"
    fi
    #append the admin auth key if it exists.
    if [ -f "$authorized_keys_file" ]; then
        sudo cat "$authorized_keys_file" >> "/home/$username/.ssh/authorized_keys"
    fi

    
    
done < "$userlist_file"
