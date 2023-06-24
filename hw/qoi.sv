module qoi 
import qoi_types::*;
(
    input clk,
    input rst,
    input cs,
    input mem_cs,
    input we,

    input byte_t data_i,
    output byte_t data_o,

    input addr_t addr
);

addr_t accel_rd_addr, next_accel_rd_addr;
addr_t accel_wr_addr, next_accel_wr_addr;
addr_t accel_addr;
byte_t accel_data_o, accel_data_i;
byte_t mem_data_o;
logic accel_cs, accel_we;

logic mem_sel;

logic mem_flag;

memory_unit u_memory_unit(
    .clk(clk),
    .rst(rst),

    .addr_a(addr),
    .data_a_i(data_i),
    .data_a_o(mem_data_o),
    .cs_a(mem_cs | mem_cs_q),
    .we_a(we),

    .addr_b(accel_addr),
    .data_b_i(accel_data_o),
    .data_b_o(accel_data_i),
    .cs_b(accel_cs),
    .we_b(accel_we),

    .sel(mem_sel),

    .flag_o(mem_flag)
);

byte_t input_data[8];
byte_t output_data[8];

byte_t encoded_data;
byte_t qoi_op, next_qoi_op;

index_t index;
pixel_t index_arr[64];
pixel_t index_val, next_index_val;

byte_t decode_buffer[4];
byte_t next_decode_buffer[4];

size_t size;
size_t count, next_count;
logic is_first, next_is_first;
pixel_t next_px, px, next_prev_px, prev_px;
logic r_flag, w_flag;
logic read_wait_flag, next_read_wait_flag;
logic final_flag;
logic working;

logic [5:0] run, next_run, run_r, next_run_r;

logic signed [8:0] vr, vg, vb;
logic signed [8:0] vg_r, vg_b;

logic index_op;
logic run_op;
logic run_match;
logic rgba_op;
logic diff_op;
logic luma_op;
logic rgb_op;

op_t op, op_r, next_op;

assign op[OP_RGB] = rgb_op;
assign op[OP_RGBA] = rgba_op;
assign op[OP_INDEX] = index_op;
assign op[OP_DIFF] = diff_op;
assign op[OP_LUMA] = luma_op;
assign op[OP_RUN] = run_op;

logic last_write, next_last_write;

logic [2:0] read_count, next_read_count;
logic [2:0] read_size, next_read_size;

typedef enum logic [2:0] {IDLE, RUN, READ_CPU, READ, WRITE, WRITE_CPU, OP_FETCH, OP_DECODE} state_t;
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
assign output_data[3][6] = final_flag;
assign output_data[3][5] = '0;
assign output_data[3][4:2] = read_count;
assign output_data[3][1] = w_flag;
assign output_data[3][0] = r_flag;

assign output_data[1] = accel_wr_addr[7:0];
assign output_data[2][1:0] = accel_wr_addr[9:8];
assign output_data[2][7:2] = '0;

assign output_data[0] = encoded_data;

