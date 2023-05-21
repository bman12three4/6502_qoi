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
size_t count;
pixel_t px, prev_px;
logic r_flag, w_flag;

typedef enum logic [1:0] {IDLE, RUN, READ, WRITE} state_t;
state_t state, next_state;

assign px.r = input_data[0];
assign px.g = input_data[1];
assign px.b = input_data[2];
assign px.a = input_data[3];

assign size[0*8 +: 8] = input_data[4];
assign size[1*8 +: 8] = input_data[5];
assign size[2*8 +: 8] = input_data[6];
assign size[3*8 +: 6] = input_data[7][5:0];

assign mode = input_data[7][6];
assign start = input_data[7][7];

assign output_data[4] = count[0*8 +: 8];
assign output_data[5] = count[1*8 +: 8];
assign output_data[6] = count[2*8 +: 8];
assign output_data[7][5:0] = count[3*8 +: 6];


assign output_data[7][6] = w_flag;
assign output_data[7][7] = r_flag;

assign data_o = output_data[addr];

always_comb begin
    if (cs) begin
        $display("QOI addr: %x", addr);
    end
end

always_ff @(posedge clk) begin
    if (cs) begin
        if (we) begin
            input_data[addr] <= data_i;
        end
    end
end

always_comb begin
    next_state = state;
    r_flag = '0;
    w_flag = '0;

    case (state)
        IDLE: begin
            if (start) begin
                next_state = READ;
            end
        end

        RUN: begin

        end

        READ: begin
            r_flag = '1;
        end

        WRITE: begin
            w_flag = '1;
        end
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        count <= '0;
    end else begin
        state <= next_state;
    end
end

endmodule