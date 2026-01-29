`define max(a,b) ((a) > (b) ? (a) : (b))

module Multiplier_log #(
	parameter APPROX	= 0,
	parameter APPROX_W	= 16,
	parameter WIDTH_A 	= 16,
	parameter WIDTH_B 	= 16,
	parameter WIDTH_MUL = 32,
	parameter SIGNED	= 0
)(
	input	wire			clk,
	input	wire			rst_n,
	input	wire	[WIDTH_A-1:0]	A,
	input	wire	[WIDTH_B-1:0]	B,

	output	wire	[WIDTH_MUL-1:0]	OUT
);

	parameter WIDTH_LOGA	= 	$clog2(WIDTH_A);
	parameter WIDTH_LOGB	= 	$clog2(WIDTH_B);
	parameter WIDTH_F		= 	`max(WIDTH_A, WIDTH_B);
	parameter LOG_W			= 	`max(WIDTH_A + WIDTH_LOGA + 1, WIDTH_B + WIDTH_LOGB + 1);
	parameter K_W			= 	`max(kWIDTH_LOGA, WIDTH_LOGB) + 1'b1;
	parameter X_W			= 	WIDTH_F - 1'b1;

	wire			[WIDTH_LOGA-1:0]				ka;
	wire			[WIDTH_LOGB-1:0]				kb;
	wire			[WIDTH_LOGA + WIDTH_LOGB:0]		k_sum;
	wire			[3:0]							shift_posA;
	wire			[3:0]							shift_posB;
	wire			[WIDTH_A-1:0]					shifted_A;
	wire			[WIDTH_B-1:0]					shifted_B;
	wire			[WIDTH_A-2:0]					xa;
	wire			[WIDTH_B-2:0]					xb;
	wire	signed	[WIDTH_A-1:0]					a_sign;
	wire	signed	[WIDTH_B-1:0]					b_sign;
	wire	signed	[WIDTH_MUL-1:0]					pro_sign;
	wire											carry_low;
	wire			[LOG_W-1:0]						log_a;
	wire			[LOG_W-1:0]						log_b;
	wire			[LOG_W:0]						log_sum;
	
	reg 	signed	[WIDTH_MUL-1:0]					product;
	reg 	signed	[WIDTH_MUL-1:0]					out;
	
	assign	a_sign 		= 	(~SIGNED) 		?	A :
					 		(A[WIDTH_A-1]) ? {1'b0, -$signed(A[WIDTH_A-2:0])} : 
					 		{1'b0, $signed(A[WIDTH_A-2:0])};

	assign	b_sign 		= 	(~SIGNED) 		?	B :
					 		(B[WIDTH_B-1]) ? {1'b0, -$signed(B[WIDTH_B-2:0])} : 
					 		{1'b0, $signed(B[WIDTH_B-2:0])};

	assign	pro_sign	= 	B[WIDTH_B-1] * A[WIDTH_A-1];

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
	
	assign 	shift_posA 	= WIDTH_A - ka;
	assign 	shift_posB 	= WIDTH_B - kb;

	assign 	shifted_A	= (A << shift_posA);
	assign 	shifted_B	= (B << shift_posB);

	assign	xa			= shifted_A[WIDTH_A-1:1];
	assign	xb			= shifted_B[WIDTH_B-1:1];

	//1.xxxx (log ~= k + x)
	assign	log_a		= {ka, xa};	
	assign 	log_b		= {kb, xb};

	always @(*) begin
		if(APPROX) begin
			log_sum[APPROX_W-1:0] 		= {APPROX_W{1'b1}};

			carry_low					= log_a[APPROX_W] & log_b[APPROX_W];

			log_sum[WIDTH_F:APPROX_W]	= carry_low + log_a[WIDTH_A-1:APPROX_W] + log_b[WIDTH_B-1:APPROX_W];
		end
		else begin
			log_sum = log_a + log_b;
		end
	end

	//2^kprod x 2^xprod
	assign	xprod = log_sum[X_W-1:0];	//decide the accuracy (xa + xb)
	assign	kprod = log_sum[LOG_W:X_W]; //decide how large the prod is (ka + kb)

	always @(*) begin
		if(kprod > X_W) begin
			product	<= (xprod << (kprod - X_W));
		end
		else begin
			product	<= (xprod >> (X_W - kprod));
		end

		product[kprod] = 1'b1;
	end

	assign	OUT = 	(~SIGNED) ? product :
				  	(pro_sign) ? -$signed(product) :
					product;
endmodule

