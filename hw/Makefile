IVERILOG=iverilog
IVERILOG_ARGS=-g2012 -DSIM
PKGS=qoi_types.sv
SRCS=ssram.sv memory_unit.sv qoi.sv ALU.v cpu_65c02.v
TB=tb.sv
TOP=tb
NAME=simv

all: exe

exe:
	$(IVERILOG) $(PKGS) $(SRCS) $(TB) -s $(TOP) $(IVERILOG_ARGS) -o $(NAME)

run: exe
	./$(NAME) -lxt2

exe_waves:
	$(IVERILOG) $(PKGS) $(SRCS) $(TB) -s $(TOP) $(IVERILOG_ARGS) -o $(NAME) -DWAVES

waves: exe_waves
	./$(NAME) -lxt2
	gtkwave -o tb.vcd &

clean:
	rm -rf *.vcd
	rm -rf $(NAME)
