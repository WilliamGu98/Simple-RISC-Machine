module datapath (clk, mdata, sximm8, PC, vsel, writenum, write, readnum, loada, loadb,
				 shift, asel, bsel, ALUop, loadc, loads, sximm5, datapath_out, status, data_out);
	//Inputs and outputs:
	//Universal clk
	input        clk;

	//for dataIn multiplexer
	input [15:0] mdata;
	input [15:0] sximm8;
	input [8:0]  PC;
	input [1:0]  vsel;

	//for RegisterFile
	input [2:0]  writenum;
	input        write;
	input [2:0]  readnum;

	//for loaderA and loaderB
	input        loada;
	input        loadb;
	
	//for shift
	input [1:0]  shift;

	//for selecterA and selecterB
	input        asel;
	input        bsel;
	input [15:0] sximm5;

	//for ALU
	input [1:0]  ALUop;

	//for loaderC
	input        loadc;

	//for status (loader)
	input        loads;

	//for data out of loaderC
	output[15:0] datapath_out;

	//for data out of status
	output[2:0]  status;

	//Wire out of registerFile and into loaderA and loaderB, and directly out
	output wire [15:0] data_out;

	//Wire out of dataIn and into registerFile
	wire  [15:0] data_in;

	//Wire out of loaderA and into selecterA
	wire  [15:0] selecter_A_in;
	//Wire out of loaderB and into shifter
	wire  [15:0] shift_in;
	//Wire out of shifter and into selecterB
	wire  [15:0] selecter_B_in;

	//Wires out of selecterA and selecterB and into ALU
	wire  [15:0] ALU_A_in;
	wire  [15:0] ALU_B_in;

	//Wire out of ALU into loaderC(answer)
	wire  [15:0] ALU_C_out;

	//Wire out of ALU into status
	wire  [2:0] ALU_status;


	//Instantiate building block modules

	//MUX for choosing data into datapath
	multiplexer_four_in #(16) dataIn (.select(vsel), .inA(mdata), .inB(sximm8),
					 .inC({7'b0,PC}), .inD(datapath_out), .out(data_in));

	//Registers for storing data
	regfile REGFILE (.clk(clk), .write(write), .writenum(writenum), .readnum(readnum),
						  .data_in(data_in), .data_out(data_out));

	//Loads for A and B
	load_enable #(16) loaderA (.clk(clk), .en(loada), .in(data_out), .out(selecter_A_in));
	load_enable #(16) loaderB (.clk(clk), .en(loadb), .in(data_out), .out(shift_in));

	//Shifter
	shifter shifter (.ain(shift_in), .select(shift), .out(selecter_B_in));

	//MUX for choosing A/16'b0 and B/sximm5
	multiplexer_two_in #(16) selecterA (.select(asel), .inA(16'b0), .inB(selecter_A_in), .outC(ALU_A_in));
	multiplexer_two_in #(16) selecterB (.select(bsel), .inA(sximm5), .inB(selecter_B_in), .outC(ALU_B_in));

	//ALU
	ALU alu (.ain(ALU_A_in), .bin(ALU_B_in), .select(ALUop), .out(ALU_C_out), .status(ALU_status));
	
	//Loads C
	load_enable #(16) loaderC (.clk(clk), .en(loadc), .in(ALU_C_out), .out(datapath_out));

	//Loads status
	load_enable #(3)  statusBlock (.clk(clk), .en(loads), .in(ALU_status), .out(status));

endmodule