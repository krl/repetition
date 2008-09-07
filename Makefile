SOURCES=$(shell ls *.c)
OBJECTS=${SOURCES:.c=.o}
#HEADER=$(shell ls *.h)
EXECUTABLE=seq
# CFLAGS=-Wuninitialized -O -g
CFLAGS=-W -Iinclude
LIBS=-ljack
LFLAGS=$(LIBS) -W

all: $(EXECUTABLE)

.PHONY: check-syntax
check-syntax:
	g++ -g -fsyntax-only $(SOURCES)


$(EXECUTABLE): $(OBJECTS)
	gcc -g $(OBJECTS) -o $@ $(LFLAGS)

%.o: %.c $(HEADER)
	gcc -g $(CFLAGS) -c $<

clean:
	rm $(OBJECTS) $(EXECUTABLE)
