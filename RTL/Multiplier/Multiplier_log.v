`define max(a,b) ((a) > (b) ? (a) : (b))

module Multiplier_log #(
	parameter APPROX	= 0,
	parameter APPROX_W	= 16,
	parameter WIDTH_A 	= 16,
	parameter WIDTH_B 	= 16,
	parameter WIDTH_MUL = 32,
	parameter SIGNED	= 0,
	parameter STAGE		= 0
)(
	input	wire					clk,
	input	wire					rst_n,
	input	wire					pip_en,
	input	wire	[WIDTH_A-1:0]	A,
	input	wire	[WIDTH_B-1:0]	B,

	output	wire	[WIDTH_MUL-1:0]	OUT
);
	function automatic integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

	parameter WIDTH_LOGA	= 	clog2(WIDTH_A);
	parameter WIDTH_LOGB	= 	clog2(WIDTH_B);
	parameter WIDTH_F		= 	`max(WIDTH_A, WIDTH_B);
	parameter LOG_W			= 	`max(WIDTH_A + WIDTH_LOGA + 1, WIDTH_B + WIDTH_LOGB + 1);
	parameter K_W			= 	`max(WIDTH_LOGA, WIDTH_LOGB) + 1'b1;
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
	reg												carry_low;
	wire			[LOG_W-1:0]						log_a;
	wire			[LOG_W-1:0]						log_b;
	reg				[LOG_W:0]						log_sum;
	
	reg 	signed	[WIDTH_MUL-1:0]					product;
	wire 			[X_W-1:0]     					xprod;
	wire 			[LOG_W-X_W:0] 					kprod;
	wire 			[WIDTH_A-1:0] 					abs_a;
	wire 			[WIDTH_B-1:0] 					abs_b;
	reg 	signed 	[WIDTH_MUL-1:0] 				pipe_reg [0:STAGE];
	integer 										p;
	wire 	signed 	[WIDTH_MUL-1:0] 				product_sign;

	
	assign	a_sign 		= 	(~SIGNED) 		?	A :
					 		(A[WIDTH_A-1]) ? {1'b0, -$signed(A[WIDTH_A-2:0])} : 
					 		{1'b0, $signed(A[WIDTH_A-2:0])};

	assign	b_sign 		= 	(~SIGNED) 		?	B :
					 		(B[WIDTH_B-1]) ? {1'b0, -$signed(B[WIDTH_B-2:0])} : 
					 		{1'b0, $signed(B[WIDTH_B-2:0])};
	
	assign 	pro_sign 	= 	SIGNED & (A[WIDTH_A-1] ^ B[WIDTH_B-1]);

	assign  abs_a 		= 	(SIGNED && A[WIDTH_A-1]) ? (0-A) : A;
	assign  abs_b		= 	(SIGNED && B[WIDTH_B-1]) ? (0-B) : B;

	lopd #(
		.WIDTH_I(WIDTH_A),
		.WIDTH_L(WIDTH_LOGA)
	) la (
		.in(abs_a), 
		.out(ka)
	);

	lopd  #(
		.WIDTH_I(WIDTH_B),
		.WIDTH_L(WIDTH_LOGB)
	) lb (
		.in(abs_b), 
		.out(kb)
	);
	
	assign 	shift_posA 	= WIDTH_A - ka - 1;
	assign 	shift_posB 	= WIDTH_B - kb - 1;

	assign shifted_A 	= (a_sign << shift_posA);
	assign shifted_B 	= (b_sign << shift_posB);

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
			product = ( {1'b1, xprod} << (kprod - X_W));
		end
		else begin
			product = ( {1'b1, xprod} >> (X_W - kprod));
		end
	end

	assign product_sign 	= (SIGNED && (A[WIDTH_A-1] ^ B[WIDTH_B-1])) ? -product : product;

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
       		for(p = 0; p <= STAGE; p = p + 1) begin
				pipe_reg[p]		<= {WIDTH_MUL{1'b0}};
			end
		end
		else if (pip_en) begin
    		pipe_reg[0] <= product_sign;
    		for (p = 1; p <= STAGE; p = p + 1) begin
        		pipe_reg[p] <= pipe_reg[p-1];
			end
		end
	end

	assign OUT = pipe_reg[STAGE];
endmodule

