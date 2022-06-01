`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:JOYAL 
// 
// Create Date: 30.05.2022 16:30:55
// Design Name: 
// Module Name: zed_oled_control_tb
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


module zed_oled_control_tb;
    
    reg  clock;         
    reg  reset;          
    wire oled_vdd;      
    wire oled_vbat;     
    wire oled_resetn;   
    wire oled_data_comm;
    wire oled_sclock;   
    wire oled_sdata;     
    
    
    zed_oled_control tb1 ( 
        .clock(clock), 
        .reset(reset), 
        .oled_vdd(oled_vdd), 
        .oled_vbat(oled_vbat), 
        .oled_resetn(oled_resetn), 
        .oled_data_comm(oled_data_comm),
        .oled_sclock(oled_sclock),
        .oled_sdata(oled_sdata)
        );
    
    always #5 clock <= ~clock;
    
    initial
    begin
             clock <= 1'b0;
             reset <= 1'b1;
        #500 reset <= 1'b0;
    end

endmodule
