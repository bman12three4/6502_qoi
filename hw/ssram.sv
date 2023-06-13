module ssram 
import qoi_types::*;
#(
    parameter DEPTH = 1024
) (
    input clk,
    input addr_t addr,
    inout byte_t data,
    input cs,
    input we,
    input oe
);

byte_t _data;
byte_t mem [DEPTH];

always @(posedge clk) begin
    if (cs & we) begin
        mem[addr] <= data;
    end

    if (cs & !we) begin
        _data = mem[addr];
    end
end

assign data = cs & oe & !we ? _data : 'z;

endmodule