logic mem_cs_q;
assign data_o = cs ? output_data[addr] : mem_cs_q ? mem_data_o : 'z;

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
    accel_data_o = '0;
    next_accel_rd_addr = accel_rd_addr;
    next_accel_wr_addr = accel_wr_addr;
    accel_cs = '0;
    next_px = px;
    next_state = state;
    next_read_count = read_count;
    next_count = count;
    next_prev_px = prev_px;
    working = 0;
    r_flag = '0;
    w_flag = '0;
    next_read_wait_flag = '0;
    final_flag = '0;

    run_match = '0;
    next_run = run;
    next_run_r = run_r;

    next_op = op_r;

    index_val = index_arr[index];
    next_index_val = index_val;

    for (int i = 0; i < 4; i++) begin
        next_decode_buffer[i] = decode_buffer[i];
    end

    case (state)
        IDLE: begin
            if (cs && we && addr == 3 && data_i[7]) begin
                next_state = READ_CPU;
            end
        end

        READ_CPU: begin
            mem_sel = 0;
            r_flag = '1;

            if (mem_flag) begin
                if (count == 0) begin
                    next_state = READ;
                end else begin
                    next_state = RUN;
                end

                if (mode == 1) begin
                    next_state = OP_FETCH;
                end
            end
        end

        // This should not be so many if statements
        READ: begin
            mem_sel = '1;
            accel_cs = '1;
            accel_we = '0;
            next_px = px;


            if (mode == 0) begin
                if (read_wait_flag) begin
                    next_accel_rd_addr = '0;
                    next_state = READ_CPU;
                end else begin
                    next_read_count = read_count + 1;

                    if (read_count < 3'h4) begin
                        next_accel_rd_addr = accel_rd_addr + 1;
                    end
                    accel_addr = accel_rd_addr;

                    if (read_count >= 3'h4) begin
                        next_state = RUN;
                    end
                    if (accel_rd_addr == '1 && !(count == (size - 1))) begin
                        next_accel_rd_addr = accel_rd_addr;
                        next_read_wait_flag = '1;
                    end
                end

                if (read_count > 0 && read_count <=3'h4) begin
                    next_px[8*(read_count-1) +: 8] = accel_data_i;
                end
            end else begin
                accel_addr = accel_rd_addr;
                next_read_count = read_count + 1;
                if (read_count < read_size) begin
                    next_accel_rd_addr = accel_rd_addr + 1;
                end
                if (read_count >= read_size) begin
                    next_state = RUN;
                end
                if (read_count > 0 && read_count <= read_size) begin
                    next_decode_buffer[read_count-1] = accel_data_i;
                end
            end

        end

        OP_FETCH: begin
            mem_sel = '1;
            accel_cs = '1;
            accel_we = '0;

            accel_addr = accel_rd_addr;
            next_accel_rd_addr = accel_rd_addr + 1;
            next_qoi_op = accel_data_i;
            next_state = OP_DECODE;
            //Read 1 byte from memory
        end

        OP_DECODE: begin
            casez (next_qoi_op) 
                8'b00??????: begin
                    $display("Read QOI_OP_INDEX");
                    next_state = RUN;
                end

                8'b01??????: begin
                    $display("Read QOI_OP_DIFF");
                    next_state = RUN;
                end

                8'b10??????: begin
                    $display("Read QOI_OP_LUMA");
                    next_read_size = 1;
                    next_read_count = '0;
                    next_state = READ;
                end

                8'b11111110: begin
                    $display("Read QOI_OP_RGB");
                    next_read_size = 3;
                    next_state = READ;
                end

                8'b11111111: begin
                    $display("Read QOI_OP_RGBA");
                    next_read_size = 4;
                    next_read_count = '0;
                    next_state = READ;
                end

                8'b11??????: begin
                    $display("Read QOI_OP_RUN");
                    next_state = RUN;
                end
            endcase
        end

        RUN: begin
            next_is_first = '0;

            index = px.r * 3 + px.g * 5 + px.b * 7 + px.a * 11;

            if (mode == 0) begin
                index_op = px == index_val;

                rgba_op = px.a != prev_px.a;

                // Try to clean this up, does it really need 3 if statements?
                if (px == prev_px && !is_first) begin
                    run_match = 1;
                    if (run == 62) begin
                        next_run = 0;
                        run_op = 1;
                    end else if (count == size - 1) begin
                        run_op = 1;
                        next_run = run + 1;
                        next_run_r = next_run;
                    end else begin
                        run_op = 0;
                        next_run = run + 1;
                        next_run_r = next_run;
                    end
                end else begin
                    run_op = (run > 0);
                    next_run = 0;
                end

                if (!run_op && ~index_op) begin
                    next_index_val = px;
                end

                diff_op = (
                    vr > -3 && vr < 2 &&
                    vg > -3 && vg < 2 &&
                    vb > -3 && vb < 2 &&
                    px.a == prev_px.a
                );

                luma_op = (
                    vg_r >  -9 && vg_r <  8 &&
                    vg   > -33 && vg   < 32 &&
                    vg_b >  -9 && vg_b <  8 &&
                    px.a == prev_px.a
                );

                rgb_op = ~(diff_op | luma_op | index_op | rgba_op);

                if (run_match && !run_op) begin
                    next_run = run + 1;
                    next_read_count = '0;
                    next_state = READ;
                end else begin
                    next_read_count = '0;
                    next_state = WRITE;
                end

                if (!run_op) begin
                    next_count = count + 1;
                end

                next_op = op;
            end else begin
                $display("Run in mode 1 is not supported");
                next_state = OP_FETCH;
            end
        end

        WRITE: begin
            last_write = '0;
            
            mem_sel = '1;
            accel_cs = '1;
            accel_we = '1;

            next_accel_wr_addr = accel_wr_addr + 1;
            accel_addr = accel_wr_addr;

            if (mode == 0) begin
                next_read_count = read_count + 1;
                if (op_r[OP_RUN]) begin
                    next_state = RUN;
                end

                if (count == (size - 1)) begin
                    next_accel_wr_addr = accel_wr_addr;
                end

                if (accel_addr == '1 || count == (size - 1)) begin
                    next_state = WRITE_CPU;
                end

                if (op_r[OP_RUN]) begin
                    $display("In RUN write case %d", read_count);
                    encoded_data = 8'hc0 | (run_r - 1);
                end else if (op_r[OP_INDEX]) begin
                    $display("In INDEX write case %d", read_count);
                    encoded_data = 8'h00 | index;
                    last_write = 1;
                end else if (op_r[OP_RGBA]) begin
                    $display("In RGBA write case %d", read_count);
                    case (read_count)
                        0: encoded_data = 8'hff;
                        1: encoded_data = px.r;
                        2: encoded_data = px.g;
                        3: encoded_data = px.b;
                        4: begin
                            encoded_data = px.a;
                            last_write = 1;
                        end
                    endcase
                end else if (op_r[OP_DIFF]) begin
                    $display("In DIFF write case %d", read_count);
                    encoded_data = 8'h40 | (vr + 2) << 4 | (vg + 2) << 2 | (vb + 2);
                    last_write = 1;
                end else if (op_r[OP_LUMA]) begin
                    $display("In DIFF write case %d", read_count);
                    case (read_count)
                        0: encoded_data = 8'h80 | (vg + 32);
                        1: begin
                            encoded_data = (vg_r + 8) << 4 | (vg_b +  8);
                            last_write = 1;
                        end
                    endcase 
                end else if (op_r[OP_RGB]) begin
                    $display("In RGB write case %d", read_count);
                    case (read_count)
                        0: encoded_data = 8'hfe;
                        1: encoded_data = px.r;
                        2: encoded_data = px.g;
                        3: begin
                            encoded_data = px.b;
                            last_write = 1;
                        end
                    endcase

                end else begin
                    $error("Undefined op: %x", op);
                end

                if (last_write) begin
                    next_prev_px = px;
                    next_read_count = '0;
                    next_state = READ;
                end

                accel_data_o = encoded_data;
            end else begin
                $display("Write in mode 1 is not supported");
            end
        end

        WRITE_CPU: begin
            mem_sel = 0;
            w_flag = '1;
            if (count == (size - 1)) begin
                final_flag = '1;
            end

            if (addr == '1 && mem_cs == '1) begin
                next_state = WRITE;
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
        //last_write <= '0;
        for (int i = 0; i < 64; i++) begin
            index_arr[i] <= '0;
        end
        for (int i = 0; i < 4; i++) begin
            decode_buffer[i] <= '0;
        end
        prev_px <= '0;
        is_first <= '1;
        accel_rd_addr <= '0;
        accel_wr_addr <= '0;
        mem_cs_q <= '0;
        read_wait_flag <= '0;
        read_size <= '0;
    end else begin
        state <= next_state;
        px <= next_px;
        prev_px <= next_prev_px;
        index_arr[index] <= next_index_val;
        read_count <= next_read_count;
        //last_write <= next_last_write;
        run <= next_run;
        run_r <= next_run_r;
        op_r <= next_op;
        count <= next_count;
        is_first <= next_is_first;
        accel_wr_addr <= next_accel_wr_addr;
        accel_rd_addr <= next_accel_rd_addr;
        mem_cs_q <= mem_cs;
        read_wait_flag <= next_read_wait_flag;
        qoi_op <= next_qoi_op;
        for (int i = 0; i < 4; i++) begin
            decode_buffer[i] <= next_decode_buffer[i];
        end
        read_size <= next_read_size;
    end
end

endmodule