`define max(a,b) ((a) > (b) ? (a) : (b))

module Multiplier_booth #(
	parameter APPROX_TYPE	= 0,
	parameter APPROX_W		= 16,
	parameter WIDTH_A 		= 16,
	parameter WIDTH_B 		= 16,
	parameter WIDTH_MUL 	= WIDTH_A + WIDTH_B,
	parameter SIGNED 		= 0,
	parameter STAGE			= 0
)(
	input	wire					clk,
	input	wire					rst_n,
	input	wire					pip_en,
	input	wire	[WIDTH_A-1:0]	A,
	input	wire	[WIDTH_B-1:0]	B,

	output	wire	[WIDTH_MUL-1:0]	OUT
);

	parameter WIDTH = `max(WIDTH_A, WIDTH_B);	
	parameter cnt	= (WIDTH + 1)/2;			//Radix-4 only need n/2

	wire			[2:0]				Q;
	wire	signed	[WIDTH_MUL+1:0]		A_sign;
	wire			[WIDTH_B+2:0]		B_ext;
	wire								done;
	
	reg 	signed 	[WIDTH_MUL-1:0] 	OUT_final;
	reg		signed	[WIDTH_MUL-1:0]		product;
	reg				[5:0]				i;
	reg 	signed 	[WIDTH_MUL-1:0] 	pipe_reg [0:STAGE];
	integer 							p;

	assign 	Q = 	(i==0) 	? {B_ext[2*i+1], B_ext[2*i], 1'b0} :
		    		(i<cnt) ? {B_ext[2*i+1], B_ext[2*i], B_ext[2*i-1]}:
					3'b000;

	assign	A_sign 	= SIGNED ? $signed({{WIDTH_B{A[WIDTH_A-1]}} , A}) : $signed({{WIDTH_B{1'b0}}, A});	
	assign 	B_ext 	= SIGNED ? {{2{B[WIDTH_B-1]}}, B, 1'b0} : {2'b0, B, 1'b0};	
	assign	done	= (i == cnt);

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			product	<= {WIDTH_MUL{1'b0}};
			i	<= 6'b0;
			OUT_final	<= {WIDTH_MUL{1'b0}};
		end
		else if (pip_en) begin
			if(i<cnt) begin
				case(Q)
					3'b000: product	<= product;
					3'b001: product	<= $signed(product) + ($signed(A_sign) << (2*i));
					3'b010: product	<= $signed(product) + ($signed(A_sign) << (2*i));
					3'b011: product	<= $signed(product) + ($signed(A_sign) << (2*i+1));
					3'b100: product	<= $signed(product) - ($signed(A_sign) << (2*i+1));
					3'b101: product	<= $signed(product) - ($signed(A_sign) << (2*i));
					3'b110: product	<= $signed(product) - ($signed(A_sign) << (2*i));
					3'b111: product	<= product;
				endcase
				i <= i + 1'b1;
			end
			else if(i==cnt) begin
				if(APPROX_TYPE) begin
					OUT_final	<= {product[WIDTH_MUL-1:APPROX_W], {APPROX_W{1'b0}}};
				end
				else begin
					OUT_final	<= product;
				end

				i 	<= 6'b0;
				product <= {WIDTH_MUL{1'b0}};
			end
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
       		for(p = 0; p <= STAGE; p = p + 1) begin
				pipe_reg[p]		<= {WIDTH_MUL{1'b0}};
			end
		end
		else if (pip_en && done) begin
    		pipe_reg[0] <= OUT_final;
    		for (p = 1; p <= STAGE; p = p + 1) begin
        		pipe_reg[p] <= pipe_reg[p-1];
			end
		end
	end

	assign OUT = pipe_reg[STAGE];
endmodule
