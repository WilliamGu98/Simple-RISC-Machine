module shifter (ain,select,out);
  input [15:0] ain;
  input [1:0] select;
  output reg [15:0] out;

  
  //code for the shifter
  always @* begin
   
		case (select)
			//no shift
			2'b00:  out = ain;
			//shift left 1
			2'b01:	begin out[15:1] = ain[14:0]; out[0] = 1'b0; end
			//shift right 1
			2'b10:	begin out[14:0] = ain[15:1]; out[15] = 1'b0; end
			//shift right 1 with MSB copied
			2'b11:	begin out[14:0] = ain[15:1]; out[15] = ain[15]; end
			default: out = ain;
		endcase

	end
endmodule