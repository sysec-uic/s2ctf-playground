#!/bin/bash
# add_users.sh -- Create student accounts and install their SSH public keys.
#
# Input: a users file (default: users.md). One student per line:
#     <username> <ssh public key ...>
# The first field is the username; the rest of the line is the SSH public key
# (type + key + optional comment). The username and key may be separated by a
# TAB or by spaces. This is exactly what you get by pasting the Google Form
# responses into users.md.
#
# For each student the script:
#   1. Creates a password-disabled account (SSH-key login only).
#   2. Installs the public key into ~/.ssh/authorized_keys with sane perms.
#
# Safe to re-run: existing users are kept, and a key is only appended if it is
# not already present.
#
# Usage: ./add_users.sh [users_file]

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

  # Normalize: strip a trailing CR (Windows paste) and skip blank/comment lines.
  line="${line%$'\r'}"
  [[ -z "${line//[[:space:]]/}" ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue

  # Split on the first run of whitespace: the first field is the username, the
  # rest of the line is the SSH public key. This accepts either a TAB or spaces
  # as the separator, while preserving the single spaces inside the key itself
  # (type + key + comment). Leading/trailing whitespace is trimmed by read.
  read -r username pubkey <<< "$line"

  # Validate the row.
  if [[ -z "$username" ]]; then
    echo "Line $lineno: no username found. Skipping." >&2
    continue
  fi
  if [[ -z "$pubkey" ]]; then
    echo "Line $lineno: no SSH key found for '$username' (username and key must be on one line). Skipping." >&2
    continue
  fi
  if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "Line $lineno: invalid username '$username'. Skipping." >&2
    continue
  fi
  if ! [[ "$pubkey" =~ ^(ssh-|ecdsa-|sk-) ]]; then
    echo "Line $lineno: '$pubkey' does not look like an SSH public key. Skipping." >&2
    continue
  fi

  # 1. Create the account if it does not already exist.
  if id "$username" &>/dev/null; then
    echo "User $username already exists; keeping it."
  else
    sudo adduser --disabled-password --gecos "" "$username"
    echo "Created user $username."
  fi

  # 2. Install the SSH public key.
  home="$(getent passwd "$username" | cut -d: -f6)"
  ssh_dir="$home/.ssh"
  auth_keys="$ssh_dir/authorized_keys"

  sudo mkdir -p "$ssh_dir"
  sudo touch "$auth_keys"

  if sudo grep -qxF "$pubkey" "$auth_keys"; then
    echo "  Key already present for $username."
  else
    echo "$pubkey" | sudo tee -a "$auth_keys" > /dev/null
    echo "  Added SSH key for $username."
  fi

  # Ownership + perms so sshd will accept the key.
  sudo chown -R "$username:$username" "$ssh_dir"
  sudo chmod 700 "$ssh_dir"
  sudo chmod 600 "$auth_keys"

done < "$USERS_FILE"

echo "Done. Processed users from $USERS_FILE."
