`timescale 1ns/1ps

module tb_adder_gear_2c;

    localparam int WIDTH_A = 4;
    localparam int WIDTH_B = 8;
    localparam int R = 4;
    localparam int P = 4;

    localparam int BITS = (WIDTH_A > WIDTH_B) ? WIDTH_A : WIDTH_B;

    logic   [WIDTH_A-1:0]  A;
    logic   [WIDTH_B-1:0]  B;
    logic                   Carry;

    logic   [BITS-1:0]      OUT;

    Adder_gear_2c #(
        .R(R),
        .P(P),
        .WIDTH_A(WIDTH_A),
        .WIDTH_B(WIDTH_B)
    ) dut (
        .A(A),
        .B(B),
        .Carry(Carry),
        .OUT(OUT)
    );

    task automatic display_result();
		$display(
			"\nA=%0d, B=%0d, Carry=%b, OUT=%0d", $signed(A), $signed(B), Carry, $signed(OUT)
		);
		$display(
			"A=%b, B=%b, Carry=%b, OUT=%b", $signed(A), $signed(B), Carry, OUT
		);
	endtask

    initial begin
        $dumpfile("tb_adder_gear_2c.vcd");
        $dumpvars(0, tb_adder_gear_2c);

        A = 4'sd5;
        B = 8'sd3;
        Carry = 0;
        #1 display_result();

        A = -4'sd5;
        B = 8'sd3;
        Carry = 0;
        #1 display_result();

        A = -4'sd5;
        B = -8'sd7;
        Carry = 0;
        #1 display_result();

        A = -4'sd1;
        B = 8'sd1;
        Carry = 0;
        #1 display_result();

        A = -4'sd1;
        B = -8'sd1;
        Carry = 1;
        #1 display_result();

        A = -4'sd20;
        B = -8'sd40;
        Carry = 1;
        #1 display_result();

        A = 4'sd7;
        B = 8'sd1;
        Carry = 0;
        #1 display_result();

        A = -4'sd8;
        B = -8'sd1;
        Carry = 0;
        #1 display_result();

        #1 $finish;
    end

endmodule