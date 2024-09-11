## A super simple capture-the-flag (s2CTF) playground
These are simple in-class examples of stack buffer overflow attacks and a shellcode injection attack for UIC CS 487.

### Setup the environment
```
git clone https://github.com/sysec-uic/s2ctf-playground.git
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
And key files `/ctf/key1`, ..., `/ctf/key4` under `/ctf` directory:
```
$ ls /ctf -lt 
total 16
-r-------- 1 level4 level4 9 Sep 11 22:14 key4
-r-------- 1 level3 level3 9 Sep 11 22:14 key3
-r-------- 1 level2 level2 9 Sep 11 22:14 key2
-r-------- 1 level1 level1 9 Sep 11 22:14 key1
```
### Goal
You need to exploit the buffer overflow vulnerability to get the keys. An example of providing the payload:
```
./stack0x01 [payload]
```

### Clean up the environment
```
./clean.sh
```
