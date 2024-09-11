#!/bin/bash
# Create 4 "level user" and create 4 keyfiles. Random string for each keyfile.
# Then set the ownership of the keyfiles with corresponding "level" users.

# Create the /ctf directory
sudo mkdir -p /ctf

# Set appropriate permissions for the /ctf directory
sudo chmod 755 /ctf

# Function to generate a random string of 8 alphanumeric characters
generate_random_string() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 8
}

# Loop to create users, key files, and insert random strings
for i in $(seq 1 4); do
  # Create the key file (e.g., key1, key2, ...)
  keyfile="/ctf/key$i"
  sudo touch "$keyfile"
  
  # Generate a random string and add it to the key file
  random_string=$(generate_random_string)
  echo "$random_string" | sudo tee "$keyfile" > /dev/null
  
  # Set permissions for the key files (optional, e.g., read only for owner)
  sudo chmod 400 "$keyfile"

  # Create the user (e.g., level1, level2, ...)
  username="level$i"
  sudo adduser --disabled-password --gecos "" "$username"

  # Change ownership of the corresponding key file to the user
  sudo chown "$username:$username" "$keyfile"

  echo "Created $username and assigned ownership of $keyfile with random string [xxx]"
done

make -C ctf clean; make -C ctf CTF=1

echo "CTF environment setup completed."