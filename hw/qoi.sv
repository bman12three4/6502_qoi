module qoi 
import qoi_types::*;
(
    input clk,
    input rst,
    input cs,
    input we,

    input byte_t data_i,
    output byte_t data_o,

    input addr_t addr
);

byte_t input_data[8];
byte_t output_data[8];

size_t size;
pixel_t px, prev_px;

assign px.r = input_data[0];
assign px.g = input_data[1];
assign px.b = input_data[2];
assign px.a = input_data[3];

assign size[0*8 +: 8] = input_data[4];
assign size[1*8 +: 8] = input_data[5];
assign size[2*8 +: 8] = input_data[6];
assign size[3*8 +: 5] = input_data[7][5:0];

always_comb begin
    if (cs) begin
        $display("QOI addr: %x", addr);
    end
end

always_ff @(posedge clk) begin
    if (cs) begin
        if (we) begin
            input_data[addr] <= data_i;
        end else begin
            data_o <= output_data[addr];
        end
    end
end

endmodule