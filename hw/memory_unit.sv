module memory_unit
import qoi_types::*;
(
    input clk,
    input rst,

    input addr_t addr_a,
    input byte_t data_a_i,
    output byte_t data_a_o,
    input cs_a, we_a,

    input addr_t addr_b,
    input byte_t data_b_i,
    output byte_t data_b_o,
    input cs_b, we_b,

    input sel,

    output flag
);

logic flag, next_flag;

byte_t input_buffer_data;
wire [7:0] _input_buffer_data;
byte_t output_buffer_data;
wire [7:0] _output_buffer_data;

addr_t input_buffer_addr;
addr_t output_buffer_addr;

logic input_buffer_cs, input_buffer_we, input_buffer_oe;
logic output_buffer_cs, output_buffer_we, output_buffer_oe;

assign _input_buffer_data = !input_buffer_oe ? input_buffer_data : 'z;
assign _output_buffer_data = !output_buffer_oe ? output_buffer_data : 'z;

ssram input_buffer(
    .clk(clk),
    .addr(input_buffer_addr),
    .data(_input_buffer_data),
    .cs(input_buffer_cs),
    .we(input_buffer_we),
    .oe(input_buffer_oe)
);

ssram output_buffer(
    .clk(clk),
    .addr(output_buffer_addr),
    .data(_output_buffer_data),
    .cs(output_buffer_cs),
    .we(output_buffer_we),
    .oe(output_buffer_oe)
);

always_ff @(posedge clk) begin
    if (rst) begin
        flag <= '0;
    end else begin
        flag <= next_flag;
    end
end

always_comb begin
    next_flag = flag;

    if (sel) begin
        input_buffer_addr = addr_b;
        data_b_o = input_buffer_data;
        input_buffer_cs = cs_b & ~we_b;
        input_buffer_oe = '1;
        input_buffer_we = '0;

        output_buffer_addr = addr_b;
        output_buffer_data = data_b_i;
        output_buffer_cs = cs_a & we_a;
        output_buffer_oe = '0;
        output_buffer_we = '1;

        if (addr_b == '1 && cs_b) begin
            next_flag = '1;
        end
    end else begin
        input_buffer_addr = addr_a;
        input_buffer_data = data_a_i;
        input_buffer_cs = cs_a & we_a;
        input_buffer_oe = '0;
        input_buffer_we = '1;

        output_buffer_addr = addr_a;
        data_a_o = output_buffer_data;
        output_buffer_cs = cs_a & ~we_a;
        output_buffer_oe = '1;
        output_buffer_we = '0;

        if (addr_a == '1 && cs_a) begin
            next_flag = '1;
        end
    end

end

endmodule