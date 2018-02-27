//Memory command encodings
`define MREAD  2'b01
`define MWRITE 2'b10

module risc_top (KEY, SW, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, CLOCK_50);
	input  [3:0] KEY;
	input  [9:0] SW;
	input CLOCK_50;
	output [9:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

	//Physical interface stuff
	wire Z, N, V;
	wire [15:0] out;
	wire [15:0] ir;

	//Wires for memory interface
	wire msel, mselread, mselwrite;
	wire [15:0] dout;
	wire write;

	//Wires into CPU
	wire [15:0] read_data;

	//Wires out of CPU
	wire [8:0] mem_addr;
	wire [1:0] mem_cmd;
	wire [15:0] write_data;

	//Wires for stage 3
	wire switch_en;
	wire led_en;


	cpu CPU(.clk(CLOCK_50), .reset(~KEY[1]), .interrupt(~KEY[3]), .read_data(read_data), .datapath_out(write_data),
			.mem_cmd(mem_cmd), .mem_addr(mem_addr), .N(N), .V(V), .Z(Z), .is_halt(LEDR[8]));

	//Instantiate Read-Write Memory
	RAM #(16,8,"demo.txt",100) MEM (.clk(CLOCK_50), .read_address(mem_addr[7:0]), .write_address(mem_addr[7:0]),
							    .write(write), .din(write_data), .dout(dout), .counterout()); //PUT IN LEDR[7:4] FOR BONUS

	//Instantiate modules for memory interface
	EqComp #(2) EQ_MREAD  (.a(`MREAD),  .b(mem_cmd), .eq(mselread));
	EqComp #(2) EQ_MWRITE (.a(`MWRITE), .b(mem_cmd), .eq(mselwrite));
	EqComp #(1) EQ_MSEL   (.a(mem_addr[8]), .b(1'b0), .eq(msel));

	//write if memory command is write and is at valid address
	assign write = (mselwrite & msel);

	//dout outputs read_data if memory command is read and is at valid address
	//else output is high impedence
	TriState #(16) MEM_DATA_OUT (.in(dout), .enable(mselread&msel), .out(read_data));


	//MEMORY MAPPED I/O//

	//Instantiate switch interface blocks
	SwitchBlock SWITCH_BLOCK (.mem_cmd(mem_cmd), .mem_addr(mem_addr), .out(switch_en));
	TriState #(16) SWITCH_TRI (.in({8'b0,SW[7:0]}), .enable(switch_en), .out(read_data[15:0]));

	//Instantiate LED interface blocks (ENABLE FOR DEMO, DISABLE FOR INTERRUPTS)
	LedBlock LED_BLOCK (.mem_cmd(mem_cmd), .mem_addr(mem_addr), .out(led_en));
	load_enable #(8) LED_LOAD (.clk(CLOCK_50), .en(led_en), .in(write_data[7:0]), .out(LEDR[7:0]));


	//INTERRUPT BONUS (ENABLE FOR INTERRUPTS, DISABLE FOR DEMO)
	//assign LEDR[3:0] = SW[3:0]; //Lower LEDR should always match SW[3:0]

	//Status bits on HEX5
	assign HEX5[0] = ~Z;
	assign HEX5[6] = ~N;
	assign HEX5[3] = ~V;

	// HEX for current interrupt counter (bonus)
	sseg H0(write_data[3:0],   HEX0);
	sseg H1(write_data[7:4],   HEX1);
	sseg H2(write_data[11:8],  HEX2);
	sseg H3(write_data[15:12], HEX3);

	//Unused HEX displays
	assign HEX4 = 7'b1111111;
	assign {HEX5[2:1],HEX5[5:4]} = 4'b1111;
endmodule


// The sseg module below can be used to display the value of datpath_out on
// the hex LEDS the input is a 4-bit value representing numbers between 0 and
// 15 the output is a 7-bit value that will print a hexadecimal digit.

module sseg(in,segs);
  input [3:0] in;
  output reg [6:0] segs;

	always @* begin
  		case (in)
			0: segs = 7'b1000000;
			1: segs = 7'b1111001;
			2: segs = 7'b0100100;
			3: segs = 7'b0110000;
			4: segs = 7'b0011001;
			5: segs = 7'b0010010;
			6: segs = 7'b0000010;
			7: segs = 7'b1111000;
			8: segs = 7'b0000000;
			9: segs = 7'b0010000;
			10: segs = 7'b0001000; //A
			11: segs = 7'b0000011; //b
			12: segs = 7'b1000110; //C
			13: segs = 7'b0100001; //d
			14: segs = 7'b0000110; //E
			15: segs = 7'b0001110; //F
			default: segs = 7'b1111111;
		endcase
	end
endmodule

//INSTANTIATE ALL MODULES FOR SUBTASKS HERE

