#!/bin/bash

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 '<hex_string>'"
    exit 1
fi

# Remove any '\x' from the input string and convert hex to binary
echo -n $1 | sed 's/\\x//g' | xxd -r -p > temp_bin

# Disassemble the binary using objdump for x86 architecture
objdump -D -b binary -m i386 -M intel temp_bin

# Clean up the temporary binary file
rm temp_bin
