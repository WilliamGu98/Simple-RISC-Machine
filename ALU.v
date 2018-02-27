module ALU (ain, bin, select, out, status);
	//Declare I/O
	input [15:0] ain;
	input [15:0] bin;
	input [1:0] select;
	output reg [15:0] out;
	output [2:0] status;

	//Assign status bits
	assign status[0] = ~|out; //Is out 0
	assign status[1] = out[15]; //Is out negative

	//Overflow status:
	// If pos. int plus pos. int is neg. OR
	// if neg. int plus neg. int is pos. OR
	// if pos. int minus neg. int is neg. OR
	// if neg. int minus pos. int is pos.
	assign status[2] = (~ain[15] & ~bin[15] & ~select[1] & ~select[0] &  out[15] ) | 
					   ( ain[15] &  bin[15] & ~select[1] & ~select[0] & ~out[15] ) |
					   (~ain[15] &  bin[15] & ~select[1] &  select[0] &  out[15] ) |
					   ( ain[15] & ~bin[15] & ~select[1] &  select[0] & ~out[15] );
  
	//ALU operations
	always @* begin
		case (select)
			//add
			2'b00:  out = ain+bin;
			//subtract
			2'b01:	out = ain-bin;
			//bitwise AND
			2'b10:	out = ain&bin;
			//bitwise NOT bin
			2'b11:	out = ~bin;
		
			default: out = ain;
		endcase
	end
endmodule