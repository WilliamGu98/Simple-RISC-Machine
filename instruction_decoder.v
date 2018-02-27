module instruction_decoder(in, nsel, opcode, op, ALUop, sximm5, sximm8, shift,
						   readnum, writenum);
	input [15:0] in;
	input [1:0] nsel;
	output [2:0] opcode;
	output [1:0] op;
	output [1:0] ALUop;
	output [15:0] sximm5;
	output [15:0] sximm8;
	output [1:0] shift;
	output reg [2:0] readnum;
	output reg [2:0] writenum;

	assign opcode = in[15:13]; //takes opcode from input to send to state machine
	assign op = in[12:11];     //takes op from input to send to to state machine
	assign ALUop = in[12:11];  //takes ALUop from input (same as op) to send to datapath
	assign sximm5 = {{11{in[4]}},in[4:0]}; //sign extend
	assign sximm8 = {{8{in[7]}},in[7:0]};  //sign extend
	assign shift = in[4:3]; //shift instruction to send to datapath
	
	always @(*) begin
		case (nsel)
			2'b00: //Put Rn into readnum and writenum
				begin
					readnum = in[10:8];
					writenum = in[10:8];
				end
			2'b01: //Put Rd into readnum and writenum
				begin
					readnum = in[7:5];
					writenum = in[7:5];
				end
			2'b10: //Put Rm into readnum and writenum
				begin
					readnum = in[2:0];
					writenum = in[2:0];
				end
			2'b11: //Put R6 (LR_IRQ) into readnum and writenum
				begin
					readnum = 3'b110;
					writenum = 3'b110;
				end
			default:
				begin
					readnum = 3'bx;
					writenum = 3'bx;
				end
		endcase
	end
endmodule