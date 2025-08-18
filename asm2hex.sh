#!/bin/bash
# asmconvert.sh - assemble and extract opcodes from inline asm or a file

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <instruction(s) | file.asm>"
    exit 1
fi

INPUT="$1"

# Prepare temp.asm
echo "section .text" > temp.asm
echo "global _start" >> temp.asm
echo "_start:" >> temp.asm

if [ -f "$INPUT" ]; then
    cat "$INPUT" >> temp.asm
else
    echo "$INPUT" | sed 's/;/\n/g' >> temp.asm
fi

# Assemble and link (32-bit)
nasm -f elf32 -o temp.o temp.asm
ld -m elf_i386 -o temp temp.o

# Disassemble and extract opcodes
objdump -M intel -d temp \
  | grep '[0-9a-f]:' \
  | grep -v 'file' \
  | cut -f2 -d: \
  | cut -f1-7 -d' ' \
  | tr -s ' ' \
  | tr '\t' ' ' \
  | sed 's/ $//g' \
  | sed 's/ /\\x/g' \
  | paste -d '' -s

# Cleanup
rm -f temp.asm temp.o temp