//Register with Load Enable
module load_enable (clk, en, in, out);
	parameter n=1;
	input clk, en;
	input  [n-1:0] in;
	output [n-1:0] out;
	reg    [n-1:0] out;
	wire   [n-1:0] next_out;

	assign next_out = en ? in : out;

	always @(posedge clk)
		out = next_out;
endmodule

//Flip-flop module
module vDFF (clk, in, out);
	parameter n=1;
	input clk;
	input [n-1:0] in;
	output [n-1:0] out;
	reg [n-1:0] out;

	always @(posedge clk)
		out = in;
endmodule

//n:m decoder
module Dec (a,b);
	parameter n = 2;
	parameter m = 4;

	input[n-1:0] a;
	output[m-1:0] b;

	wire[m-1:0] b = 1 << a;
endmodule

//16 bit one hot select, 8 input multiplexer
module multiplexer_eight_in (select, inA, inB, inC, inD, inE, inF, inG, inH, out);
	input [7:0] select;
	input [15:0] inA, inB, inC, inD, inE, inF, inG, inH;
	output reg [15:0] out;

	always @*
		case (select)
			8'b00000001: out = inA;
			8'b00000010: out = inB;
			8'b00000100: out = inC;
			8'b00001000: out = inD;
			8'b00010000: out = inE;
			8'b00100000: out = inF;
			8'b01000000: out = inG;
			8'b10000000: out = inH;
			default: out = 16'bx;
		endcase
endmodule

//Variable bit binary select, 2 input multiplexer
//If select is 1, choose A. If select is 0, choose B.
module multiplexer_two_in (select, inA, inB, outC);
	parameter k = 1;
	input         select;
	input  [k-1:0] inA;
	input  [k-1:0] inB;
	output [k-1:0] outC;

	assign outC = select ? inA : inB;
endmodule

//Variable bit binary select, 4 input multiplexer
module multiplexer_four_in (select, inA, inB, inC, inD, out);
	parameter k = 8;
	input [1:0] select;
	input [k-1:0] inA, inB, inC, inD;
	output reg [k-1:0] out;

	always @*
		case (select)
			2'b00: out = inA;
			2'b01: out = inB;
			2'b10: out = inC;
			2'b11: out = inD;
			default: out = {k{1'bx}};
		endcase
endmodule

//Variable bit binary select, 5 input multiplexer
module multiplexer_five_in (select, inA, inB, inC, inD, inE, out);
	parameter k = 8;
	input [2:0] select;
	input [k-1:0] inA, inB, inC, inD, inE;
	output reg [k-1:0] out;

	always @*
		case (select)
			3'b000: out = inA;
			3'b001: out = inB;
			3'b010: out = inC;
			3'b011: out = inD;
			3'b100: out = inE;
			default: out = {k{1'bx}};
		endcase
endmodule

//equality comparator copied from ss6 page 56
module EqComp(a, b, eq);
	parameter k=8;
	input [k-1:0] a, b;
	output eq;

	assign eq = (a==b);
endmodule

//RAM module from ss7 page 17
module RAM (clk, read_address, write_address, write, din, dout, counterout);
	parameter data_width = 32;
	parameter addr_width = 4;
	parameter filename = "test.txt";
	parameter counteraddr = 0;

	input clk;
	input [addr_width-1:0] read_address, write_address;
	input write;
	input [data_width-1:0] din;
	output [data_width-1:0] dout;
	output [3:0] counterout;

	reg [data_width-1:0] dout;

	reg [data_width-1:0] mem [2**addr_width-1:0];

	initial $readmemb (filename, mem);

	always @(posedge clk) begin
		if (write)
			mem[write_address] <= din;
		dout <= mem[read_address];
	end

	assign counterout = mem[counteraddr][3:0];

endmodule

//Tri State Buffer
module TriState (in, enable, out);
	parameter k=8;
	input [k-1:0] in;
	input enable;
	output [k-1:0] out;

	assign out = enable ? in : {k{1'bz}};
endmodule

//Switch Block Module to allow physical STR (Left on diagram)
module SwitchBlock (mem_cmd, mem_addr, out);
	input [1:0] mem_cmd;
	input [8:0] mem_addr;
	output reg out;
	always @* begin
		if ((mem_cmd == `MREAD) && (mem_addr == 9'h140))
			out = 1'b1;
		else
			out = 1'b0;
	end
endmodule

//LED Block Module to allow physical LDR (Right on diagram)
module LedBlock (mem_cmd, mem_addr, out);
	input [1:0] mem_cmd;
	input [8:0] mem_addr;
	output reg out;
	always @* begin
		if ((mem_cmd == `MWRITE) && (mem_addr == 9'h100))
			out = 1'b1;
		else
			out = 1'b0;
	end
endmodule
