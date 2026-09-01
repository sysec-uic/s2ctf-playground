#!/bin/bash
# del_users.sh -- Remove the student accounts created by add_users.sh.
#
# Input: the same users file used by add_users.sh (default: users.md). Only the
# first whitespace-separated field of each line (the username) is used; the SSH
# key portion is ignored.
#
# For each listed student the script deletes the account and its home directory
# (which also removes their ~/.ssh/authorized_keys).
#
# This only touches the students listed in the file; the level1..level4 CTF
# users and /ctf are handled separately by clean.sh.
#
# Usage: ./del_users.sh [users_file]

set -u

USERS_FILE="${1:-users.md}"

if [[ ! -f "$USERS_FILE" ]]; then
  echo "Error: users file '$USERS_FILE' not found." >&2
  echo "Usage: $0 [users_file]" >&2
  exit 1
fi

lineno=0
while IFS= read -r line || [[ -n "$line" ]]; do
  lineno=$((lineno + 1))

  # Strip a trailing CR (Windows paste) and skip blank/comment lines.
  line="${line%$'\r'}"
  [[ -z "${line//[[:space:]]/}" ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue

  # Username = first whitespace-separated field (TAB or spaces); ignore the key.
  read -r username _ <<< "$line"

  if [[ -z "$username" ]]; then
    echo "Line $lineno: no username found. Skipping." >&2
    continue
  fi
  if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "Line $lineno: invalid username '$username'. Skipping." >&2
    continue
  fi

  if id "$username" &>/dev/null; then
    sudo deluser --remove-home "$username"
    echo "Deleted user $username"
  else
    echo "User $username does not exist; nothing to do."
  fi

done < "$USERS_FILE"

echo "Done. Removed students listed in $USERS_FILE."
