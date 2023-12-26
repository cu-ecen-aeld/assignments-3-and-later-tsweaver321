#!/bin/bash

# Check if the number of arguments is correct
if [ $# -ne 2 ]; then
    echo "Usage: $0 <writefile> <writestr>"
    exit 1
fi

# Assign arguments to variables
writefile="$1"
writestr="$2"

# Check if writefile is specified
if [ -z "$writefile" ]; then
    echo "Error: Please specify the path to the file"
    exit 1
fi

# Check if writestr is specified
if [ -z "$writestr" ]; then
    echo "Error: Please specify the text string to be written"
    exit 1
fi

# Create the directory if it does not exist
dir=$(dirname "$writefile")
mkdir -p "$dir" || { echo "Error: Unable to create directory $dir"; exit 1; }

# Write content to the file
echo "$writestr" > "$writefile" || { echo "Error: Unable to write to file $writefile"; exit 1; }

echo "Content successfully written to $writefile"
exit 0
