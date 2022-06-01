`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:JOYAL 
// 
// Create Date: 30.05.2022 14:26:04
// Design Name: 
// Module Name: delay_2ms
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module delay_2ms(
    input  clock,
    input  reset,
    input  enable,
    (* dont_touch = "true" *)output done
    );
    
    reg [17:0]counter = 0;
    
    wire done_i;
    
    assign done   = (counter == 200000)? 1'b1: 1'b0;
    assign done_i = (counter == 200000)? 1'b1: 1'b0;                  // for monitoring in ila
    
    always @(posedge clock)
    begin
        if(reset)
            counter <= 0;
        else if(enable)
            counter <= counter + 1;
        else
            counter <= 0;
    end
    
    ila_0 ila_inst1 (
	.clk(clock),       // input wire clk

	.probe0(enable),   // input wire [0:0]   probe0  
	.probe1(counter),  // input wire [17:0]  probe1 
	.probe2(done_i)    // input wire [0:0]   probe2
    );
     
endmodule
