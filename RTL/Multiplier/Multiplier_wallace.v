module Multiplier_wallace #(
    parameter APPROX	= 0,
	parameter APPROX_W	= 16,
	parameter WIDTH_A 	= 16,
	parameter WIDTH_B 	= 16,
	parameter WIDTH_MUL = 32,
	parameter SIGNED	= 0
)(
    input	wire 					clk,
	input	wire					rst_n,

	input	wire	[WIDTH_A-1:0]	A,
	input	wire	[WIDTH_B-1:0]	B,

	output	wire	[WIDTH_MUL-1:0]	OUT
);

	wire			[WIDTH_A-1:0]	a_abs;
	wire			[WIDTH_B-1:0]	b_abs;
	wire			[15:0]			a_wall;
	wire			[15:0]			b_wall;
	wire			[31:0]			product;
	reg				[WIDTH_MUL-1:0]	product_out;
	wire							a_sign, b_sign, pro_sign;

	assign	a_sign		= A[WIDTH_A-1];		//1st bit of A
	assign	b_sign		= B[WIDTH_B-1];		//1st bit of B
	assign 	pro_sign	= a_sign ^ b_sign;

	assign 	a_abs	= 	(!SIGNED) 	? 	A :
						(a_sign)	? 	(0-A) :
						A;
	
	assign 	b_abs	= 	(!SIGNED) 	? 	B :
						(b_sign)	? 	(0-B) :
						B;

	assign	a_wall	=	{1'b0, a_abs[WIDTH_A-2:0]};
	assign	b_wall	=	{1'b0, b_abs[WIDTH_B-2:0]};

	Wallace_16bit #(
		.APPROX(APPROX)
	) w0 (
		.A(a_wall),
		.B(b_wall),
		.OUT(product)
	);

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			product_out	<= {WIDTH_MUL{1'b0}};	
		end
		else begin
			if(SIGNED && pro_sign)
				product_out	<= (0 - product);
			else
				product_out	<= product;
		end
	end
 
	assign 	OUT = product_out;

endmodule