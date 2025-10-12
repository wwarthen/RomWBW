APP := compress
OBJS := compress.o
UNAME := $(shell uname)

all: $(APP)
	cp -p $(APP) ../../$(UNAME)

$(APP): $(OBJS)
	$(CC) $^ -o $@

clean:
	@rm -rf $(APP) $(OBJS)
