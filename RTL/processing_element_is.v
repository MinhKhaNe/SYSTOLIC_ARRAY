module processing_element_is #(
    parameter   WIDTH_A             = 16,
    parameter   WIDTH_B             = 16,
    parameter   WIDTH_MAC           = 48,
    parameter   WIDTH_T             = 2,
    parameter   ZERO_GATING_MULT    = 1,
    parameter   ZERO_GATING_ADD     = 1
)(
    input   wire                    clk,
    input   wire                    rst_n,
    input   wire    [WIDTH_A-1:0]   A,              //activation
    input   wire    [WIDTH_B-1:0]   B,              //weight
    input   wire    [WIDTH_MAC-1:0] MAC_IN,

    input   wire                    pipeline_en,
    input   wire                    reg_clear,
    input   wire                    cell_en,
    input   wire                    cell_sc_en,
    input   wire                    c_switch,
    input   wire                    cscan_en,

    input   wire    [WIDTH_T-1:0]   Thres,

    output  wire                    cell_out,

    output  wire    [WIDTH_MAC-1:0] MAC_OUT             //MAC
);

    parameter   ZERO_DETECTION  = ZERO_GATING_ADD | ZERO_GATING_MULT;

    reg     [WIDTH_MAC-1:0]         mac_reg;
    wire    [WIDTH_MAC-1:0]         mac_switch;
    reg                             cell_reg;
    reg                             pipeline_in;
    reg                             Zero_detected;

    assign  pipeline_in = pipeline_en & cell_en;
    assign  mac_switch  = c_switch ? mac_reg : MAC_IN;

    Zero_detection #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_T(WIDTH_T)
    ) zd0 (
        .A(A),
        .B(B),
        .Thres(Thres),
        .Zero(Zero_detected)
    );

    fma_wrapper_ofBSC #(
        .MUL_TYPE(MUL_TYPE),
        .M_APPROX(M_APPROX),
        .MM_APPROX(MM_APPROX),
        .ADD_TYPE(ADD_TYPE),
        .A_APPROX(A_APPROX),
        .AA_APPROX(AA_APPROX),
        .STAGES(STAGES_MUL),
        .INTERMEDIATE_PIPELINE_STAGE(INTERMEDIATE_PIPELINE_STAGE),
        .ZERO_GATING_MULT(ZERO_GATING_MULT),
        .FP_W(WIDTH_A)
    ) fma_i (
        .i_clk		        (clk),
        .i_rstn		        (rst_n && (reg_clear)),
        .i_a		        (a_zd_q),
        .i_b		        (b_zd_q),
        .i_c                (mac_q_zd),
        .i_msel             (mul_mux_sel),
        .i_pipeline_en      (pipeline_en),
        .o_c		        (mac_d)
    );

    
    //Handle cell_enable for next PE
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cell_reg        <= 1'b0;
        end
        else begin
            if(reg_clear)
                cell_reg    <= 1'b0;
            else 
                cell_reg    <= cell_sc_en;
        end
    end

    assign cell_out = cell_reg;

    //
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin

        end
        else begin

        end
    end

    assign

endmodule