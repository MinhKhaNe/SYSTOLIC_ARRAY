module processing_element_ws #(
    parameter   WIDTH_A     = 16,
    parameter   WIDTH_B     = 16,
    parameter   WIDTH_MUL   = 32
)(
    input   wire                    clk,
    input   wire                    rst_n,
    input   wire    [WIDTH_A-1:0]   A,                  //activation
    input   wire    [WIDTH_B-1:0]   B,                  //weight

    input   wire                    pipeline_en,
    input   wire                    

    output  wire    [WIDTH_MUL-1:0] OUT                 //MAC
);



endmodule