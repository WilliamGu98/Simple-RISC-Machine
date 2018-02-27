module interrupt_tb();
	reg [3:0] KEY;
	reg [9:0] SW;
	wire [9:0] LEDR;
	wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	reg err;
	reg CLOCK_50;

	lab8_top DUT(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50);

	initial forever begin
		CLOCK_50 = 0; #5;
		CLOCK_50 = 1; #5;
	end

	wire done = (DUT.MEM.mem[100] == 16'd5); //Done when counter in memory hits 5

	initial begin
		err = 0;
		KEY[1] = 1'b0; // reset asserted
		#10; // wait until next falling edge of clock
		KEY[1] = 1'b1; // reset de-asserted, PC still undefined if as in Figure 4
		while (~done) begin
			@(posedge (DUT.CPU.FSM.p == 6'd1) or posedge done);
			@(negedge CLOCK_50); // show advance to negative edge of clock
			$display("PC = %h", DUT.CPU.PC);
			#30;
			KEY[3] = 1'b0; SW[7:0] = 8'b00000001; #30; //Initiate interrupt
			KEY[3] = 1'b1; #100; //Deassert Interrupt
		end
		if (LEDR[7:4] !== 4'b0101) begin err = 1; $display("FAILED: LEDR is wrong"); $stop; end
		if (~err) $display("PASSED, LEDS display correct counter value");
		$stop;
	end
endmodule
