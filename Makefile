
CFLAGS=-Wall -Wextra

all: main
	./main

%: %.o


%.o: %.c

