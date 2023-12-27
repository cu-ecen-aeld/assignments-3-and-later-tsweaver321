# Compiler and compiler flags
CROSS_COMPILE ?=
CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -Wextra

# Target executable
TARGET = writer

# Source files
SRCS = writer.c

# Object files
OBJS = $(SRCS:.c=.o)

.PHONY: all clean

# Default target to build the "writer" application
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean target to remove the "writer" application and all .o files
clean:
	rm -f $(TARGET) $(OBJS)
