#!/bin/bash

# Loop to delete users and their home directories
for i in $(seq 1 4); do
  # Format the username (e.g., level1, level2, ...)
  username="level$i"

  # Delete the user and their home directory
  sudo deluser --remove-home "$username"

  echo "Deleted user $username"
done

# Remove the /ctf directory and everything in it: the key files AND the
# installed Set-UID challenge binaries (stack0x01..stack0x04).
sudo rm -rf /ctf

make -C ctf clean

echo "/ctf directory removed (keys and installed stack0x0* binaries)"