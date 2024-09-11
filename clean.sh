#!/bin/bash

# Loop to delete users and their home directories
for i in $(seq 1 4); do
  # Format the username (e.g., level1, level2, ...)
  username="level$i"

  # Delete the user and their home directory
  sudo deluser --remove-home "$username"

  echo "Deleted user $username"
done

# Remove the /ctf directory and its contents (key files)
sudo rm -rf /ctf

make -C ctf clean

echo "/ctf directory and key files removed"