`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:JOYAL 
// 
// Create Date: 24.05.2022 18:05:03
// Design Name: 
// Module Name: spi_cntrol
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


module spi_control(
    input       clock,                         // global clock from zedboard - 100mhz
    input       reset,                         // global reset
    input  [7:0]data_in,                       // 8 bit data to be sent over spi to oled
    input       data_vld,                      // valid input data or a new data, for handshaking, should be high for 300ns after prividing a new data input
    output      o_sclock,                      // spi clock - 10mhz
    output      o_sdata,                       // serial data output
    output      o_sdone                        // indicates a byte transfer or finish, for handshaking, based on sclock
    );
    
    reg [2:0]clk_cntr = 0;
    reg      sclock   = 0;
    reg      sdone    = 0;
    reg      sdata    = 1;
    reg      ce       = 0;
    reg [1:0]state    = 0;
    reg [7:0]shiftReg = 0;
    reg [2:0]datacntr = 0;
    
    wire sclock_i;
    
    localparam st1_idle = 2'd0,
               st2_send = 2'd1,
               st3_done = 2'd2;
    
    assign o_sclock = (ce == 1)? sclock : 1'b1;
    assign sclock_i = (ce == 1)? sclock : 1'b1;           // for monitoring in ila
    assign o_sdata  = sdata;
    assign o_sdone  = sdone;
    
    always @(posedge clock)
    begin
//        if(reset)
//        begin
//            clk_cntr <= 3'b000;
//            sclock   <= 0;
//        end
//        else
//        begin 
            if(clk_cntr != 3'b100)
            begin
                clk_cntr <= clk_cntr + 1;
                sclock   <= sclock;
            end
            else
            begin
                clk_cntr <= 0;
                sclock   <= ~sclock;
            end
        end    
//    end 
    
    always @(negedge sclock)
    begin
        if(reset)
        begin
            state    <= st1_idle;
            sdone    <= 0;
            sdata    <= 1;
            shiftReg <= 0;
            datacntr <= 0;
            ce       <= 0;
        end
        else
        begin
            case(state)
                st1_idle: begin
                    sdone    <= 0;
                    sdata    <= 1;
                    datacntr <= 0;
                    ce       <= 0;
                    if(data_vld)
                    begin
                        state    <= st2_send;
                        shiftReg <= data_in;
                    end
                    else
                    begin
                        state    <= st1_idle;
                        shiftReg <= 0;
                    end
                end
                
                st2_send: begin
                    sdone    <= 0;
                    sdata    <= shiftReg[7];
                    shiftReg <= {shiftReg[6:0], 1'b0};
                    ce       <= 1;
                    if(datacntr != 3'b111)
                    begin
                        datacntr <= datacntr + 1;
                        state    <= st2_send;
                    end
                    else
                    begin
                        datacntr <= datacntr;
                        state    <= st3_done;
                    end
                end
                
                st3_done: begin
                    sdone    <= 1;
                    sdata    <= 1;
                    shiftReg <= 0;
                    datacntr <= 0;
                    ce       <= 0;
                    state    <= st1_idle;
                end
            endcase
        end
    end
    
//    ila_1 ila_inst2 (
//	.clk(clock), // input wire clk


//	.probe0(data_in),      // input wire [7:0]  probe0  
//	.probe1(data_vld),     // input wire [0:0]  probe1 
//	.probe2(clk_cntr),     // input wire [2:0]  probe2 
//	.probe3(sclock),       // input wire [0:0]  probe3 
//	.probe4(sdone),        // input wire [0:0]  probe4 
//	.probe5(sdata),        // input wire [0:0]  probe5 
//	.probe6(ce),           // input wire [0:0]  probe6 
//	.probe7(state),        // input wire [1:0]  probe7 
//	.probe8(shiftReg),     // input wire [7:0]  probe8 
//	.probe9(datacntr),     // input wire [2:0]  probe9
//	.probe10(sclock_i)     // input wire [0:0]  probe10
//    );
 
endmodule
