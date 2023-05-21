package qoi_types;

typedef struct packed {
    logic [7:0] r;
    logic [7:0] g;
    logic [7:0] b;
    logic [7:0] a;
} pixel_t;

typedef logic [7:0] byte_t;
typedef logic [2:0] addr_t;

typedef logic [29:0] size_t;

typedef logic [5:0] index_t;

endpackage : qoi_types