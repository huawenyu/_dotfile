// vim: set filetype=markdown:

# @note:makefile
TARGET = testme
LIBS = -lm
CC=gcc
CFLAGS=-g -Wall

# @note:makefile
TARGET = testme
LIBS = -lm
CC=gcc
CFLAGS=-g -Wall

.PHONY: default all clean

default: $(TARGET)
all: default

OBJS = $(patsubst %.c, %.o, $(wildcard *.c))
HDRS = $(wildcard *.h)

%.o: %.c $(HDRS)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -Wall $(LIBS) -o $@

clean:
	- rm -f *.o
	- rm -f $(TARGET)

run: $(TARGET)
	./$(TARGET)
default: $(TARGET)
all: default

OBJS = $(patsubst %.c, %.o, $(wildcard *.c))
HDRS = $(wildcard *.h)

%.o: %.c $(HDRS)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJS)
	$(CC) $(OBJS) -Wall $(LIBS) -o $@

clean:
	- rm -f *.o
	- rm -f $(TARGET)

run: $(TARGET)
	./$(TARGET)
