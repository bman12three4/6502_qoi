module tb();

logic clk, reset;
logic [15:0] AB;
logic [7:0] DI, DO;
logic WE, IRQ, NMI, RDY, SYNC;

always #1 clk = clk === '0;

cpu_65c02 dut(.*);

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0,tb);
end

initial begin
	reset = '1;
	RDY = '1;
	IRQ = '0;
	NMI = '0;
	DI = 8'hea;
	repeat (10) @(posedge clk);
	reset = '0;
	repeat (100) @(posedge clk);
	$finish();
end

endmodule

