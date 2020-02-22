CC = gcc
STRIP = strip
CFLAGS = -Werror -Wall -Wextra -Wconversion -O2 -D NDEBUG
BINARY = bin2asm

SRC_FILES = $(wildcard *.c)
OBJ_FILES = $(SRC_FILES:.c=.o)

all: $(BINARY)

.PHONY: clean
clean:
	rm -f $(OBJ_FILES)

$(BINARY): $(OBJ_FILES)
	$(CC) -o $@ $^ $(LIBS)
	$(STRIP) -s $@

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(IMPORT)
