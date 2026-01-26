`define max(a,b) ((a) > (b) ? (a) : (b))

module Adder_gear_2c #(
	parameter 	R = 16,					//number of shifted bit
	parameter 	P = 16,					//overlap bit
	parameter 	WIDTH_A = 16,
	parameter 	WIDTH_B = 16
)(
	input	wire	[WIDTH_A-1:0]			A,
	input	wire	[WIDTH_B-1:0]			B,
	input	wire					Carry,	//do not use Carry

	output	wire	[`max(WIDTH_A, WIDTH_B)-1:0]	OUT
);

	parameter BITS 	= `max(WIDTH_A, WIDTH_B);
	parameter L 	= R + P;				//sub-adder length
	parameter k	= int'($ceil(1 + ((BITS-L)/R)));	//number of loops
	parameter N	= L + (k-1)*R;				//real width of sum

	integer					p;

	wire	signed	[N-1:0]			Sum;
	wire	signed	[BITS-1:0] 		a;
	wire	signed	[BITS-1:0] 		b;
	wire	signed	[k-1:0][L-1:0]		subadd_A; 
	wire	signed	[k-1:0][L-1:0]		subadd_B; 
	wire	signed	[k-1:0][L:0]		subadd_sum;
	wire	signed	[k-1:0][L-1:0]		subadd_real;
	wire	signed	[k-1:0]			subadd_one;	//predict carry if all bits  are 1
	wire		[k-1:0]			subadd_carry;	//local carry 
	wire		[k-1:0]			carry;
	
	assign	a = {{{BITS-WIDTH_A}{A[WIDTH_A-1]}}, A};	//sign extend
	assign	b = {{{BITS-WIDTH_B}{B[WIDTH_B-1]}}, B};	//sign extend

	genvar i,j;
	generate
		for(i=0; i<k; i++) begin
			assign subadd_A[i] = a[i*R+:L];
			assign subadd_B[i] = b[i*R+:L];

			//Sum the sub-adder
			assign subadd_sum[i] = subadd_A[i] + subadd_B[i];

			//Local Carry
			assign subadd_carry[i]	= subadd_sum[i][L];	//Highest bits of Sub-Adder

			if(i==0) begin
				assign carry[0] = subadd_carry[0];
				
				assign Sum[L-1:0] = subadd_sum[0][L-1:0];

				assign subadd_one[0] = 1'b0;
				
				assign subadd_real[0] = subadd_sum[0][L-1:0];
			end
			else begin
				assign subadd_one[i] = (&subadd_sum[i][L-1:P]) & subadd_sum[i][L-1];

				
				//Have carry if local carry is 1 or previous carry is 1 and every previous bit is 1
				assign carry[i] = subadd_carry[i] | (carry[i-1] & subadd_one[i]);
				
				//Equal sum if previous bit is not tottaly one or do not have carry
				for (j = 0; j < R; j++) begin
    					assign subadd_real[i][P+j] = (subadd_sum[i][P+j] & ~subadd_one[i]) | (~carry[i-1] & subadd_one[i]);
				end

				assign subadd_real[i][P-1:0] = {P{subadd_sum[i][L-1]}};
				
				assign Sum[P + i*R +:R] = subadd_real[i][L-1:P];

			end

		end
	endgenerate

	assign OUT = Sum[BITS-1:0]; 
endmodule