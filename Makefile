
CFLAGS=-Wall -Wextra -g

all: main
	./main

%: %.o


%.o: %.c
