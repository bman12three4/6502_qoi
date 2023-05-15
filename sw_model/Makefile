CC=cl65
CFLAGS=-T -t sim65c02 -O
SIM=sim65
SIMARGS=-c
LDFLAGS=-m $(NAME).map

NAME=qoi
BIN=$(NAME).bin
HEX=$(NAME).hex

SRCS=$(wildcard *.s) $(wildcard *.c)
OBJS+=$(patsubst %.s,%.o,$(filter %s,$(SRCS)))
OBJS+=$(patsubst %.c,%.o,$(filter %c,$(SRCS)))

LISTS=lists

all: $(BIN)

sim: $(BIN)
	$(SIM) $(SIMARGS) $(BIN) $(ARGS)

$(BIN): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@


$(HEX): $(BIN)
	objcopy --input-target=binary --output-target=ihex $(BIN) $(HEX)


%.o: %.c $(LISTS)
	$(CC) $(CFLAGS) -l $(LISTS)/$<.list -c $< -o $@


%.o: %.s $(LISTS)
	$(CC) $(CFLAGS) -l $(LISTS)/$<.list -c $< -o $@

$(LISTS):
	mkdir -p $(addprefix $(LISTS)/,$(sort $(dir $(SRCS))))

.PHONY: clean
clean:
	rm -rf $(OBJS) $(BIN) $(HEX) $(LISTS) $(NAME).map
