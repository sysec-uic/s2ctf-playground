## A super simple capture-the-flag (s2CTF) playground
These are simple in-class examples of stack buffer overflow attacks, shellcode injection, and code reuse (e.g., ret2libc) attacks for UIC CS 487.
The code has been tested on **Ubuntu 22.04**.

### Setup the environment
```
sudo apt install gcc gcc-multilib make git
git clone https://github.com/sysec-uic/s2ctf-playground.git
cd s2ctf-playground
./setup.sh
```
You should have `stack0x01`, ..., `stack0x04` under `ctf/`:
```
$ ls ctf -lt 
total 96
-rwsrwxr-x 1 level4 level4 16320 Sep 11 22:14 stack0x04
-rwsrwxr-x 1 level3 level3 16588 Sep 11 22:14 stack0x03
-rwsrwxr-x 1 level2 level2 16624 Sep 11 22:14 stack0x02
-rwsrwxr-x 1 level1 level1 16488 Sep 11 22:14 stack0x01
... ...
```
The setup also installs the Set-UID binaries and their key files into the shared
`/ctf` directory, so every student can run the challenges from one place:
```
$ ls /ctf -lt 
total 80
-rwsr-xr-x 1 level4 level4 16320 Sep 11 22:14 stack0x04
-rwsr-xr-x 1 level3 level3 16588 Sep 11 22:14 stack0x03
-rwsr-xr-x 1 level2 level2 16624 Sep 11 22:14 stack0x02
-rwsr-xr-x 1 level1 level1 16488 Sep 11 22:14 stack0x01
-r-------- 1 level4 level4     9 Sep 11 22:14 key4
-r-------- 1 level3 level3     9 Sep 11 22:14 key3
-r-------- 1 level2 level2     9 Sep 11 22:14 key2
-r-------- 1 level1 level1     9 Sep 11 22:14 key1
```

### Add student accounts
Paste the usernames and SSH public keys from the Google Form into `users.md`
(one student per line: `username` then the `ssh-... key comment`, separated by a
TAB or spaces), then:
```
./add_users.sh users.md
```
This creates a password-disabled (SSH-key-only) account for each student and
installs their public key into `~/.ssh/authorized_keys`. It is safe to re-run as
more responses come in.

To remove those student accounts (and their home directories) later:
```
./del_users.sh users.md
```

### Install pwndbg for all users
pwndbg is a GDB plugin, so it only needs to be installed once. Rather than
installing it per student, install it into a shared location and enable it in
the system-wide GDB init file, so every user (current and future) gets it:
```
./install_pwndbg.sh
```
This clones pwndbg to `/opt/pwndbg` (root-owned, world-readable) and adds a
`source /opt/pwndbg/gdbinit.py` line to the system gdbinit. Keep `/opt/pwndbg`
non-writable by students: that code runs inside every user's `gdb` (including
root's under `sudo gdb`).

### Goal
You need to exploit the buffer overflow vulnerability of the Set-UID programs to get the keys. Students run the challenges from `/ctf`; an example of providing the payload:
```
$ cd /ctf
$ ./stack0x01 [payload]
NWOB3tdw
```

### Clean up the environment
```
./clean.sh
```
