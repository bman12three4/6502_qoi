module memory_unit
(
    input clk,
    input rst,

    input [9:0] addr_a,
    input [7:0] data_a_i,
    output reg [7:0] data_a_o,
    input cs_a, we_a,

    input [9:0] addr_b,
    input [7:0] data_b_i,
    output reg [7:0] data_b_o,
    input cs_b, we_b,

    input sel,

    output reg flag_o
);

logic flag, next_flag;

//assign flag_o = next_flag;

reg [7:0] input_buffer_data;
wire [7:0] _input_buffer_data;
reg [7:0]  output_buffer_data;
wire [7:0] _output_buffer_data;

reg [9:0] input_buffer_addr;
reg [9:0] output_buffer_addr;

reg input_buffer_cs, input_buffer_we, input_buffer_oe;
reg output_buffer_cs, output_buffer_we, output_buffer_oe;

assign _input_buffer_data = !input_buffer_oe ? input_buffer_data : 8'hzz;
assign _output_buffer_data = !output_buffer_oe ? output_buffer_data : 8'hzz;

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

/*
always_ff @(posedge clk) begin
    if (rst) begin
        flag <= '0;
    end else begin
        flag <= next_flag;
    end
end
*/

always @(*) begin
    //next_flag = flag;
    flag_o = 0;

    if (sel) begin
        input_buffer_addr = addr_b;
        data_b_o = _input_buffer_data;
        input_buffer_cs = cs_b & ~we_b;
        input_buffer_oe = 1;
        input_buffer_we = 0;

        output_buffer_addr = addr_b;
        output_buffer_data = data_b_i;
        output_buffer_cs = cs_b & we_b;
        output_buffer_oe = 0;
        output_buffer_we = 1;

        if (cs_b) begin
            //next_flag = &addr_b;
            //flag_o = &addr_b;
        end
    end else begin
        input_buffer_addr = addr_a;
        input_buffer_data = data_a_i;
        input_buffer_cs = cs_a & we_a;
        input_buffer_oe = 0;
        input_buffer_we = 1;

        output_buffer_addr = addr_a;
        data_a_o = _output_buffer_data;
        output_buffer_cs = cs_a & ~we_a;
        output_buffer_oe = 1;
        output_buffer_we = 0;

        if (cs_a) begin
            //next_flag = &addr_a;
            flag_o = &addr_a & input_buffer_cs;
        end
    end

end

endmodule
