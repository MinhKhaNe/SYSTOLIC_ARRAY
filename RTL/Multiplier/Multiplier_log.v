module Multiplier_log #(
	parameter WIDTH_A 	= 16,
	parameter WIDTH_B 	= 16,
	parameter WIDTH_MUL 	= 32,
	parameter SIGNED	= 0
)(
	input	wire			clk,
	input	wire			rst_n,
	input	wire	[WIDTH_A-1:0]	A,
	input	wire	[WIDTH_B-1:0]	B,

	output	wire	[WIDTH_MUL-1:0]	OUT
);

	parameter WIDTH_LOGA	= $clog2(WIDTH_A);
	parameter WIDTH_LOGB	= $clog2(WIDTH_B);

	wire		[WIDTH_LOGA-1:0]	ka;
	wire		[WIDTH_LOGB-1:0]	kb;
	wire		[WIDTH_A-1:0]		fa;
	wire		[WIDTH_B-1:0]		fb;
	wire	signed	[WIDTH_A-1:0]		a_sign;
	wire	signed	[WIDTH_B-1:0]		b_sign;
	wire	signed	[WIDTH_MUL-1:0]		pro_sign;
	
	assign	a_sign = SIGNED ? {} : {};
	assign	b_sign = SIGNED ? {} : {};

	lopd la #(
		.WIDTH_I(WIDTH_A),
		.WIDTH_L(WIDTH_LOGA)
	)(
		.in(A),
		.out(ka)
	);

	lopd lb #(
		.WIDTH_I(WIDTH_B),
		.WIDTH_L(WIDTH_LOGB)
	)(
		.in(B),
		.out(kb)
	);
	
	assign 	fa = (A >> ka) - 1;
	assign	fb = (B << ka) - 1;

endmodule

