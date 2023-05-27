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

byte_t encoded_data;

index_t index;
pixel_t index_arr[64];

size_t size;
size_t count;
pixel_t next_px, px, next_prev_px, prev_px;
logic r_flag, w_flag;
logic working;

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

op_t op;

assign op[OP_RGB] = rgb_op;
assign op[OP_RGBA] = rgba_op;
assign op[OP_INDEX] = index_op;
assign op[OP_DIFF] = diff_op;
assign op[OP_LUMA] = luma_op;
assign op[OP_RUN] = run_op;

logic last_write, next_last_write;

logic [2:0] read_count, next_read_count;

typedef enum logic [1:0] {IDLE, RUN, READ, WRITE} state_t;
state_t state, next_state;

assign size[0*8 +: 8] = input_data[4];
assign size[1*8 +: 8] = input_data[5];
assign size[2*8 +: 8] = input_data[6];
assign size[3*8 +: 6] = input_data[7][5:0];

assign mode = input_data[3][6];
assign start = input_data[3][7];

assign output_data[4] = count[0*8 +: 8];
assign output_data[5] = count[1*8 +: 8];
assign output_data[6] = count[2*8 +: 8];
assign output_data[7][5:0] = count[3*8 +: 6];


assign output_data[3][7] = working;
assign output_data[3][6:4] = '0;
assign output_data[3][3:2] = read_count;
assign output_data[3][1] = w_flag;
assign output_data[3][0] = r_flag;

assign output_data[0] = encoded_data;

assign data_o = output_data[addr];

assign vr = px.r - prev_px.r;
assign vg = px.g - prev_px.g;
assign vb = px.b - prev_px.b;

assign vg_r = vr - vg;
assign vg_b = vb - vg;

always_ff @(posedge clk) begin
    if (cs) begin
        if (we) begin
            input_data[addr] <= data_i;
        end
    end
end

always_comb begin
    next_state = state;
    next_read_count = read_count;
    next_prev_px = prev_px;
    working = 0;
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

            if (run_match) begin
                next_run = run + 1;
                next_state = READ;
            end else begin
                next_read_count = '0;
                next_state = WRITE;
                next_last_write = '0;
            end
        end

        READ: begin
            r_flag = '1;
            next_px = px;
            if (we && cs) begin
                next_read_count = read_count + 1;
                if (read_count == 2'h3) begin
                    next_state = RUN;
                end
                next_px[8*read_count +: 8] = data_i;
            end
        end

        WRITE: begin
            next_last_write = last_write;
            w_flag = '1;

            if (~we & cs & addr == '0) begin
                next_read_count = read_count + 1;
                if (last_write) begin
                    next_prev_px = px;
                    next_read_count = '0;
                    next_state = READ;
                end
            end
            
            
            if (op[OP_INDEX]) begin
                if (cs && addr == '0) $display("In INDEX write case %d", read_count);
                encoded_data = 8'h00 | index;
                next_last_write = 1;
            end else if (op[OP_RGBA]) begin
                if (cs && addr == '0) $display("In RGBA write case %d", read_count);
                case (read_count)
                    0: encoded_data = 8'hff;
                    1: encoded_data = px.r;
                    2: encoded_data = px.g;
                    3: encoded_data = px.b;
                    4: begin
                        encoded_data = px.a;
                        next_last_write = 1;
                    end
                endcase
            end else if (op[OP_DIFF]) begin
                if (cs && addr == '0) $display("In DIFF write case %d", read_count);
                encoded_data = 8'h40 | (vr + 2) << 4 | (vg + 2) << 2 | (vb + 2);
                next_last_write = 1;
            end else if (op[OP_LUMA]) begin
                if (cs && addr == '0) $display("In DIFF write case %d", read_count);
                case (read_count)
                    0: encoded_data = 8'h80 | (vg + 32);
                    1: begin
                        encoded_data = (vg_r + 8) << 4 | (vg_b +  8);
                        next_last_write = 1;
                    end
                endcase 
            end else if (op[OP_RGB]) begin
                if (cs && addr == '0) $display("In RGB write case %d", read_count);
                case (read_count)
                    0: encoded_data = 8'hfe;
                    1: encoded_data = px.r;
                    2: encoded_data = px.g;
                    3: begin
                        encoded_data = px.b;
                        next_last_write = 1;
                    end
                endcase

            end else begin
                if (cs && addr == '0) $error("Undefined op: %x", op);
            end
        end
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        count <= '0;
        read_count <= '0;
        run <= '0;
        last_write <= '0;
        for (int i = 0; i < 64; i++) begin
            index_arr[i] <= '0;
        end
        prev_px <= '0;
    end else begin
        state <= next_state;
        px <= next_px;
        prev_px <= next_prev_px;
        index_arr[index] <= next_prev_px;
        read_count <= next_read_count;
        last_write <= next_last_write;
    end
end

endmodule