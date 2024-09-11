FLAGS    = -z execstack -fno-stack-protector -g
FLAGS_32 = -m32
FLAGS_NOPIE = -no-pie -fno-pic
TARGET   = stack0x01 stack0x02 stack0x03 stack0x04

# To enable CTF: make CTF=1
CTF ?= 0

all: $(TARGET)

stack0x01: vul1.c
	gcc $(FLAGS) $(FLAGS_NOPIE) $(FLAGS_32) -o $@ $^
ifeq ($(CTF), 1)
	sudo chown level1:level1 $@
	sudo chmod u+s $@
endif

stack0x02: vul2.c
	gcc $(FLAGS) $(FLAGS_NOPIE) $(FLAGS_32) -o $@ $^
ifeq ($(CTF), 1)
	sudo chown level2:level2 $@
	sudo chmod u+s $@
endif

stack0x03: vul3.c
	gcc $(FLAGS) $(FLAGS_NOPIE) $(FLAGS_32) -o $@ $^
ifeq ($(CTF), 1)
	sudo chown level3:level3 $@
	sudo chmod u+s $@
endif

stack0x04: vul4.c
	gcc $(FLAGS) $(FLAGS_NOPIE) $(FLAGS_32) -o $@ $^
ifeq ($(CTF), 1)
	sudo chown level4:level4 $@
	sudo chmod u+s $@
endif

clean:
	rm -rf $(TARGET) *.o *-dbg

.PONY: stack0x01 stack0x02 stack0x03 stack0x04
