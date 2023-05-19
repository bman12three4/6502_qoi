module tb();

timeunit 10ns;
timeprecision 10ns;

logic clk, reset;
logic [15:0] AB;
logic [7:0] DI, DO;
logic WE, IRQ, NMI, RDY, SYNC;

always #1 clk = clk === '0;

cpu_65c02 dut(.*);

logic [7:0] ram [4096*8];
logic [7:0] img [4096];
logic [7:0] qoi [4096];
logic [7:0] rom [4096*3];

logic img_access, qoi_access;

assign img_access = (AB >= 16'h8000 && AB < 16'h9000);
assign qoi_access = (AB >= 16'h9000 && AB < 16'ha000);

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0,tb);
end

always @(posedge clk) begin
	if (AB >= 16'hd000 && ~WE) begin
		DI <= rom[AB-16'hd000];
	end
	if (AB < 16'h8000) begin
		if (WE) begin
			ram[AB] <= DO;
		end else begin
			DI <= ram[AB];
		end
	end

	if (AB >= 16'h8000 && AB < 16'h9000) begin
		if (WE) begin
			img[AB-16'h8000] <= DO;
			$display("Writing to   IMG %x:%x", AB-16'h8000, DO);
		end else begin
			DI <= img[AB-16'h8000];
			$display("Reading from IMG %x:%x", AB-16'h8000, img[AB-16'h8000]);
		end
	end

	if (AB >= 16'h9000 && AB < 16'ha000) begin
		if (WE) begin
			qoi[AB-16'h9000] <= DO;
			$display("Writing to   QOI %x:%x", AB-16'h9000, DO);
		end else begin
			DI <= qoi[AB-16'h9000];
			$display("Reading from QOI %x:%x", AB-16'h9000, qoi[AB-16'h9000]);
		end
	end
end

initial begin
	$readmemh("pixels.mem", img);
	$readmemh("qoi_sim.hex", rom);
	reset = '1;
	RDY = '1;
	IRQ = '0;
	NMI = '0;
	DI = 8'hea;
	repeat (10) @(posedge clk);
	reset = '0;
	while(1) begin
		if (AB == '1) begin
			repeat(5) @(posedge clk);
			$writememh("outputqoi.mem", qoi);
			$finish();
		end
		@(posedge clk);
	end
end

initial begin
end

endmodule

