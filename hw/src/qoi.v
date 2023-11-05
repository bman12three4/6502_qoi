`default_nettype none

module qoi #(
    parameter BITS = 16
)(
`ifdef USE_POWER_PINS
    inout vdd,	// User area 1 1.8V supply
    inout vss,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [63:0] la_data_in,
    output [63:0] la_data_out,
    input  [63:0] la_oenb,

    // IOs
    input  [BITS-1:0] io_in,
    output [BITS-1:0] io_out,
    output [BITS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);

assign wbs_ack_o = 0;
assign wbs_dat_o = 0;
assign irq = 0;
assign la_data_out = 0;


wire [7:0] data_in;
wire [7:0] data_out;
wire clk;
wire reset;
wire rwb;
wire cs;
wire oeb;
wire [2:0] address;

assign data_in = io_in[7:0];
assign io_out[7:0] = data_out;
assign io_out[15:8] = 8'h00;
assign reset = io_in[8];
assign clk = io_in[9];
assign rwb = io_in[10];
assign cs = io_in[11];
assign oeb = io_in[12];
assign address = io_in[15:13];

assign io_oeb = {8'hff, {8{oeb}}};


reg [7:0] input_data [0:7];
wire [7:0] output_data [0:7];

reg [7:0] encoded_data;

wire [29:0] size;
reg [29:0] count, next_count;
reg is_first, next_is_first;
wire mode, start;
reg r_flag, w_flag;
reg working;

reg [1:0] read_count, next_read_count;

reg [5:0] index;
reg [31:0] index_arr[0:63];
reg [31:0] index_val, next_index_val;

reg [31:0] next_px, px, next_prev_px, prev_px;

reg index_op;
reg run_op;
reg run_match;
reg rgba_op;
reg diff_op;
reg luma_op;
reg rgb_op;

reg [5:0] run, next_run, run_r, next_run_r;
wire signed [8:0] vr, vg, vb;
wire signed [8:0] vg_r, vg_b;

assign vr = px[7:0] - prev_px[7:0];
assign vg = px[15:8] - prev_px[15:8];
assign vb = px[23:16] - prev_px[23:16];

assign vg_r = vr - vg;
assign vg_b = vb - vg;

reg last_write, next_last_write;


// logic [5:0] {OP_RGB, OP_RGBA, OP_INDEX, OP_DIFF, OP_LUMA, OP_RUN } op_t;
localparam OP_RGB = 0;
localparam OP_RGBA = 1;
localparam OP_INDEX = 2;
localparam OP_DIFF = 3;
localparam OP_LUMA = 4;
localparam OP_RUN = 5;


reg [5:0] op_r, next_op;
wire [5:0] op;

assign op[OP_RGB] = rgb_op;
assign op[OP_RGBA] = rgba_op;
assign op[OP_INDEX] = index_op;
assign op[OP_DIFF] = diff_op;
assign op[OP_LUMA] = luma_op;
assign op[OP_RUN] = run_op;


assign data_out = output_data[address];

assign size[7:0] = input_data[3'h4];
assign size[15:8] = input_data[3'h5];
assign size[23:16] = input_data[3'h6];
assign size[29:24] = input_data[3'h7][5:0];

assign output_data[4] = count[0*8 +: 8];
assign output_data[5] = count[1*8 +: 8];
assign output_data[6] = count[2*8 +: 8];
assign output_data[7][5:0] = count[3*8 +: 6];
assign output_data[7][7:6] = 0;


assign output_data[3][7] = working;
assign output_data[3][6:4] = '0;
assign output_data[3][3:2] = read_count;
assign output_data[3][1] = w_flag;
assign output_data[3][0] = r_flag;

assign output_data[1] = 0;
assign output_data[2] = 0;

assign output_data[0] = encoded_data;


assign mode = input_data[3][6];
assign start = input_data[3][7];

// typedef enum logic [1:0] {IDLE, RUN, READ, WRITE} state_t;
// state_t state, next_state;

localparam IDLE  = 2'h0;
localparam RUN   = 2'h1;
localparam READ  = 2'h2;
localparam WRITE = 2'h3;


reg [1:0] state, next_state;


always @(posedge clk) begin
    if (cs & ~rwb) begin
        input_data[address] <= data_in;
    end
end



always @(*) begin
    next_state = state;
    next_read_count = read_count;
    next_count = count;
    next_prev_px = prev_px;
    next_is_first = is_first;
    working = 0;
    r_flag = 0;
    w_flag = 0;
    index = 0;

    run_match = 0;
    next_run = run;
    next_run_r = run_r;

    index_op = 0;
    run_op = 0;
    rgba_op = 0;
    rgb_op = 0;
    diff_op = 0;
    luma_op = 0;
    next_last_write = last_write;

    next_op = op_r;

    next_px = 0;

    index_val = index_arr[index];
    next_index_val = index_val;

    case (state)
        IDLE: begin
            if (cs && ~rwb && address == 3'h3 && data_in[3'h7]) begin
                next_state = READ;
            end
        end

        READ: begin
            r_flag = '1;
            next_px = px;
            if (~rwb && cs) begin
                next_read_count = read_count + 2'h1;
                if (read_count == 2'h3) begin
                    next_state = RUN;
                end
                next_px[8*read_count +: 8] = data_in;
            end
        end

        RUN: begin
            next_is_first = '0;

            // index = px.r * 3 + px.g * 5 + px.b * 7 + px.a * 11;
            index = px[7:0] * 3 + px[15:8] * 5 + px[23:16] * 7 + px[31:24] * 11;

            index_op = px == index_val;

            // rgba_op = px.a != prev_px.a;
            rgba_op = px[31:24] != prev_px[31:24];

            // Try to clean this up, does it really need 3 if statements?
            if (px == prev_px && !is_first) begin
                run_match = 1;
                if (run == 62) begin
                    next_run = 0;
                    run_op = 1;
                end else if (count == size - 30'h1) begin
                    run_op = 1;
                    next_run = run + 6'h1;
                    next_run_r = next_run;
                end else begin
                    run_op = 0;
                    next_run = run + 6'h1;
                    next_run_r = next_run;
                end
            end else begin
                run_op = (run > 6'h0);
                next_run = 0;
            end

            if (!run_op && ~index_op) begin
                next_index_val = px;
            end

            diff_op = (
                vr > -3 && vr < 2 &&
                vg > -3 && vg < 2 &&
                vb > -3 && vb < 2 &&
                // px.a == prev_px.a
                px[31:24] == prev_px[31:24]
            );

            luma_op = (
                vg_r >  -9 && vg_r <  8 &&
                vg   > -33 && vg   < 32 &&
                vg_b >  -9 && vg_b <  8 &&
                // px.a == prev_px.a
                px[31:24] == prev_px[31:24]
            );

            rgb_op = ~(diff_op | luma_op | index_op | rgba_op);

            if (run_match && !run_op) begin
                next_run = run + 1;
                next_read_count = '0;
                next_state = READ;
            end else begin
                next_read_count = '0;
                next_state = WRITE;
                next_last_write = '0;
            end

            if (!run_op) begin
                next_count = count + 30'h1;
            end

            next_op = op;
        end

        WRITE: begin
            next_last_write = last_write;
            w_flag = '1;

            if (rwb & cs & address == '0) begin
                next_read_count = read_count + 1;
                if (op_r[OP_RUN]) begin
                    next_state = RUN;
                end
                if (last_write) begin
                    next_prev_px = px;
                    next_read_count = '0;
                    next_state = READ;
                end
                if (count == size - 1) begin
                    next_state = IDLE;
                end
            end

            if (op_r[OP_RUN]) begin
                // if (cs && addr == '0) $display("In RUN write case %d", read_count);
                encoded_data = 8'hc0 | (run_r - 1);
            end else if (op_r[OP_INDEX]) begin
                // if (cs && addr == '0) $display("In INDEX write case %d", read_count);
                encoded_data = 8'h00 | index;
                next_last_write = 1;
            end else if (op_r[OP_RGBA]) begin
                // if (cs && addr == '0) $display("In RGBA write case %d", read_count);
                case (read_count)
                    0: encoded_data = 8'hff;
                    1: encoded_data = px[7:0];
                    2: encoded_data = px[15:8];
                    3: encoded_data = px[23:16];
                    4: begin
                        encoded_data = px[31:24];
                        next_last_write = 1;
                    end
                endcase
            end else if (op_r[OP_DIFF]) begin
                // if (cs && addr == '0) $display("In DIFF write case %d", read_count);
                encoded_data = 8'h40 | (vr + 2) << 4 | (vg + 2) << 2 | (vb + 2);
                next_last_write = 1;
            end else if (op_r[OP_LUMA]) begin
                // if (cs && addr == '0) $display("In DIFF write case %d", read_count);
                case (read_count)
                    0: encoded_data = 8'h80 | (vg + 32);
                    1: begin
                        encoded_data = (vg_r + 8) << 4 | (vg_b +  8);
                        next_last_write = 1;
                    end
                endcase 
            end else if (op_r[OP_RGB]) begin
                // if (cs && addr == '0) $display("In RGB write case %d", read_count);
                case (read_count)
                    0: encoded_data = 8'hfe;
                    1: encoded_data = px[7:0];
                    2: encoded_data = px[15:8];
                    3: begin
                        encoded_data = px[23:16];
                        next_last_write = 1;
                    end
                endcase

            end
        end

    endcase


    // TODO
    encoded_data = 8'h55;

end

always @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
        read_count <= 0;
        count <= 0;
        px <= 0;
        prev_px <= 0;
        op_r <= 0;
        run <= 0;
        run_r <= 0;
        is_first <= 1;
        last_write <= 0;
        for (integer i = 0; i < 64; i++) begin
            index_arr[i] <= 0;
        end
    end else begin
        px <= next_px;
        state <= next_state;
        read_count <= next_read_count;
        index_arr[index] <= next_index_val;
        count <= next_count;
        prev_px <= next_prev_px;
        op_r <= next_op;
        run <= next_run;
        run_r <= next_run_r;
        is_first <= next_is_first;
        last_write <= next_last_write;
    end
end


endmodule

