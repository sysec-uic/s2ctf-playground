#include <string.h>
#include <stdio.h>
#include <stdio.h>
#include <unistd.h>
#include <err.h>

#define	SIZE	64

int vul(char *input)
{
	int flag = 0;
	char buf[SIZE];
	strcpy(buf, input);
	if (flag) {
		char *argv[] = {"/usr/bin/cat", "/ctf/key1", NULL};
		execve(argv[0], argv, NULL);
	} else {
		printf("Flag was not changed. Try it again!\n");
	}
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
