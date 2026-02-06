module processing_element_os #(                         //Output Sationary (Store MAC, transfer Weight and Activation)
    parameter   WIDTH_A             = 16,               //Width of A
    parameter   WIDTH_B             = 16,               //Width of B
    parameter   WIDTH_MAC           = 48,               //Width of MAC
    parameter   WIDTH_T             = 2,                //Width of threshold
    parameter   ZERO_GATING_MULT    = 1,                //
    parameter   ZERO_GATING_ADD     = 1,                //
    parameter   MM_APPROX           = 1,                //
    parameter   M_APPROX            = 1,                //
    parameter   AA_APPROX           = 1,                //
    parameter   A_APPROX            = 1,                //
    parameter   MUL_TYPE            = 0,                //Choosing Multiplier
    parameter   ADD_TYPE            = 0,                //Choosing Adder
    parameter   STAGE               = 0,                //Number of Stage of pipeline
    parameter   ARITHMETIC          = 0,
    parameter   SIGNED              = 0,

    parameter   INTERMEDIATE_PIPELINE_STAGE = 0

)(
    input   wire                    clk,
    input   wire                    rst_n,
    input   wire    [WIDTH_A-1:0]   act,                //activation 
    input   wire    [WIDTH_B-1:0]   wei,                //weight
    input   wire    [WIDTH_MAC-1:0] MAC_IN,             //transport value to next PE to push out

    input   wire                    pipeline_en,        //stimulate pipeline
    input   wire                    reg_clear,          //Clear Registers
    input   wire                    cell_en,            //
    input   wire                    cell_sc_en,         //
    input   wire                    c_switch,           //Switch value between internal Accumulate and input Accumulate (Off because Output Stationary)
    input   wire                    cscan_en,           //

    input   wire    [WIDTH_T-1:0]   Thres,              //Threshold for zero detection

    output  wire                    cell_out,           //Cell_enable output for next PE
    output  wire                    c_switch_out,

    output  wire    [WIDTH_A-1:0]   wei_out,            //Weight out
    output  wire    [WIDTH_B-1:0]   act_out,            //Activation Out
    output  wire    [WIDTH_MAC-1:0] MAC_out,            //do not flow out
);

    parameter   ZERO_DETECTION  = ZERO_GATING_ADD | ZERO_GATING_MULT;
    parameter   MUL_W           = (ARITHMETIC==0)   ?   (WIDTH_A+WIDTH_B) : WIDTH_MAC;

    reg     [WIDTH_MAC-1:0]         mac_reg;            //Always choosing local mac instead of Out MAC because of OS
    wire    [WIDTH_MAC-1:0]         mac_out_fma, mac_value, mac_out_adder;       
    // reg     [WIDTH_MAC-1:0]         pipe_mac [0:STAGE];    
    wire    [WIDTH_A-1:0]           act_zd;
    wire    [WIDTH_B-1:0]           wei_zd;
    reg     [WIDTH_A-1:0]           act_reg;
    reg     [WIDTH_B-1:0]           wei_reg;
    reg                             cell_reg;
    wire                            pipeline_in;
    wire                            Zero_detected;
    wire    [MUL_W-1:0]             mul_value;
    wire                            mul_mux_sel;
    wire                            zero_reg, mac_is_valid;
    reg     [STAGE:0]               pipe_valid, zero_pipe;
    wire                            acc_read_en;

    integer                         i;

    assign  mul_mux_sel     = 1'b0;                             //OUTPUT STATIONARY
    assign  mac_value       = mac_reg;
    assign  pipeline_in     = pipeline_en & cell_en;
    assign  c_switch_out    = 1'b0;                             //OS so do not need to switch MAC
    assign  wei_out         = wei_reg;
    assign  act_out         = act_reg;
    assign  MAC_out         = mac_is_valid      ? mac_reg : MAC_IN;     //If having mac_end signal, push local mac value out, otherwise it will be transfer station
    assign  act_zd          = zero_reg          ? {WIDTH_A{1'b0}} : act;
    assign  wei_zd          = zero_reg          ? {WIDTH_B{1'b0}} : wei;
    assign  mac_is_valid    = pipe_valid[STAGE];
    assign  zero_reg        = ZERO_DETECTION    ? Zero_detected : 1'b0;
    assign  acc_read_en     = mac_is_valid && ~zero_pipe[STAGE] && pipeline_in;


    Zero_detection #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_T(WIDTH_T)
    ) zd0 (
        .A(act),
        .B(wei),
        .Thres(Thres),
        .Zero(Zero_detected)
    );

    generate
        if (ARITHMETIC) begin
            fma_wrapper_ofBSC #(
                .MUL_TYPE(MUL_TYPE),
                .M_APPROX(M_APPROX),
                .MM_APPROX(MM_APPROX),
                .ADD_TYPE(ADD_TYPE),
                .A_APPROX(A_APPROX),
                .AA_APPROX(AA_APPROX),
                .STAGES(STAGE),
                .INTERMEDIATE_PIPELINE_STAGE(INTERMEDIATE_PIPELINE_STAGE),
                .ZERO_GATING_MULT(ZERO_GATING_MULT),
                .FP_W(WIDTH_A)
            ) fma_i (
                .i_clk		        (clk),
                .i_rstn		        (rst_n && (!reg_clear)),
                .i_a		        (act_zd),                   //after zero detection
                .i_b		        (wei_zd),                   //after zero detection
                .i_c                (mac_value),                 //after zero detection
                .i_msel             (mul_mux_sel),
                .i_pipeline_en      (pipeline_en),
                .o_c		        (mac_out_fma)
            );
        end 
        else begin
            Adder_generic #(
                .WIDTH_A(WIDTH_MAC),
                .WIDTH_B(MUL_W),
                .WIDTH_OUT(WIDTH_MAC),
                .AA_APPROX(AA_APPROX),
                .A_APPROX(A_APPROX),
                .ADD_TYPE(ADD_TYPE),
                .SIGNED(SIGNED)
            ) a0 (
                .A(mac_value),
                .B(mul_value),
                .Carry(0),
                .OUT(mac_out_adder)
            );

            Multiplier_generic #(
                .WIDTH_A(WIDTH_A),
                .WIDTH_B(WIDTH_B),
                .MM_APPROX(MM_APPROX),
                .M_APPROX(M_APPROX),
                .MUL_TYPE(MUL_TYPE),
                .WIDTH_MUL(WIDTH_A+WIDTH_B),
                .SIGNED(SIGNED),
                .STAGE(STAGE)
            ) m0 (
                .clk(clk),
                .rst_n(rst_n),
                .pipeline_en(pipeline_en),
                .A(act_zd),
                .B(wei_zd),
                .OUT(mul_value)
            );
        end
    endgenerate

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

    //When finish all STAGE, pipe_valid is HIGH
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pipe_valid  <= {(STAGE+1){1'b0}};
        end
        else if(pipeline_en) begin
            pipe_valid  <= {pipe_valid[STAGE-1:0], cell_en};    //Shift bit to check
        end
    end

    //Zero pipeline
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            zero_pipe  <= {(STAGE+1){1'b0}};
        end
        else if(pipeline_en) begin
            zero_pipe  <= {zero_pipe[STAGE-1:0], Zero_detected};    //Shift bit to check
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mac_reg <= {WIDTH_MAC{1'b0}};
        end
        else begin
            if(reg_clear) begin
                mac_reg <= {WIDTH_MAC{1'b0}};
            end
            else if (acc_read_en) begin
                mac_reg <= ARITHMETIC ? mac_out_fma : mac_out_adder;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            act_reg       <= {WIDTH_A{1'b0}};
            wei_reg       <= {WIDTH_B{1'b0}};
        end
        else begin
            if(reg_clear) begin
                act_reg       <= {WIDTH_A{1'b0}};
                wei_reg       <= {WIDTH_B{1'b0}};
            end
            else if(pipeline_in) begin
                act_reg       <= act;
                wei_reg       <= wei;
            end
        end
    end

    // always @(posedge clk or negedge rst_n) begin
    //     if(!rst_n) begin
    //         for(i = 0; i < STAGE; i = i + 1) begin
    //             pipe_mac[i]    <= {WIDTH_MAC{1'b0}};
    //         end
    //     end
    //     else if(pipeline_in) begin
    //         pipe_mac[0] <= mac_reg;
    //         for(i = 1; i < STAGE + 1; i = i + 1) begin
    //             pipe_mac[i]    <= pipe_mac[i-1];
    //         end
    //     end
    // end

endmodule
