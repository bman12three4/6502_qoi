module qoi 
(
    input clk,
    input rst,
    input cs,
    input mem_cs,
    input we,

    input [7:0] data_i,
    output [7:0] data_o,

    input [9:0] addr
);

localparam IDLE = 0;
localparam READ_CPU = 1;
localparam READ = 2;
localparam RUN = 3;
localparam WRITE = 4;
localparam WRITE_CPU = 5;

reg [9:0] accel_rd_addr;
reg [9:0] next_accel_rd_addr;
reg [9:0] accel_wr_addr;
reg [9:0] next_accel_wr_addr;
reg [9:0] accel_addr;
reg [7:0] accel_data_o;
wire [7:0] accel_data_i;
wire [7:0] mem_data_o;
reg accel_cs, accel_we;

reg mem_sel;

wire mem_flag;

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

reg [7:0] input_data[7:0];
wire [7:0] output_data[7:0];

reg [7:0]  encoded_data;

reg [5:0] index;
reg [31:0]  index_arr[63:0];
reg [31:0] index_val;
reg [31:0] next_index_val;

wire [29:0] size;
reg [29:0]  count;
reg [29:0] next_count;
reg  is_first;
reg next_is_first;
reg [31:0] next_px,  next_prev_px;
reg [31:0] px, prev_px;
reg r_flag, w_flag;
reg read_wait_flag;
reg next_read_wait_flag;
reg final_flag;
reg working;

reg [5:0] run, run_r;
reg [5:0] next_run, next_run_r;

wire signed [8:0] vr, vg, vb;
wire  signed [8:0] vg_r, vg_b;

reg index_op;
reg run_op;
reg run_match;
reg rgba_op;
reg diff_op;
reg luma_op;
reg rgb_op;

wire [5:0] op;
reg [5:0] op_r, next_op;

localparam OP_RGB = 0;
localparam OP_RGBA = 1;
localparam OP_INDEX = 2;
localparam OP_DIFF = 3;
localparam OP_LUMA = 4;
localparam OP_RUN = 5;

assign op[0] = rgb_op;
assign op[1] = rgba_op;
assign op[2] = index_op;
assign op[3] = diff_op;
assign op[4] = luma_op;
assign op[5] = run_op;

reg last_write;
reg next_last_write;

reg [2:0] read_count;
reg [2:0] next_read_count;

reg [2:0] state, next_state;

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
assign output_data[3][5] = 1'b0;
assign output_data[3][4:2] = read_count;
assign output_data[3][1] = w_flag;
assign output_data[3][0] = r_flag;

assign output_data[1] = accel_wr_addr[7:0];
assign output_data[2][1:0] = accel_wr_addr[9:8];
assign output_data[2][7:2] = 6'b0;

assign output_data[0] = encoded_data;

reg mem_cs_q;
assign data_o = cs ? output_data[addr] : mem_cs_q ? mem_data_o : 8'hzz;

assign vr = px[7:0] - prev_px[7:0];
assign vg = px[15:8] - prev_px[15:8];
assign vb = px[23:16] - prev_px[23:16];

assign vg_r = vr - vg;
assign vg_b = vb - vg;

always @(posedge clk) begin
    if (cs) begin
        if (we) begin
            input_data[addr] <= data_i;
        end
    end
end

always @(*) begin
    accel_data_o = 0;
    next_accel_rd_addr = accel_rd_addr;
    next_accel_wr_addr = accel_wr_addr;
    accel_cs = 0;
    next_px = px;
    next_state = state;
    next_read_count = read_count;
    next_count = count;
    next_prev_px = prev_px;
    working = 0;
    r_flag = 0;
    w_flag = 0;
    next_read_wait_flag = 0;
    final_flag = 0;

    run_match = 0;
    next_run = run;
    next_run_r = run_r;

    next_op = op_r;

    index_val = index_arr[index];
    next_index_val = index_val;

    case (state)
        IDLE: begin
            if (cs && we && addr == 3 && data_i[7]) begin
                next_state = READ_CPU;
            end
        end

        READ_CPU: begin
            mem_sel = 0;
            r_flag = 1;

            if (mem_flag) begin
                if (count == 0) begin
                    next_state = READ;
                end else begin
                    next_state = RUN;
                end
            end
        end

        // This should not be so many if statements
        READ: begin
            mem_sel = 1;
            accel_cs = 1;
            accel_we = 0;
            next_px = px;

            if (read_wait_flag) begin
                next_accel_rd_addr = 0;
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
                if (accel_rd_addr == 10'h3ff && !(count == (size - 1))) begin
                    next_accel_rd_addr = accel_rd_addr;
                    next_read_wait_flag = 1;
                end
            end

            if (read_count > 0 && read_count <=3'h4) begin
                next_px[8*(read_count-1) +: 8] = accel_data_i;
            end

        end

        RUN: begin
            next_is_first = 0;

            index = px[7:0] * 3 + px[15:8] * 5 + px[23:16] * 7 + px[31:24] * 11;
            index_op = px == index_val;

            rgba_op = px[31:24] != prev_px[31:24];

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
                px[31:24] == prev_px[31:24]
            );

            luma_op = (
                vg_r >  -9 && vg_r <  8 &&
                vg   > -33 && vg   < 32 &&
                vg_b >  -9 && vg_b <  8 &&
                px[31:24] == prev_px[31:24]
            );

            rgb_op = ~(diff_op | luma_op | index_op | rgba_op);

            if (run_match && !run_op) begin
                next_run = run + 1;
                next_read_count = 0;
                next_state = READ;
            end else begin
                next_read_count = 0;
                next_state = WRITE;
            end

            if (!run_op) begin
                next_count = count + 1;
            end

            next_op = op;
        end

        WRITE: begin
            last_write = 0;
            
            mem_sel = 1;
            accel_cs = 1;
            accel_we = 1;

            next_accel_wr_addr = accel_wr_addr + 1;
            accel_addr = accel_wr_addr;

            next_read_count = read_count + 1;
            if (op_r[OP_RUN]) begin
                next_state = RUN;
            end

            if (count == (size - 1)) begin
                next_accel_wr_addr = accel_wr_addr;
            end

            if (accel_addr == 10'hff || count == (size - 1)) begin
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
                    1: encoded_data = px[7:0];
                    2: encoded_data = px[15:8];
                    3: encoded_data = px[23:16];
                    4: begin
                        encoded_data = px[31:24];
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
                    1: encoded_data = px[7:0];
                    2: encoded_data = px[15:8];
                    3: begin
                        encoded_data = px[23:16];
                        last_write = 1;
                    end
                endcase

            end else begin
                $error("Undefined op: %x", op);
            end

            if (last_write) begin
                next_prev_px = px;
                next_read_count = 0;
                next_state = READ;
            end

            accel_data_o = encoded_data;
        end

        WRITE_CPU: begin
            mem_sel = 0;
            w_flag = 1;
            if (count == (size - 1)) begin
                final_flag = 1;
            end

            if (addr == 10'h3ff && mem_cs == 1) begin
                next_state = WRITE;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        count <= 0;
        read_count <= 0;
        run <= 0;
        //last_write <= '0;
        for (integer i = 0; i < 64; i++) begin
            index_arr[i] <= 0;
        end
        prev_px <= 0;
        is_first <= 1;
        accel_rd_addr <= 0;
        accel_wr_addr <= 0;
        mem_cs_q <= 0;
        read_wait_flag <= 0;
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
    end
end

endmodule
