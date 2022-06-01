`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:JOYAL 
// 
// Create Date: 29.05.2022 16:32:47
// Design Name: 
// Module Name: zed_oled_control
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


module zed_oled_control(
    input clock,                              // global clock - board clock 100MHz
    input reset,                              // global reset - push button BUTNC
    //OLED I/F signals
    output oled_vdd,                          // Power Supply for Logic
    output oled_vbat,                         // Power Supply for DC/DC Converter Circuit
    output oled_resetn,                       // Power Reset for Controller and Driver
    output oled_data_comm,                    // Data/Command Control
    output oled_sclock,                       // spi clock
    output oled_sdata                         // spi data
    );
    
    reg oled_vdd_i           = 1;             // active low signal 
    reg oled_vbat_i          = 1;             // active low signal
    reg oled_rstn_i          = 1;             // active low signal
    reg oled_dc_i            = 0;             // 1- data and 0 - command
    reg [7:0]sdata           = 0;
    reg svalid               = 0;
    reg dly_enable           = 0;
    reg [4:0]vld_cnt         = 0;
    reg sdone_d              = 0;
    reg sdone_d1             = 0;
    reg [5:0]state           = 0;
    reg [5:0]comeback_state  = 0; 
    
    wire delay_done;
    wire sdone;
    wire sdone_fe;     
    
    localparam idle              = 6'd0,
               vddon             = 6'd1,
               wait1             = 6'd2,
               dispoff           = 6'd3,
               resetON           = 6'd4,
               wait2             = 6'd5,
               resetOFF          = 6'd6,
               chargepump1       = 6'd7,
               chargepump2       = 6'd8,
               precharge1        = 6'd9,
               precharge2        = 6'd10,
               vbatON            = 6'd11,
               wait3             = 6'd12,
               set_DispContrast1 = 6'd13,
               set_DispContrast2 = 6'd14,
               segment_remap     = 6'd15,
               COM_scan_dir      = 6'd16,
               COM_pinconfig1    = 6'd17,
               COM_pinconfig2    = 6'd18,
               display_ON        = 6'd19,
               full_display      = 6'd20,
               init_done         = 6'd21,
               delay_en          = 6'd30,
               delay_chk         = 6'd31,
               clear_dly_en      = 6'd32,
               sdata_vld         = 6'd40,
               sdone_chk         = 6'd41;

    spi_control spi_control_inst1 (       
        .clock(clock),    
        .reset(reset),    
        .data_in(sdata),  
        .data_vld(svalid), 
        .o_sclock(oled_sclock), 
        .o_sdata(oled_sdata),  
        .o_sdone(sdone)   
        ); 
        
    delay_2ms delay_2ms_inst1 (
        .clock(clock),
        .reset(reset),
        .enable(dly_enable),
        .done(delay_done)
        );  
        
    assign oled_vdd        = oled_vdd_i;
    assign oled_vbat       = oled_vbat_i;
    assign oled_resetn     = oled_rstn_i; 
    assign oled_data_comm  = oled_dc_i;

    always @(posedge clock)
    begin
        if(reset)
        begin
            sdone_d  <= 0;
            sdone_d1 <= 0;
        end
        else
        begin
            sdone_d  <= sdone;
            sdone_d1 <= sdone_d;
        end
    end 
    
    assign sdone_fe = (sdone_d1 & ~sdone_d);                
    
    always @(posedge clock)
    begin
        if(reset)
        begin
            oled_vdd_i     <= 1;
            oled_vbat_i    <= 1;
            oled_rstn_i    <= 1;
            oled_dc_i      <= 0;
            dly_enable     <= 0;
            sdata          <= 0;
            svalid         <= 0;
            vld_cnt        <= 0;
            state          <= idle;
            comeback_state <= idle;
        end
        else
        begin
            case(state)
                idle: begin
                    oled_vdd_i     <= 1;   
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0; 
                    dly_enable     <= 0;
                    sdata          <= 0;
                    svalid         <= 0;
                    vld_cnt        <= 0;  
                    state          <= vddon;
                end
                
                vddon: begin
                    oled_vdd_i     <= 0;                       // turned ON VDD and wait for 2ms
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    dly_enable     <= 0; 
                    sdata          <= 0;
                    svalid         <= 0;  
                    state          <= wait1;
                end
                
                wait1: begin
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    dly_enable     <= 0;
                    sdata          <= 0; 
                    svalid         <= 0;  
                    state          <= delay_en;
                    comeback_state <= dispoff;
                end
                
                dispoff: begin                                // sending display off command to oled 
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    sdata          <= 8'hAE;
                    svalid         <= 0;    
                    state          <= sdata_vld;
                    comeback_state <= resetON;
                end
                
                resetON: begin                                // apply reset and wait for 2ms - active low
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 0;   
                    oled_dc_i      <= 0;    
                    state          <= wait2;
                end
                
                wait2: begin                   
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 0;   
                    oled_dc_i      <= 0;    
                    state          <= delay_en;
                    comeback_state <= resetOFF;
                end
                
                resetOFF: begin                               // remove reset after 2ms
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;    
                    state          <= delay_en;
                    comeback_state <= chargepump1;
                end
                
                chargepump1: begin                            // sending charge pump configuration to oled 
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    sdata          <= 8'h8D;
                    svalid         <= 0;    
                    state          <= sdata_vld;
                    comeback_state <= chargepump2;
                end
                
                chargepump2: begin                            // sending charge pump configuration to oled 
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    sdata          <= 8'h14;
                    svalid         <= 0;    
                    state          <= sdata_vld;
                    comeback_state <= precharge1;
                end
                
                precharge1: begin                             // sending pre-charge configuration to oled 
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    sdata          <= 8'hD9;
                    svalid         <= 0;    
                    state          <= sdata_vld;
                    comeback_state <= precharge2;
                end
                
                precharge2: begin                            // sending pre-charge configuration to oled 
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 1;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    sdata          <= 8'hF1;
                    svalid         <= 0;    
                    state          <= sdata_vld;
                    comeback_state <= vbatON;
                end
                
                vbatON: begin                                // apply vbat and wait for 2ms - active low
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 0;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;    
                    state          <= wait3;
                end
                
                wait3: begin                   
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 0;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;    
                    state          <= delay_en;
                    comeback_state <= set_DispContrast1;
                end
                
                set_DispContrast1: begin                     // Set Contrast Control Followed by one byte: contrast level
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 0;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    sdata          <= 8'h81;
                    svalid         <= 0;    
                    state          <= sdata_vld;
                    comeback_state <= set_DispContrast2;
                end
                
                set_DispContrast2: begin                     // setting contrast level x00-MIN xFF-MAX
                    oled_vdd_i     <= 0;                 
                    oled_vbat_i    <= 0;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    sdata          <= 8'hFF;
                    svalid         <= 0;    
                    state          <= sdata_vld;
                    comeback_state <= segment_remap;
                end
                
                segment_remap: begin                        // flips left-right orientation of the display  - 0xA0 -> Normal segment mapping (column 0 ? SEG0)
                    oled_vdd_i     <= 0;                    //                                              0xA1 -> Column address remapped (column 0 ? SEG127)
                    oled_vbat_i    <= 0;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    sdata          <= 8'hA0;
                    svalid         <= 0;    
                    state          <= sdata_vld;
                    comeback_state <= COM_scan_dir;
                end
                
                COM_scan_dir: begin                         // flips top-bottom orientation of the display  - 0xC0 -> Normal scan  ? default top-to-bottom
                    oled_vdd_i     <= 0;                    //                                                0xC8 -> Reverse scan ? flips vertical direction
                    oled_vbat_i    <= 0;   
                    oled_rstn_i    <= 1;   
                    oled_dc_i      <= 0;
                    sdata          <= 8'hC0;
                    svalid         <= 0;    
                    state          <= sdata_vld;
                    comeback_state <= COM_pinconfig1;
                end
                
                COM_pinconfig1: begin                       // sets COM pin hardware configurations       
                    oled_vdd_i     <= 0;              
                    oled_vbat_i    <= 0;              
                    oled_rstn_i    <= 1;              
                    oled_dc_i      <= 0;              
                    sdata          <= 8'hDA;          
                    svalid         <= 0;              
                    state          <= sdata_vld;      
                    comeback_state <= COM_pinconfig2; 
                end                                   
                
                COM_pinconfig2: begin                       // sets COM pin hardware configurations       
                    oled_vdd_i     <= 0;              
                    oled_vbat_i    <= 0;              
                    oled_rstn_i    <= 1;              
                    oled_dc_i      <= 0;              
                    sdata          <= 8'h00;          
                    svalid         <= 0;              
                    state          <= sdata_vld;      
                    comeback_state <= display_ON; 
                end
                
                
               display_ON: begin                              // Turn the OLED display ON      
                    oled_vdd_i     <= 0;              
                    oled_vbat_i    <= 0;              
                    oled_rstn_i    <= 1;              
                    oled_dc_i      <= 0;              
                    sdata          <= 8'hAF;          
                    svalid         <= 0;              
                    state          <= sdata_vld;      
                    comeback_state <= full_display; 
                end 
                
                full_display: begin                            // Turn all pixels of OLED      
                    oled_vdd_i     <= 0;              
                    oled_vbat_i    <= 0;              
                    oled_rstn_i    <= 1;              
                    oled_dc_i      <= 0;              
                    sdata          <= 8'hA5;          
                    svalid         <= 0;              
                    state          <= sdata_vld;      
                    comeback_state <= init_done; 
                end
                
                init_done: begin                               // initialization finished and stays in the same state
                    state          <= init_done;
                end 

                // SPI transitions
                // 1. Set valid to 1 for 300ns
                // 2. Waits for spi_control to finish

                sdata_vld: begin                               
                    sdata          <= sdata;
                    svalid         <= 1;
                    if(vld_cnt != 'd29)
                    begin
                        vld_cnt    <= vld_cnt + 1; 
                        state      <= sdata_vld;
                    end
                    else
                    begin
                        vld_cnt    <= 0; 
                        state      <= sdone_chk;
                    end
                end
                
                sdone_chk: begin
                    sdata          <= sdata;
                    svalid         <= 0;
                    vld_cnt        <= 0; 
                    if(sdone_fe)
                        state      <= comeback_state;
                    else
                        state      <= sdone_chk;
                end
                
                // Delay transitions
                // 1. Set dly_enable to 1
                // 2. Waits for delay to finish
                // 3. Goes to Clear state 

                delay_en: begin                              
                    oled_vdd_i     <= oled_vdd_i;                 
                    oled_vbat_i    <= oled_vbat_i;   
                    oled_rstn_i    <= oled_rstn_i;   
                    oled_dc_i      <= oled_dc_i;
                    dly_enable     <= 1;   
                    state          <= delay_chk;
                end
                
                delay_chk: begin
                    oled_vdd_i     <= oled_vdd_i;                 
                    oled_vbat_i    <= oled_vbat_i;   
                    oled_rstn_i    <= oled_rstn_i;   
                    oled_dc_i      <= oled_dc_i;
                    dly_enable     <= 1; 
                    if(delay_done)   
                        state <= clear_dly_en;
                    else
                        state <= delay_chk;
                end
                
                // Clear transitions
                // 1. Sets dly_enable to 0
                // 2. Go to comeback state

                clear_dly_en: begin
                    oled_vdd_i     <= oled_vdd_i;                 
                    oled_vbat_i    <= oled_vbat_i;   
                    oled_rstn_i    <= oled_rstn_i;   
                    oled_dc_i      <= oled_dc_i;
                    dly_enable     <= 0;    
                    state          <= comeback_state;
                end
            endcase
        end
    end
    
    ila_1 ila_inst2 (
    	.clk(clock),                          // input wire clk
       
    	.probe0(oled_vdd_i),                  // input wire [0:0]  probe0  
    	.probe1(oled_vbat_i),                 // input wire [0:0]  probe1 
    	.probe2(oled_rstn_i),                 // input wire [0:0]  probe2 
    	.probe3(oled_dc_i),                   // input wire [0:0]  probe3 
    	.probe4(sdata),                       // input wire [7:0]  probe4 
    	.probe5(svalid),                      // input wire [0:0]  probe5 
    	.probe6(dly_enable),                  // input wire [0:0]  probe6 
    	.probe7(vld_cnt),                     // input wire [4:0]  probe7 
    	.probe8(state),                       // input wire [5:0]  probe8 
    	.probe9(comeback_state),              // input wire [5:0]  probe9 
    	.probe10(delay_done),                 // input wire [0:0]  probe10 
    	.probe11(sdone_fe)                    // input wire [0:0]  probe11
    );


endmodule
