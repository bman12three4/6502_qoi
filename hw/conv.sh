#!/bin/bash

gawk '!/^\/\// && /^[0-9a-fA-F]{2}$/ { printf "%c", strtonum("0x"$0) }' $1 > $2

