CC=cl65
CFLAGS=-T -t none -I . --cpu "65C02"
LDFLAGS=-C link.ld -m $(NAME).map

NAME=hello

BIN=$(NAME).bin
HEX=$(NAME).hex

LISTS=lists

SRCS=$(wildcard *.s) $(wildcard *.c)

OBJS+=$(patsubst %.s,%.o,$(filter %s,$(SRCS)))
OBJS+=$(patsubst %.c,%.o,$(filter %c,$(SRCS)))

all: $(BIN)

$(BIN): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@


$(HEX): $(BIN)
	objcopy --input-target=binary --output-target=verilog --verilog-data-width 1 $(BIN) $(HEX)

install: $(HEX)
	cp $(HEX) ../hw

%.o: %.c $(LISTS)
	$(CC) $(CFLAGS) -l $(LISTS)/$<.list -c $< -o $@

%.o: %.s $(LISTS)
	$(CC) $(CFLAGS) -l $(LISTS)/$<.list -c $< -o $@

$(LISTS):
	mkdir -p $(addprefix $(LISTS)/,$(sort $(dir $(SRCS))))

.PHONY: clean
clean:
	rm -rf $(OBJS) $(BIN) $(HEX) $(LISTS) $(NAME).map

