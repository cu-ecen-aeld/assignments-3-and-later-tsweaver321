#!/bin/sh

# Check if the required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <filesdir> <searchstr>"
    exit 1
fi

filesdir=$1
searchstr=$2

# Check if filesdir is a directory
if [ ! -d $filesdir ]; then
    echo "Error: '$filesdir' is not a directory."
    exit 1
fi

# Find matching lines in files
matching_lines=$(grep -r "$searchstr" "$filesdir" | wc -l)
file_count=$(find "$filesdir" -type f | wc -l)

# Print the results
echo "The number of files are $file_count and the number of matching lines are $matching_lines"
