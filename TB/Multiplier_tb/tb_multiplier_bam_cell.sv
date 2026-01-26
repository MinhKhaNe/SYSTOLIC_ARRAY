`timescale 1ns/1ps

module tb_Multiplier_bam;

	localparam WIDTH_A  = 8;
	localparam WIDTH_B  = 8;
	localparam WIDTH_OUT = 16;

	reg clk;
	reg rst_n;
	reg  [WIDTH_A-1:0] A;
	reg  [WIDTH_B-1:0] B;
	wire [WIDTH_OUT-1:0] OUT;


	Multiplier_bam #(
		.WIDTH_A(WIDTH_A),
		.WIDTH_B(WIDTH_B),
		.WIDTH_OUT(WIDTH_OUT),
		.SIGNED(1),    
		.VBL(0),
		.HBL(0)
	) dut (
		.clk(clk),
		.rst_n(rst_n),
		.A(A),
		.B(B),
		.OUT(OUT)
	);

	always #5 clk = ~clk;  

	task check;
	  input signed [WIDTH_A-1:0] a;
	  input signed [WIDTH_B-1:0] b;
	  reg   signed [WIDTH_OUT-1:0] golden;
    
    begin
	    A = a;
	    B = b; 
	    @(posedge clk);  
	    #1 golden = a * b;
	    $display("A=%0d  B=%0d  | OUT=%0d  GOLD=%0d %s",
	      a, b, $signed(OUT), golden,
	      ($signed(OUT) === golden) ? "OK" : "FAIL");

	    if ($signed(OUT) !== golden) begin
		    $stop;
	    end
    end
    endtask

	initial begin
		$dumpfile("tb_Multiplier_bam.vcd");
		$dumpvars(0, tb_Multiplier_bam);

		clk = 0;
		rst_n = 0;
		A = 0;
		B = 0;

		repeat(2) @(posedge clk);
		rst_n = 1;
		check(5, 3);
		check(7, 2);
		check(15, 1);
		check(-5, 3);
		check(-5, -7);
		check(-1, 1);
		check(1, -1);
		repeat (20) begin
			check($random, $random);
		end
		$finish;
	end

endmodule
