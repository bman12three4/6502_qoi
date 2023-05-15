IVERILOG=iverilog
IVERILOG_ARGS=-g2012
SRCS=ALU.v cpu_65c02.v
TB=tb.sv
TOP=tb
NAME=simv

all: exe

exe:
	$(IVERILOG) $(SRCS) $(TB) -s $(TOP) $(IVERILOG_ARGS) -o $(NAME)

run: exe
	./$(NAME)

waves: run
	gtkwave tb.vcd &

clean:
	rm -rf *.vcd
	rm -rf $(NAME)
