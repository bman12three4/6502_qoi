#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: ./script.sh input.txt output.txt"
  exit 1
fi

input_file="$1"
tmp_file=tmp
tmp2_file=tmp2
tmp3_file=tmp3
output_file="$2"

gawk '!/^\/\//' "$input_file" > "$tmp_file"
sed -e 's/ //g' -e 's/x//g'  "$tmp_file" > "$tmp2_file"
awk 'BEGIN { line_number = 0 } /^[[:space:]]*$/ { exit } { printf "%03x: %s\n", line_number, $0; line_number++ }' "$tmp2_file" > "$tmp3_file"
xxd -r "$tmp3_file" > "$output_file"
rm tmp*