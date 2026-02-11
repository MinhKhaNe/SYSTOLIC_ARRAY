module tb_processing_element;
    localparam  WIDTH_A             = 16;
    localparam  WIDTH_B             = 16;
    localparam  WIDTH_MAC           = 48;
    localparam  WIDTH_T             = 2;
    localparam  ZERO_GATING_MULT    = 1;
    localparam  ZERO_GATING_ADD     = 1;
    localparam  MM_APPROX           = 1;
    localparam  M_APPROX            = 1;
    localparam  AA_APPROX           = 1;
    localparam  A_APPROX            = 1;
    localparam  MUL_TYPE            = 0;
    localparam  ADD_TYPE            = 0;
    localparam  STAGE               = 5;
    localparam  ARITHMETIC          = 0;
    localparam  SIGNED              = 0;
    localparam  INTERMEDIATE_PIPELINE_STAGE = 0;
    
    //INPUT signals
    logic                   clk, rst_n;
    logic   [WIDTH_A-1:0]   act;
    logic   [WIDTH_B-1:0]   wei;
    logic   [WIDTH_MAC-1:0] MAC_in;
    logic                   pipeline_en, reg_clear, cell_en, cell_sc_en, c_switch, cscan_en;
    logic   [WIDTH_T-1:0]   Thres;

    //OUTPUT signals
    logic                   cell_out, c_switch_out;
    logic   [WIDTH_A-1:0]   act_out;
    logic   [WIDTH_B-1:0]   wei_out;
    logic   [WIDTH_MAC-1:0] MAC_out;

    initial begin
        clk = 0;
        forever #25 clk = ~clk;
    end

    processing_element_os #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B),
        .WIDTH_MAC(WIDTH_MAC),
        .WIDTH_T(WIDTH_T),
        .ZERO_GATING_MULT(ZERO_GATING_MULT),
        .ZERO_GATING_ADD(ZERO_GATING_ADD),
        .MM_APPROX(MM_APPROX),
        .M_APPROX(M_APPROX),
        .AA_APPROX(AA_APPROX),
        .A_APPROX(A_APPROX),
        .MUL_TYPE(MUL_TYPE),
        .ADD_TYPE(ADD_TYPE),
        .STAGE(STAGE),
        .ARITHMETIC(ARITHMETIC),
        .SIGNED(SIGNED),
        .INTERMEDIATE_PIPELINE_STAGE(INTERMEDIATE_PIPELINE_STAGE) 
    ) PE0 (
        .clk(clk),
        .rst_n(rst_n),
        .act(act),
        .wei(wei),
        .MAC_IN(MAC_in),
        .pipeline_en(pipeline_en),
        .reg_clear(reg_clear),
        .cell_en(cell_en),
        .cell_sc_en(cell_sc_en),
        .c_switch(c_switch),
        .cscan_en(cscan_en),
        .Thres(Thres),
        .cell_out(cell_out),
        .c_switch_out(c_switch_out),
        .wei_out(wei_out),
        .act_out(act_out),
        .MAC_out(MAC_out)
    );

    task automatic check_result(
        logic   [WIDTH_MAC-1:0] a,
        logic   [WIDTH_MAC-1:0] b
    );

        if(a !== b) begin
            $display("===== t=%0t FAILED! MAC does not match, Expected Result: %0d, Actual Result: %0d =====", $time, a, b);
        end
        else begin
            $display("===== t=%0t PASSED SUCCESSFULLY!!! =====", $time);
        end
    endtask

    task automatic check_act_wei(
        logic   [WIDTH_A-1:0] a,
        logic   [WIDTH_B-1:0] b
    );

        if(a !== b) begin
            $display("===== t=%0t FAILED! ACT or WEI does not match, Expected Result: %0h, Actual Result: %0h =====", $time, a, b);
        end
        else begin
            $display("===== t=%0t PASSED SUCCESSFULLY!!! =====", $time);
        end
    endtask

    task automatic check_bit(
        logic                  a,
        logic                  b
    );

        if(a !== b) begin
            $display("===== t=%0t FAILED! Result does not match, Expected Result: %0h, Actual Result: %0h =====", $time, a, b);
        end
        else begin
            $display("===== t=%0t PASSED SUCCESSFULLY!!! =====", $time);
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_processing_element);

        $monitor("Mac_out = %0d, Cell_en = %b, pipeline_en = %b",MAC_out, cell_en, pipeline_en);
        act = 16'h0; wei = 16'h0; MAC_in = 48'h0; 
        pipeline_en = 0; reg_clear = 0; cell_en = 0; cell_sc_en = 0; c_switch = 0; cscan_en = 0;
        Thres = 2'b00;

        $display("\n===== Case 1: Reset Check =====");
        rst_n = 0;
        act = 16'h1; wei = 16'h1; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1; reg_clear = 0;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b0, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h0, wei_out);
        check_act_wei(16'h0, act_out);
        check_result(48'h0, MAC_out);
        act = 16'h2; wei = 16'h2;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b0, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h0, wei_out);
        check_act_wei(16'h0, act_out);
        check_result(48'h0, MAC_out);

        $display("\n===== Case 2: Reg_clr Signal Check =====");
        rst_n = 1;
        reg_clear = 0; act = 16'h1; wei = 16'h1; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h1, wei_out);
        check_act_wei(16'h1, act_out);
        check_result(48'h1, MAC_out);
        reg_clear = 1;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b0, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h0, wei_out);
        check_act_wei(16'h0, act_out);
        check_result(48'h0, MAC_out);
        reg_clear = 0; act = 16'h2; wei = 16'h2; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h2, wei_out);
        check_act_wei(16'h2, act_out);
        check_result(48'h4, MAC_out);
        
        $display("\n===== Case 3: Cell_en Signal Check =====");
        reg_clear = 1;
        @(posedge clk);
        #1;
        reg_clear = 0;
        act = 16'h1; wei = 16'h1; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h1, wei_out);
        check_act_wei(16'h1, act_out);
        check_result(48'h1, MAC_out);
        act = 16'h2; wei = 16'h2; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h2, wei_out);
        check_act_wei(16'h2, act_out);
        check_result(48'hf, MAC_out);
        act = 16'h3; wei = 16'h3; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h3, wei_out);
        check_act_wei(16'h3, act_out);
        check_result(48'h39, MAC_out);

        cell_en = 0;
        act = 16'h4; wei = 16'h4; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h3, wei_out);
        check_act_wei(16'h3, act_out);
        check_result(48'h39, MAC_out);
        act = 16'h5; wei = 16'h5; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h3, wei_out);
        check_act_wei(16'h3, act_out);
        check_result(48'h39, MAC_out);
        act = 16'h6; wei = 16'h6; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h3, wei_out);
        check_act_wei(16'h3, act_out);
        check_result(48'h39, MAC_out);

        $display("\n===== Case 4: Pipeline_en Signal Check =====");
        reg_clear = 1;
        @(posedge clk);
        #1;
        reg_clear = 0; cell_en = 1;

        act = 16'h1; wei = 16'h1; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);                          //Wait for MAC_OUT come     (5 Stage pipeline and 3 stage delay)
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h1, wei_out);
        check_act_wei(16'h1, act_out);
        check_result(48'h1, MAC_out);

        //CHECK STOP
        act = 16'h2; wei = 16'h2; pipeline_en = 0; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        repeat (STAGE + 3) @(posedge clk);                          //OFF
        #1;                                                         
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h1, wei_out);
        check_act_wei(16'h1, act_out);
        check_result(48'h1, MAC_out);

        act = 16'h3; wei = 16'h3; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        @(posedge clk);                                             //Wait for MAC_OUT come
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h3, wei_out);
        check_act_wei(16'h3, act_out);
        check_result(48'h2, MAC_out);

        repeat (STAGE)@(posedge clk);                          
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h3, wei_out);
        check_act_wei(16'h3, act_out);
        check_result(48'd7, MAC_out);                             

        repeat (1)@(posedge clk);                               //7 clk 3-4-5-6-7-16-25    (pipeline_en = 1 high for 8 clk -> MAC calculates 7 times from 1-7 because reg_clear)
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h3, wei_out);
        check_act_wei(16'h3, act_out);
        check_result(48'd16, MAC_out);                              //7 clk counting 16-25-34-43-52-61-70
  
        //CHECK STOP
        act = 16'h4; wei = 16'h4; pipeline_en = 0; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        @(posedge clk);                          //OFF 
        #1;                                                 
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h3, wei_out);
        check_act_wei(16'h3, act_out);
        check_result(48'd16, MAC_out);

        repeat (STAGE + 2) @(posedge clk);                          //OFF   
        #1;                                                 
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h3, wei_out);
        check_act_wei(16'h3, act_out);
        check_result(48'd16, MAC_out);

        act = 16'h5; wei = 16'h5; pipeline_en = 1; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;
        @(posedge clk);                                             //Wait for MAC_OUT come
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h5, wei_out);
        check_act_wei(16'h5, act_out);
        check_result(48'd25, MAC_out);

        repeat (STAGE)@(posedge clk);                          
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h5, wei_out);
        check_act_wei(16'h5, act_out);
        check_result(48'd70, MAC_out); 

        repeat (1)@(posedge clk);                                  //7 clk 43-52-61-70-79-104-129    (pipeline_en = 1 high for 8 clk -> MAC calculates 7 times from 1-7)
        #1;
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h5, wei_out);
        check_act_wei(16'h5, act_out);
        check_result(48'd95, MAC_out);                             //7 clk counting 95-120-145-170-195-220-245

        //CHECK STOP
        act = 16'h6; wei = 16'h6; pipeline_en = 0; Thres = 2'b00; cscan_en = 0; cell_en = 1; cell_sc_en = 1;          
        @(posedge clk);                          //OFF                         
        #1;                    
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h5, wei_out);
        check_act_wei(16'h5, act_out);
        check_result(48'd95, MAC_out);

        repeat (STAGE + 2) @(posedge clk);                          //OFF   
        #1;                                                 
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h5, wei_out);
        check_act_wei(16'h5, act_out);
        check_result(48'd95, MAC_out);

        //CHECK final value of act and wei = 5 loop
        pipeline_en = 1;
        repeat (1) @(posedge clk);                          
        #1;                    
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h6, wei_out);
        check_act_wei(16'h6, act_out);
        check_result(48'd120, MAC_out);

        repeat (STAGE) @(posedge clk);                          
        #1;                    
        check_bit(1'b1, cell_out);
        check_bit(1'b0, c_switch_out);
        check_act_wei(16'h6, wei_out);
        check_act_wei(16'h6, act_out);
        check_result(48'd245, MAC_out);

        
        #10;
        $stop;
    end

endmodule
