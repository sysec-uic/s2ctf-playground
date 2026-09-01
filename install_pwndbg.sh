#!/bin/bash
# install_pwndbg.sh -- Install pwndbg ONCE in a shared location and enable it
# for every user (current and future) via the system-wide GDB init file.
#
# Why this works: pwndbg is a GDB plugin. GDB reads a system-wide init file at
# startup for EVERY user, so a single `source .../gdbinit.py` line there gives
# all users pwndbg -- there is no need to install it once per student.
#
# Layout on the target machine:
#   /opt/pwndbg              the shared install (root-owned, world-readable)
#   <system gdbinit>         gets one line: source /opt/pwndbg/gdbinit.py
#
# Run this on the TARGET machine (the CTF server), as a user with sudo.
# Requirements: sudo, and network access (apt + git clone + dependency install).

set -euo pipefail

PWNDBG_DIR="/opt/pwndbg"
SOURCE_LINE="source $PWNDBG_DIR/gdbinit.py"

# --- 0. Prerequisites ------------------------------------------------------
# Make sure git and gdb exist (pwndbg's setup.sh also needs them; and we need
# gdb present to locate the system-wide init file below).
if ! command -v git >/dev/null || ! command -v gdb >/dev/null; then
  echo "[*] Installing prerequisites (git, gdb)..."
  sudo apt-get update
  sudo apt-get install -y git gdb
fi

echo "[*] GDB embeds Python: $(gdb --batch --nx -ex 'python import sys; print(sys.version.split()[0])' 2>/dev/null || echo '?')"

# --- 1. Locate the system-wide gdbinit that GDB actually reads --------------
# The path is baked in at build time; ask gdb for it instead of guessing.
SYSTEM_GDBINIT="$(gdb --configuration 2>/dev/null \
  | grep -oE -- '--with-system-gdbinit=[^ "]+' \
  | head -1 | cut -d= -f2)"
SYSTEM_GDBINIT="${SYSTEM_GDBINIT:-/etc/gdb/gdbinit}"   # Ubuntu/Debian default
echo "[*] System-wide gdbinit: $SYSTEM_GDBINIT"

# --- 2. Clone (or update) pwndbg into the shared location ------------------
echo "[*] Installing pwndbg into $PWNDBG_DIR (shared, root-owned)..."
if [[ -d "$PWNDBG_DIR/.git" ]]; then
  echo "[*] $PWNDBG_DIR already exists; updating."
  sudo git -C "$PWNDBG_DIR" pull --ff-only
else
  sudo git clone https://github.com/pwndbg/pwndbg.git "$PWNDBG_DIR"
fi

# --- 3. Build pwndbg's self-contained environment --------------------------
# setup.sh creates a venv matching GDB's embedded Python and installs all
# dependencies into it; gdbinit.py injects that venv onto gdb's sys.path.
echo "[*] Running pwndbg setup (pulls dependencies; needs network)..."
sudo "$PWNDBG_DIR/setup.sh"

# --- 4. Lock down permissions (SECURITY) -----------------------------------
# This code runs inside EVERY user's gdb -- including root's when you use
# `sudo gdb`. Students must READ/EXECUTE it but never WRITE it, or they could
# inject code that runs as another user. Root-owned, world r-x, no g/o write.
sudo chown -R root:root "$PWNDBG_DIR"
sudo chmod -R go-w "$PWNDBG_DIR"
sudo chmod -R a+rX "$PWNDBG_DIR"

# --- 5. Enable pwndbg for ALL users via the system-wide gdbinit ------------
sudo mkdir -p "$(dirname "$SYSTEM_GDBINIT")"
sudo touch "$SYSTEM_GDBINIT"
if sudo grep -qxF "$SOURCE_LINE" "$SYSTEM_GDBINIT"; then
  echo "[*] $SYSTEM_GDBINIT already sources pwndbg."
else
  echo "$SOURCE_LINE" | sudo tee -a "$SYSTEM_GDBINIT" > /dev/null
  echo "[*] Added pwndbg to $SYSTEM_GDBINIT."
fi

echo "[+] Done. Every user's 'gdb' now loads pwndbg automatically."
echo "    Verify as any student (e.g. su - dbaxter2):  echo quit | gdb"
echo "    You should see the pwndbg banner instead of the plain gdb prompt."
