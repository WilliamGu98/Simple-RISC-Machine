//Memory command encodings
`define MREAD  2'b01
`define MWRITE 2'b10

//State encodings:
`define SW 6

`define Reset 6'd0

`define IF1 6'd1

`define IF2 6'd2

`define UpdatePC 6'd3

`define Decode 6'd4

`define MovRn0 6'd5

`define MovRd0 6'd6
`define MovRd1 6'd7
`define MovRd2 6'd8

`define AluAdd0 6'd9
`define AluAdd1 6'd10
`define AluAdd2 6'd11
`define AluAdd3 6'd12

`define AluCmp0 6'd13
`define AluCmp1 6'd14
`define AluCmp2 6'd15

`define AluAnd0 6'd16
`define AluAnd1 6'd17
`define AluAnd2 6'd18
`define AluAnd3 6'd19

`define AluMvn0 6'd20
`define AluMvn1 6'd21
`define AluMvn2 6'd22

`define LDR0 6'd23
`define LDR1 6'd24
`define LDR2 6'd25
`define LDR3 6'd26
`define LDR4 6'd27

`define STR0 6'd28
`define STR1 6'd29
`define STR2 6'd30
`define STR3 6'd31
`define STR4 6'd32

`define Branch 6'd33

`define BL1 6'd34
`define BL2 6'd35

`define BLX1 6'd36
`define BLX2 6'd37

`define BX1 6'd38

`define IRS1 6'd39
`define IRS2 6'd40

