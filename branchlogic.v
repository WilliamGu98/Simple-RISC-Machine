module branchlogic (PC, cond, sximm8, V, N, Z, PCout);
	input [8:0] PC;
	input [2:0] cond;
	input [8:0] sximm8;
	input V, N, Z;
	output reg [8:0] PCout;

	always @(*) begin
		casex({cond, V, N, Z})
			//B
			6'b000_xxx: PCout = PC + sximm8;
			
			//BEQ
			6'b001_xx1: PCout = PC + sximm8;

			//BNE
			6'b010_xx0: PCout = PC + sximm8;

			//BLT
			6'b011_10x: PCout = PC + sximm8;
			6'b011_01x: PCout = PC + sximm8;

			//BLE
			6'b100_10x: PCout = PC + sximm8;
			6'b100_01x: PCout = PC + sximm8;
			6'b100_xx1: PCout = PC + sximm8;

			//BL
			6'b111_xxx: PCout = PC + sximm8;

			default: PCout = PC;
		endcase
	end

endmodule
