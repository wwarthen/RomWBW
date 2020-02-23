CC = gcc
STRIP = strip
CFLAGS = -Werror -Wall -Wextra -Wconversion -O2 -D NDEBUG
BINARY = bin2asm

DEST := ../../$(shell uname)

SRC_FILES = $(wildcard *.c)
OBJ_FILES = $(SRC_FILES:.c=.o)

all: $(BINARY) $(DEST)
	cp $(BINARY) $(DEST)

$(DEST):
	mkdir -p $(DEST)
	
.PHONY: clean

clean:
	rm -f $(OBJ_FILES)

clobber:
	rm -f $(DEST)/$(BINARY) $(BINARY)

$(BINARY): $(OBJ_FILES)
	$(CC) -o $@ $^ $(LIBS)
	$(STRIP) -s $@

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(IMPORT)