`define Halt 6'd41


module state_machine(clk, reset, opcode, op, nsel, vsel, write, loada, loadb, interrupt,
					 asel, bsel, loadc, loads, load_ir, load_pc, select_pc, addr_sel, mem_cmd, load_addr, is_halt);

	input clk, reset, interrupt;
	input [2:0] opcode;
	input [1:0] op;

	output [1:0] nsel; //00->Rn, 01->Rd, 10->Rm, 11->R6 (LR_IRQ)
	output [1:0] vsel; //00->mdata, 01->sximm8, 10->PC, 11->datapath_out

	output write, loada, loadb, asel, bsel, loadc, loads;

	//New for lab7
	output load_ir, load_pc, addr_sel, load_addr;
	output [1:0] mem_cmd;
	output [2:0] select_pc; //000->PC+1, 001->Reset, 010->Logic Block (in cpu), 011->Read from regfile, 100->Set PC to IRS_start

	output is_halt; //Only 1 if in halt state

	wire mask, loadmask, nextmask; //For interrupts

	//Wires for determining states
	wire [`SW-1:0] p, next_state, next_state_reset;

	//Reg for storing the next state and outputs
	reg [(`SW+23)-1:0] next;

	//Instantiate flipflop for state machine
	vDFF #(`SW) state_machine (.clk(clk), .in(next_state_reset), .out(p));

	//Instantiate load_enable for loading mask
	load_enable #(1) MASK_LOAD (.clk(clk), .en(loadmask), .in(nextmask), .out(mask)) ;

	//If reset is 1 for any clk, return to wait state
	assign next_state_reset = reset ? `Reset : next_state;

	//Assign next state and all current outputs in specified order
	assign {next_state, nsel, vsel, write, loada, loadb, asel, bsel, loadc, loads,
			 select_pc, load_pc, addr_sel, mem_cmd, load_ir, load_addr, is_halt, nextmask, loadmask} = next;

	//Comb. logic for selecting next state and for choosing next outputs
	always@(*) begin
		casex ({p, opcode, op, interrupt, mask})
			//In reset state, reset and load pc
			{`Reset, 7'bxxxxx_xx}: next = {`IF1, 23'b00_00_0_00_00_00__001_1_0_00_0_0_0_01};

			//In IF1 state, select address and memory command
			{`IF1, 7'bxxxxx_0x}: next = {`IF2, 23'b00_00_0_00_00_00__000_0_1_01_0_0_0_00}; //(Mem cmd is READ)
			{`IF1, 7'bxxxxx_x1}: next = {`IF2, 23'b00_00_0_00_00_00__000_0_1_01_0_0_0_00};

			//INTERRUPT STAGES
			//If interrupt conds. are satisfied:
			{`IF1,  7'bxxxxx_10}: next = {`IRS1, 23'b11_10_1_00_00_00__000_0_0_00_0_0_0_11}; // Save PC in R6 (LR_IRQ), set mask to 1
			{`IRS1, 7'bxxxxx_xx}: next = {`IRS2, 23'b00_00_0_00_00_00__100_1_0_00_0_0_0_00}; // Set PC to IRS_start

			{`IRS2, 7'bxxxxx_0x}: next = {`IF1,  23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; // Interrupt is deasserted
			{`IRS2, 7'bxxxxx_1x}: next = {`IRS2, 23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; // Stay here until interrupt is deasserted


			//In IF2 state, select address, memory command, and load instr register
			{`IF2, 7'bxxxxx_xx}: next = {`UpdatePC, 23'b00_00_0_00_00_00__000_0_1_01_1_0_0_00}; //(Mem cmd is read)

			//In IF2 state, select address, memory command, and load instr register
			{`UpdatePC, 7'bxxxxx_xx}: next = {`Decode, 23'b00_00_0_00_00_00__000_1_0_00_0_0_0_00};

			//In decode state, the op and opcode matter for next state and need to be maintained
			//for the entire instruction
			{`Decode, 7'b11010_xx}: next = {`MovRn0,  23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform MOV Rn,#<im8>
			{`Decode, 7'b11000_xx}: next = {`MovRd0,  23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform MOV Rd,Rm{,<sh_op>}
			{`Decode, 7'b10100_xx}: next = {`AluAdd0, 23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform ADD Rd,Rn,Rm{,<sh_op>}
			{`Decode, 7'b10101_xx}: next = {`AluCmp0, 23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform CMP Rn,Rm{,<sh_op>}
			{`Decode, 7'b10110_xx}: next = {`AluAnd0, 23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform AND Rd,Rn,Rm{,<sh_op>}
			{`Decode, 7'b10111_xx}: next = {`AluMvn0, 23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform MVN Rd,Rm{,<sh_op>}

			{`Decode, 7'b01100_xx}: next = {`LDR0,    23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform LDR Rd, [Rn{,#<im5>}]
			{`Decode, 7'b10000_xx}: next = {`STR0,    23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform STR Rd, [Rn{,#<im5>}]

			{`Decode, 7'b00100_xx}: next = {`Branch,  23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform a branch instruction

			{`Decode, 7'b01011_xx}: next = {`BL1,  23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform BL
			{`Decode, 7'b01010_xx}: next = {`BLX1, 23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform BLX
			{`Decode, 7'b01000_xx}: next = {`BX1,  23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Perform BX

			{`Decode, 7'b111xx_xx}: next = {`Halt, 23'b00_00_0_00_00_00__000_0_0_00_0_0_0_00}; //Go into halt state

			//MOV Rn,#<im8> instruction:
			//Writes the im8 immediate value to register labelled Rn
			{`MovRn0, 7'b11010_xx}: next = {`IF1, 23'b00_01_1_00_00_00__000_0_0_00_0_0_0_00}; //Write im8 into Rn

			//MOV Rd,Rm{,<sh_op>} instruction:
			//Take Rm and store into Rd
			{`MovRd0, 7'b11000_xx}: next = {`MovRd1, 23'b10_00_0_01_00_00__000_0_0_00_0_0_0_00}; //Load Rm into B
			{`MovRd1, 7'b11000_xx}: next = {`MovRd2, 23'b00_00_0_00_10_10__000_0_0_00_0_0_0_00}; //Load into C, selA is 1
			{`MovRd2, 7'b11000_xx}: next = {`IF1,    23'b01_11_1_00_00_00__000_0_0_00_0_0_0_00}; //Write into Rd

			//ADD Rd,Rn,Rm{,<sh_op>} instruction:
			//Do Rm (loaderB) plus Rn (loaderA) and puts the sum in Rd
			{`AluAdd0, 7'b10100_xx}: next = {`AluAdd1, 23'b00_00_0_10_00_00__000_0_0_00_0_0_0_00}; //Load Rn into A
			{`AluAdd1, 7'b10100_xx}: next = {`AluAdd2, 23'b10_00_0_01_00_00__000_0_0_00_0_0_0_00}; //Load Rm into B
			{`AluAdd2, 7'b10100_xx}: next = {`AluAdd3, 23'b00_00_0_00_00_10__000_0_0_00_0_0_0_00}; //Load into C
			{`AluAdd3, 7'b10100_xx}: next = {`IF1,     23'b01_11_1_00_00_00__000_0_0_00_0_0_0_00}; //Write into Rd

			//CMP Rn,Rm{,<sh_op>} instruction:
			//Do Rn (loader A) minus Rm (loaderB) and load status
			{`AluCmp0, 7'b10101_xx}: next = {`AluCmp1, 23'b00_00_0_10_00_00__000_0_0_00_0_0_0_00}; //Load Rn into A
			{`AluCmp1, 7'b10101_xx}: next = {`AluCmp2, 23'b10_00_0_01_00_00__000_0_0_00_0_0_0_00}; //Load Rm into B
			{`AluCmp2, 7'b10101_xx}: next = {`IF1,     23'b00_00_0_00_00_01__000_0_0_00_0_0_0_00}; //Load status

			//Perform AND Rd,Rn,Rm{,<sh_op>} instruction:
			//Do Rn (loader A) AND Rm (loaderB) and puts result in Rd
			{`AluAnd0, 7'b10110_xx}: next = {`AluAnd1, 23'b00_00_0_10_00_00__000_0_0_00_0_0_0_00}; //Load Rn into A
			{`AluAnd1, 7'b10110_xx}: next = {`AluAnd2, 23'b10_00_0_01_00_00__000_0_0_00_0_0_0_00}; //Load Rm into B
			{`AluAnd2, 7'b10110_xx}: next = {`AluAnd3, 23'b00_00_0_00_00_10__000_0_0_00_0_0_0_00}; //Load into C
			{`AluAnd3, 7'b10110_xx}: next = {`IF1,     23'b01_11_1_00_00_00__000_0_0_00_0_0_0_00}; //Write into Rd

			//Perform MVN Rd,Rm{,<sh_op>} instruction:
			//Do bitwise NOT on Rm (loader B) and put in Rd
			{`AluMvn0, 7'b10111_xx}: next = {`AluMvn1, 23'b10_00_0_01_00_00__000_0_0_00_0_0_0_00}; //Load Rm into B
			{`AluMvn1, 7'b10111_xx}: next = {`AluMvn2, 23'b00_00_0_00_10_10__000_0_0_00_0_0_0_00}; //Load into C, selA is 1
			{`AluMvn2, 7'b10111_xx}: next = {`IF1,     23'b01_11_1_00_00_00__000_0_0_00_0_0_0_00}; //Write into Rd

			//LDR Rd, [Rn{,#<im5>}] instruction:
			//Read from memory address of Rn (loader A) + sx(im5), put value in data address reg,
			//and store value from memory in Rd
			{`LDR0, 7'b01100_xx}: next = {`LDR1, 23'b00_00_0_10_00_00__000_0_0_00_0_0_0_00}; //Load Rn into A
			{`LDR1, 7'b01100_xx}: next = {`LDR2, 23'b00_00_0_00_01_10__000_0_0_00_0_0_0_00}; //Load sum into C, allowing it through datapath_out
			{`LDR2, 7'b01100_xx}: next = {`LDR3, 23'b00_00_0_00_00_00__000_0_0_00_0_1_0_00}; //Load datapath_out in data address
			{`LDR3, 7'b01100_xx}: next = {`LDR4, 23'b00_00_0_00_00_00__000_0_0_01_0_0_0_00}; //Use read cmd and wait for dout
			{`LDR4, 7'b01100_xx}: next = {`IF1,  23'b01_00_1_00_00_00__000_0_0_01_0_0_0_00}; //Use read cmd and store mdata in Rd)

			//STR Rd, [Rn{,#<im5>}] instruction:
			//Read from memory address of Rn (loader A) + sx(im5), put value in data address reg,
			//and write Rd to that memory address
			{`STR0, 7'b10000_xx}: next = {`STR1, 23'b00_00_0_10_00_00__000_0_0_00_0_0_0_00}; //Load Rn into A
			{`STR1, 7'b10000_xx}: next = {`STR2, 23'b01_00_0_01_01_10__000_0_0_00_0_0_0_00}; //Load sum into C, allowing it through datapath_out,
																				   //while also storing RD into B
			{`STR2, 7'b10000_xx}: next = {`STR3, 23'b00_00_0_00_00_00__000_0_0_00_0_1_0_00}; //Load datapath_out in data address
			{`STR3, 7'b10000_xx}: next = {`STR4, 23'b00_00_0_00_10_10__000_0_0_10_0_0_0_00}; //Use write cmd while also storing B into C
			{`STR4, 7'b10000_xx}: next = {`IF1,  23'b00_00_0_00_00_00__000_0_0_10_0_0_0_00}; //Use write cmd to write datapath_out to memory

			//Branch instruction (lab8):
			{`Branch, 7'b00100_xx}: next = {`IF1, 23'b00_00_0_00_00_00__010_1_0_00_0_0_0_00}; //Update the PC

			//BL instruction (lab8)
			{`BL1, 7'b01011_xx}: next = {`BL2, 23'b00_10_1_00_00_00__000_0_0_00_0_0_0_00}; //R7 (Rn) = PC
			{`BL2, 7'b01011_xx}: next = {`IF1, 23'b00_00_0_00_00_00__010_1_0_00_0_0_0_00}; //Update PC = PC+1+sxim8

			//BLX instruction (lab8 bonus)
			{`BLX1, 7'b01010_xx}: next = {`BLX2, 23'b00_10_1_00_00_00__000_0_0_00_0_0_0_00}; //R7 (Rn) = PC
			{`BLX2, 7'b01010_xx}: next = {`IF1,  23'b01_00_0_00_00_00__011_1_0_00_0_0_0_00}; //Update PC = Rd

			//BX instruction(lab8)
			{`BX1, 7'b01000_x1}: next = {`IF1, 23'b01_00_0_01_00_00__011_1_0_00_0_0_0_01}; //Update PC = Rd, if mask is 1 switch to 0
		    {`BX1, 7'b01000_x0}: next = {`IF1, 23'b01_00_0_01_00_00__011_1_0_00_0_0_0_00}; //Update PC = Rd, (no interrupt here)

			//Halt state prevents further instructions from being performed
			{`Halt, 7'bxxxxx_xx}: next = {`Halt, 23'b00_00_0_00_00_00__000_0_0_00_0_0_1_00};

			default: next = {29'bx};

		endcase
	end
endmodule
