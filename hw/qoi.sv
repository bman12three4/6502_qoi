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

index_t index;
pixel_t index_arr[64];

size_t size;
size_t count;
pixel_t px, prev_px;
logic r_flag, w_flag;

logic [5:0] run, next_run;

logic signed [8:0] vr, vg, vb;
logic signed [8:0] vg_r, vg_b;

logic index_op;
logic run_op;
logic run_match;
logic rgba_op;
logic diff_op;
logic luma_op;
logic rgb_op;

typedef enum logic [1:0] {IDLE, RUN, READ, WRITE} state_t;
state_t state, next_state;

assign px.r = input_data[3];
assign px.g = input_data[2];
assign px.b = input_data[1];
assign px.a = input_data[0];

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

assign vr = px.r - prev_px.r;
assign vg = px.g - prev_px.g;
assign vb = px.b - prev_px.b;

assign vg_r = vr - vg;
assign vg_b = vb - vg;

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

    run_match = '0;

    case (state)
        IDLE: begin
            if (start) begin
                next_state = READ;
            end
        end

        RUN: begin
            index = px.r * 3 + px.g * 5 + px.b * 7 + px.a * 11;
            index_op = px == index_arr[index];
            rgba_op = px.a != prev_px.a;

            if (px == prev_px) begin
                if (run == 62 || size == count) begin
                    next_run = 0;
                    run_op = 1;
                end else begin
                    run_match = 1;
                    next_run = run + 1;
                end
            end else begin
                run_op = (run > 0);
                next_run = 0;
            end

            diff_op = (
                vr > -3 && vr < 2 &&
                vg > -3 && vg < 2 &&
                vb > -3 && vb < 2
            );

            luma_op = (
                vg_r >  -9 && vg_r <  8 &&
                vg   > -33 && vg   < 32 &&
                vg_b >  -9 && vg_b <  8
            );

            rgb_op = ~(diff_op | luma_op | index_op | rgba_op);

            if (!run_match) begin
                next_state = WRITE;
            end
        end

        READ: begin
            r_flag = '1;
            if (we && cs && addr == 3'h3) begin
                next_state = RUN;
            end
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
        run <= '0;
        for (int i = 0; i < 64; i++) begin
            index_arr[i] <= '0;
        end
        prev_px <= '0;
    end else begin
        state <= next_state;
    end
end

endmodule