`timescale 10ns/1ns

module tb();

// timeunit 10ns;
// timeprecision 1ns;

// import qoi_types::*;

reg clk, reset;
wire [15:0] AB;
wire [7:0] DI, DO;
reg IRQ, NMI, RDY;
wire WE, SYNC;

wire [7:0] new_di;
//assign DI = new_di;

reg [7:0] tb_di;
assign DI = new_di;

always #1 clk = clk === 0;

cpu_65c02 u_cpu(.*);

wire qoi_cs;
reg qoi_cs_q;
wire [7:0] accel_do;
reg [7:0] accel_do_q;

qoi u_qoi(
	.clk(clk),
	.rst(reset),
	.cs(qoi_cs),
	.mem_cs(accel_mem_cs),
	.we(WE),
	.data_i(DO),
	.data_o(accel_do),
	.addr(AB[9:0])
	);

reg [7:0] ram [4096*8-1:0];
reg [7:0] img [4096-1:0];
reg [7:0] qoi [4096-1:0];
reg [7:0] rom [4096*4-1:0];

wire img_access, img_access_q;
wire qoi_access;

reg prg_rom_cs_q;
reg ram_cs_q;

wire accel_mem_cs;
reg accel_mem_cs_q;

assign img_access = (AB >= 16'h8000 && AB < 16'h9000);
assign qoi_access = (AB >= 16'h9000 && AB < 16'ha000);
assign accel_mem_cs = (AB >= 16'ha000 && AB < 16'ha400);
assign qoi_cs = (AB >= 16'ha400 && AB < 16'ha408);

`ifdef WAVES
initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0,tb);
end
`endif

assign new_di = accel_mem_cs_q ? accel_do : tb_di;

always @(posedge clk) begin
	if (AB >= 16'hC000 && ~WE) begin
		tb_di <= rom[AB-16'hC000];
	end
	if (AB < 16'h8000) begin
		if (WE) begin
			ram[AB] <= DO;
		end else begin
			tb_di <= ram[AB];
		end
	end

	if (AB >= 16'h8000 && AB < 16'h9000) begin
		if (WE) begin
			img[AB-16'h8000] <= DO;
			$display("Writing to   IMG %x:%x", AB-16'h8000, DO);
		end else begin
			tb_di <= img[AB-16'h8000];
			$display("Reading from IMG %x:%x", AB-16'h8000, img[AB-16'h8000]);
		end
	end

	if (AB >= 16'h9000 && AB < 16'ha000) begin
		if (WE) begin
			qoi[AB-16'h9000] <= DO;
			$display("Writing to   QOI %x:%x", AB-16'h9000, DO);
		end else begin
			tb_di <= qoi[AB-16'h9000];
			$display("Reading from QOI %x:%x", AB-16'h9000, qoi[AB-16'h9000]);
		end
	end

	if (qoi_cs) begin
		tb_di <= accel_do;
	end

	accel_mem_cs_q <= accel_mem_cs;
	accel_do_q <= accel_do;
end

initial begin
	$readmemh("weary_spaghet.mem", img);
	$readmemh("qoi_sim.hex", rom);
	reset = 1;
	RDY = 1;
	IRQ = 0;
	NMI = 0;
	repeat (10) @(posedge clk);
	reset = 0;
	while(1) begin
		if (AB == 16'hffff) begin
			repeat(5) @(posedge clk);
			$writememh("outputqoi.mem", qoi);
			$writememh("output_buffer.mem", u_qoi.u_memory_unit.output_buffer.mem);
			$finish();
		end
		@(posedge clk);
	end
end

endmodule

