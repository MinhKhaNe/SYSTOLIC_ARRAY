module lopd(
	parameter WIDTH_I = 16,
	parameter WIDTH_L = $clog2(WIDTH_I)
)(
	input	wire	[WIDTH_I-1:0]	in,

	output	reg	[WIDTH_L-1:0]	out
);
	integer			i;

	always @(*) begin
		for(i=0; i<WIDTH_I; i=i+1) begin
			if(in[i]) 
				out = i;
		end
	end

endmodule
