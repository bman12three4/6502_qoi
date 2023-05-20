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

exe_waves:
	$(IVERILOG) $(SRCS) $(TB) -s $(TOP) $(IVERILOG_ARGS) -o $(NAME) -DWAVES

waves: exe_waves
	./$(NAME)
	gtkwave tb.vcd &

clean:
	rm -rf *.vcd
	rm -rf $(NAME)
