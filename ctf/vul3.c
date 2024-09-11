#include <string.h>
#include <stdio.h>
#include <stdio.h>
#include <unistd.h>
#include <err.h>

#define	SIZE	64

void target() {
	char *argv[] = {"/usr/bin/cat", "/ctf/key3", NULL};
	execve(argv[0], argv, NULL);
}

void dummy() {
	printf("A dummy function is called.\n");
}

int vul(char *input)
{
	char buf[SIZE];
	strcpy(buf, input);
	return 0;
}

int main(int argc, char *argv[], char *env[])
{
	if(argc == 1) {
		errx(1, "Please specify an argument.");
	}
	vul(argv[1]);

	return 0;
}
