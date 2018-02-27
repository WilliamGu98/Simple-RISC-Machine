module regfile (clk, write, writenum, readnum, data_in, data_out);
	input clk;
	input write;
	input  [2:0] writenum;
	input  [2:0] readnum;
	input  [15:0] data_in;
	output [15:0] data_out;

	wire [7:0] write_select, read_select; //Write num and readnum converted to one hot
	wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7; //Outputs of registers

	Dec #(3,8) write_decode(writenum, write_select);
	Dec #(3,8) read_decode(readnum, read_select);

	//Initialize 8 load enable modules for each register
	load_enable #(16) Reg0(clk, write & write_select[0], data_in, R0);
	load_enable #(16) Reg1(clk, write & write_select[1], data_in, R1);
	load_enable #(16) Reg2(clk, write & write_select[2], data_in, R2);
	load_enable #(16) Reg3(clk, write & write_select[3], data_in, R3);
	load_enable #(16) Reg4(clk, write & write_select[4], data_in, R4);
	load_enable #(16) Reg5(clk, write & write_select[5], data_in, R5);
	load_enable #(16) Reg6(clk, write & write_select[6], data_in, R6);
	load_enable #(16) Reg7(clk, write & write_select[7], data_in, R7);

	//Select which register to read from
	multiplexer_eight_in READ (read_select, R0, R1, R2, R3, R4, R5, R6, R7, data_out);
	
endmodule