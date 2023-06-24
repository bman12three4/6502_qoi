package qoi_types;

typedef struct packed {
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] g;
    logic [7:0] r;
} pixel_t;

typedef logic [7:0] byte_t;
typedef logic [9:0] addr_t;

typedef logic [29:0] size_t;

typedef logic [5:0] index_t;

typedef enum logic [5:0] {OP_RGB, OP_RGBA, OP_INDEX, OP_DIFF, OP_LUMA, OP_RUN } op_t;

`define QOI_OP_RGB	 8'hfe
`define QOI_OP_RGBA	 8'hff
`define QOI_OP_INDEX 8'h00
`define QOI_OP_DIFF	 8'h40
`define QOI_OP_LUMA	 8'h80
`define QOI_OP_RUN	 8'hc0
`define QOI_MASK_2	8'hc0

endpackage : qoi_types