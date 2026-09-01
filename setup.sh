#!/bin/bash
# Create 4 "level" users and 4 flag files (random string in each), then set the
# ownership of the flag files to the corresponding "level" users.
#
# Layout after setup:
#   /ctf/keyN            the flag, owned by levelN, readable only via the binary
#   /vulcode/stack0x0N   the setuid challenge binary (owned by levelN)
#   /vulcode/stack0x0N.c its source code (world-readable, for students to study)

# Create the shared directories: /ctf holds the flags, /vulcode holds the
# challenge binaries and their source code.
sudo mkdir -p /ctf /vulcode

# Set appropriate permissions (traversable + world-readable dirs).
sudo chmod 755 /ctf /vulcode

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

# Install the built Set-UID binaries and their source code into the shared
# /vulcode directory so every student can run and read them from one canonical
# place. Each binary stays owned by its matching level user with the setuid bit
# set (-rwsr-xr-x) and is not writable by students, so the challenge binaries
# cannot be tampered with. The source is root-owned and world-readable.
for i in $(seq 1 4); do
  binary="stack0x0$i"
  # Copy + set ownership first, then set the setuid bit as a separate step.
  # (Setting owner clears setuid, and some `install` variants apply -o after
  # -m, so we must chmod u+s last to reliably keep -rwsr-xr-x.)
  sudo install -m 755 -o "level$i" -g "level$i" "ctf/$binary" "/vulcode/$binary"
  sudo chmod u+s "/vulcode/$binary"
  # Install the matching source code next to the binary (read-only).
  sudo install -m 644 -o root -g root "ctf/vul$i.c" "/vulcode/$binary.c"
  echo "Installed /vulcode/$binary (setuid level$i) and /vulcode/$binary.c"
done

echo "CTF environment setup completed."
