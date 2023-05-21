#!/bin/bash

objcopy --input-target=binary --output-target=verilog --verilog-data-width 1 $(BIN) $(HEX)