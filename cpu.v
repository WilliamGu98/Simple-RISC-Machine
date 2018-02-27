`define ISR_START 9'b1010 //Memory location of interrupt instruction

module cpu(clk, reset, interrupt, read_data, datapath_out, mem_cmd, mem_addr, N, V, Z, is_halt);
	input clk, reset, interrupt;
	input [15:0] read_data;
	output [15:0] datapath_out;
	output N, V, Z, is_halt;

	output [1:0] mem_cmd;
	output [8:0] mem_addr;

	wire [15:0] into_instr_decoder;

	//Wires out of INSTR_DEC//
	//Into STATE_MACHINE
	wire [2:0] opcode;
	wire [1:0] op;

	//Into DP
	wire [1:0] ALUop, shift;
	wire [15:0] sximm5, sximm8;
	wire [2:0] readnum, writenum;

	wire [15:0] reg_out; //directly read from regfile

	//Wires out of STATE_MACHINE//
	wire [1:0] nsel; //Into INSTR_DEC

	wire [1:0] vsel; //Into DP
	wire write, loada, loadb, asel, bsel, loadc, loads; 
	
	wire load_ir, load_pc, addr_sel, load_addr; //For lab 7
	wire [1:0] mem_cmd;
	wire [2:0] select_pc;

	//Wires in and out of PROGRAM_COUNTER//
	wire [8:0] next_pc;
	wire [8:0] PC;
	wire [8:0] branch_pc;

	//Wire out of data address
	wire [8:0] data_addr;

	//Instantiate instruciton register
	load_enable #(16) INSTRUCTION_REGISTER(.clk(clk), .en(load_ir), .in(read_data), .out(into_instr_decoder));

	//Instantiate instruction decoder
	instruction_decoder INSTR_DEC(.in(into_instr_decoder), .nsel(nsel), .opcode(opcode), .op(op),
								  .ALUop(ALUop), .sximm5(sximm5), .sximm8(sximm8), 
								  .shift(shift), .readnum(readnum), .writenum(writenum));

	//Instantiate state machine
	state_machine FSM(.clk(clk), .reset(reset), .opcode(opcode), .interrupt(interrupt),
						.op(op), .nsel(nsel), .vsel(vsel), 
						.write(write), .loada(loada), .loadb(loadb),
					 	.asel(asel), .bsel(bsel), .loadc(loadc), .loads(loads),
						.load_ir(load_ir), .load_pc(load_pc), .select_pc(select_pc), 
						.addr_sel(addr_sel), .mem_cmd(mem_cmd), .load_addr(load_addr), .is_halt(is_halt));

	//Instantiate datapath
	datapath DP(.clk(clk), .mdata(read_data), .sximm8(sximm8), .PC(PC), .vsel(vsel),
				.writenum(writenum), .write(write), .readnum(readnum), .loada(loada),
				.loadb(loadb), .shift(shift), .asel(asel), .bsel(bsel), .ALUop(ALUop),
				.loadc(loadc), .loads(loads), .sximm5(sximm5), .datapath_out(datapath_out), 
				.status({V,N,Z}), .data_out(reg_out));

	//Instantiate comb. logic block for next pc if branch instruction is used
	branchlogic BRANCH_PC (.PC(PC), .cond(into_instr_decoder[10:8]), .sximm8(sximm8[8:0]), .V(V), .N(N), .Z(Z), .PCout(branch_pc));

	//Instantiate next program counter MUX
    multiplexer_five_in #(9) NEXT_COUNT (.select(select_pc), .inA(PC+1'b1), .inB(9'b0), .inC(branch_pc), .inD(reg_out[8:0]), .inE(`ISR_START), .out(next_pc));

	//Instantiate program counter loader
	load_enable #(9) PROGRAM_COUNTER (.clk(clk), .en(load_pc), .in(next_pc), .out(PC));

	//Instantiate address select MUX
	multiplexer_two_in #(9) ADDR_SELECT (.select(addr_sel), .inA(PC), .inB(data_addr), .outC(mem_addr));

	//Instantiate Data Address Load Enable
	load_enable #(9) DATA_ADDRESS (.clk(clk), .en(load_addr), .in(datapath_out[8:0]), .out(data_addr));
endmodule