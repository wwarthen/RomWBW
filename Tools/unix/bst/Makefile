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
	-for i in *.$(SUFFIX) ; do \
		chmod +x $$i ; \
		cp $$i $(DEST)/$$(basename $$i .$(SUFFIX)) ; \
	done

$(DEST):
	mkdir $(DEST)

clobber:
	-for i in *.$(SUFFIX) ; do \
		rm $(DEST)/$$(basename $$i .$(SUFFIX)) ; \
	done

clean:
