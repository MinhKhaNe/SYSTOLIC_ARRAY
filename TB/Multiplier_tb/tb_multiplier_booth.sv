`timescale 1ns/1ps

module tb_multiplier_booth;

	parameter WIDTH_A   = 16;
	parameter WIDTH_B   = 16;
	parameter WIDTH_MUL = WIDTH_A + WIDTH_B;
	parameter SIGNED    = 0;
	parameter STAGE     = 2;
	parameter APPROX_TYPE = 0;
	parameter APPROX_W    = 8;

	localparam WIDTH = (WIDTH_A > WIDTH_B) ? WIDTH_A : WIDTH_B;
	localparam CNT   = (WIDTH + 1) / 2;
	localparam LATENCY = CNT + 1 + STAGE;

	logic clk;
	logic rst_n;
	logic pip_en;

	logic [WIDTH_A-1:0] A;
	logic [WIDTH_B-1:0] B;

	wire  [WIDTH_MUL-1:0] OUT;

	Multiplier_booth #(
		.APPROX_TYPE(APPROX_TYPE),
		.APPROX_W   (APPROX_W),
		.WIDTH_A    (WIDTH_A),
		.WIDTH_B    (WIDTH_B),
		.WIDTH_MUL  (WIDTH_MUL),
		.SIGNED     (SIGNED),
		.STAGE      (STAGE)
	) dut (
		.clk    (clk),
		.rst_n  (rst_n),
		.pip_en (pip_en),
		.A      (A),
		.B      (B),
		.OUT    (OUT)
	);

	always #5 clk = ~clk;


	task run_test(input int a, input int b);
		int exp;
	begin
		A = a;
		B = b;
		pip_en = 1'b1;

		exp = SIGNED ? ($signed(a) * $signed(b)) : (a * b);

		// wait for result
		repeat (LATENCY) @(posedge clk);

		if (APPROX_TYPE)
			exp = (exp >> APPROX_W) << APPROX_W;

		if (OUT !== exp) begin
			$display("FAIL: A=%0d B=%0d | OUT=%0d EXPECT=%0d",
			          a, b, $signed(OUT), exp);
		end
		else begin
			$display("PASS: A=%0d B=%0d | OUT=%0d",
			          a, b, $signed(OUT));
		end
	end
	endtask

	initial begin
		$dumpfile("tb_multiplier_booth.vcd");
		$dumpvars(0, tb_multiplier_booth);

		clk   = 0;
		rst_n = 0;
		pip_en = 0;
		A = 0;
		B = 0;

		// reset
		repeat (3) @(posedge clk);
		rst_n = 1;

		// wait after reset
		repeat (2) @(posedge clk);

		run_test(3, 5);
		run_test(7, 9);
		run_test(12, 4);
		run_test(15, 15);

		if (SIGNED) begin
			run_test(-3, 7);
			run_test(-8, -4);
			run_test(6, -5);
		end

		// random tests
		repeat (5) begin
			run_test($urandom_range(0, 100),
			         $urandom_range(0, 100));
		end

		$display("All tests finished");
		#20;
		$finish;
	end

endmodule
