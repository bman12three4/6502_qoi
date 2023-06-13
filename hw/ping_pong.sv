module ping_pong 
import qoi_types::*;
(
    input clk,
    input rst,

    output sel_o,

    input addr_t rd_addr,
    input addr_t wr_addr,
    output byte_t rd_data,
    input byte_t wr_data,

    input rd_cs, wr_cs
);

logic sel, next_sel;
logic rd_done, next_rd_done;
logic wr_done, next_wr_done;

assign sel_o = sel;

addr_t addr_a, addr_b;
byte_t data_a, data_b;
wire [7:0] _data_a, _data_b;
logic cs_a, cs_b;
logic we_a, we_b;
logic oe_a, oe_b;

assign _data_a = !oe_a ? data_a : 'hz;
assign _data_b = !oe_b ? data_b : 'hz;

ssram mem_A(
    .clk(clk),
    .addr(addr_a),
    .data(_data_a),
    .cs(cs_a),
    .we(we_a),
    .oe(oe_a)
);

ssram mem_B(    
    .clk(clk),
    .addr(addr_b),
    .data(_data_b),
    .cs(cs_b),
    .we(we_b),
    .oe(oe_b)
);

always @(posedge clk) begin
    if (rst) begin
        sel = '0;
        rd_done = '1;
        wr_done = '0;
    end else begin
        sel = next_sel;
        rd_done = next_rd_done;
        wr_done = next_wr_done;
    end
end



always_comb begin
    next_sel = sel;
    next_rd_done = rd_done;
    next_wr_done = wr_done;

    if (rd_addr == '1 && rd_cs) begin
        next_rd_done = '1;
    end

    if (wr_addr == '1 && wr_cs) begin
        next_wr_done = '1;
    end

    if (rd_done && wr_done) begin
        next_sel = ~sel;
        next_wr_done = '0;
        next_rd_done = '0;
    end

    if (sel) begin
        addr_a = rd_addr;
        cs_a = rd_cs;
        we_a = '0;
        oe_a = '1;
        rd_data = _data_a;

        addr_b = wr_addr;
        cs_b = wr_cs;
        we_b = '1;
        oe_b = '0;
        data_b = wr_data;
    end else begin
        addr_b = rd_addr;
        cs_b = rd_cs;
        we_b = '0;
        oe_b = '1;
        rd_data = _data_b;

        addr_a = wr_addr;
        cs_a = wr_cs;
        we_a = '1;
        oe_a = '0;
        data_a = wr_data;
    end
end

endmodule