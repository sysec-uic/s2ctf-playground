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
# NOTE: pwndbg's setup.sh (via `uv`) resolves dependencies from the
# pyproject.toml in the CURRENT directory, so it must run with its CWD set to
# the pwndbg checkout -- otherwise it fails with "No pyproject.toml found".
echo "[*] Running pwndbg setup (pulls dependencies; needs network)..."
( cd "$PWNDBG_DIR" && sudo ./setup.sh )

# --- 4. Lock down permissions (SECURITY) -----------------------------------
# This code runs inside EVERY user's gdb -- including root's when you use
# `sudo gdb`. Students must READ/EXECUTE it but never WRITE it, or they could
# inject code that runs as another user. Root-owned, world r-x, no g/o write.
sudo chown -R root:root "$PWNDBG_DIR"
sudo chmod -R go-w "$PWNDBG_DIR"
sudo chmod -R a+rX "$PWNDBG_DIR"

# --- 5. Enable pwndbg for ALL users via the system-wide gdbinit ------------
# We write a managed block containing:
#   1) `set debuginfod enabled off`. Ubuntu's gdb auto-fetches debug info and
#      source from a remote debuginfod server; on an offline/firewalled CTF box
#      every lookup hangs until it times out ("Download failed: Timer expired").
#   2) Disable pwndbg's runtime auto-update. This is a SHARED, read-only install
#      (students cannot write /opt/pwndbg), so a user session must never try to
#      self-update -- it would fail with "Permission denied". The admin updates
#      manually by re-running this script (git pull + setup.sh) as root.
#   3) Source pwndbg itself.
sudo mkdir -p "$(dirname "$SYSTEM_GDBINIT")"
sudo touch "$SYSTEM_GDBINIT"

# Remove any prior managed block and any bare pwndbg source line, then re-add,
# so re-running this script stays idempotent.
sudo sed -i '/# >>> pwndbg (managed by install_pwndbg.sh) >>>/,/# <<< pwndbg <<</d' "$SYSTEM_GDBINIT"
sudo sed -i "\#^${SOURCE_LINE}\$#d" "$SYSTEM_GDBINIT"
sudo sed -i '\#^set debuginfod enabled off$#d' "$SYSTEM_GDBINIT"
sudo tee -a "$SYSTEM_GDBINIT" > /dev/null <<EOF
# >>> pwndbg (managed by install_pwndbg.sh) >>>
set debuginfod enabled off
python import os; os.environ.setdefault("PWNDBG_NO_AUTOUPDATE", "1")
$SOURCE_LINE
# <<< pwndbg <<<
EOF
echo "[*] Enabled pwndbg (auto-update + debuginfod disabled) in $SYSTEM_GDBINIT."

echo "[+] Done. Every user's 'gdb' now loads pwndbg automatically."
echo "    Verify as any student (e.g. su - dbaxter2):  echo quit | gdb"
echo "    You should see the pwndbg banner instead of the plain gdb prompt."
echo
echo "    To UPDATE pwndbg later, just re-run this script as an admin:"
echo "      ./install_pwndbg.sh   (git pull + setup.sh + re-lock, all as root)"
