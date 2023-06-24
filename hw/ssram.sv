module ssram 
#(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 8, 
    parameter DEPTH = 1024
) (
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    inout [DATA_WIDTH-1:0] data,
    input cs,
    input we,
    input oe
);

reg [DATA_WIDTH-1:0]  _data;
reg [DATA_WIDTH-1:0]  mem [DEPTH];

always @(posedge clk) begin
    if (cs & we) begin
        $display("SSRAM %m M[%x] <= %x", addr, data);
        mem[addr] <= data;
    end

    if (cs & !we) begin
        _data = mem[addr];
    end
end

assign data = cs & oe & !we ? _data : 'z;

endmodule