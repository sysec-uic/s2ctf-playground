#!/bin/bash

# Loop to delete users and their home directories
for i in $(seq 1 4); do
  # Format the username (e.g., level1, level2, ...)
  username="level$i"

  # Delete the user and their home directory
  sudo deluser --remove-home "$username"

  echo "Deleted user $username"
done

# Remove the /ctf directory (flag files key1..key4) and the /vulcode directory
# (installed Set-UID binaries stack0x01..stack0x04 and their source code).
sudo rm -rf /ctf /vulcode

make -C ctf clean

echo "/ctf (flags) and /vulcode (binaries + source) removed"
