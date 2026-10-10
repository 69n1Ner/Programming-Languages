#!/bin/bash
FILE=$1
OUTPUT="${FILE%.asm}"
nasm -g "$FILE" -f elf64 -o "${OUTPUT}.o" && ld -o "$OUTPUT" "${OUTPUT}.o" && ./"$OUTPUT"
