IVERILOG=iverilog
IVERILOG_ARGS=-g2012 -DSIM
PKGS=qoi_types.sv
SRCS=qoi.sv ALU.v cpu_65c02.v
TB=tb.sv
TOP=tb
NAME=simv

all: exe

exe:
	$(IVERILOG) $(PKGS) $(SRCS) $(TB) -s $(TOP) $(IVERILOG_ARGS) -o $(NAME)

run: exe
	./$(NAME)

exe_waves:
	$(IVERILOG) $(PKGS) $(SRCS) $(TB) -s $(TOP) $(IVERILOG_ARGS) -o $(NAME) -DWAVES

waves: exe_waves
	./$(NAME)
	gtkwave -o tb.vcd &

clean:
	rm -rf *.vcd
	rm -rf $(NAME)
