#
# build the propeller tools for linux and Darwin
#
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	SUFFIX=linux
endif
ifeq ($(UNAME), Darwin)
	SUFFIX=osx
endif

DEST = ../../$(UNAME)

all: $(DEST)

$(DEST):
	mkdir $(DEST)

install:
	-for i in *.$(SUFFIX) ; do \
		cp $$i $(DEST)/$$(basename $$i .$(SUFFIX)) ; \
	done

clobber:
	-for i in *.$(SUFFIX) ; do \
		rm $(DEST)/$$(basename $$i .$(SUFFIX)) ; \
	done

clean:
