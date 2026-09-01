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

# Install the built Set-UID binaries into the shared /ctf directory so every
# student can run them from one canonical place. Each binary stays owned by its
# matching level user with the setuid bit set (-rwsr-xr-x); it is not writable
# by students, so the challenge binaries cannot be tampered with.
for i in $(seq 1 4); do
  binary="stack0x0$i"
  # Copy + set ownership first, then set the setuid bit as a separate step.
  # (Setting owner clears setuid, and some `install` variants apply -o after
  # -m, so we must chmod u+s last to reliably keep -rwsr-xr-x.)
  sudo install -m 755 -o "level$i" -g "level$i" "ctf/$binary" "/ctf/$binary"
  sudo chmod u+s "/ctf/$binary"
  echo "Installed /ctf/$binary (setuid level$i)"
done

echo "CTF environment setup completed."
