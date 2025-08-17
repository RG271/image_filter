`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:        Richard D. Kaminsky, Ph.D.
// 
// Create Date:     7/30/2025
// Design Name:     image_filter
// Module Name:     spotter.v
// Project Name:
// Target Devices:  PYNQ-Z2
// Tool Versions:   Xilinx Vivado 2022.2
// Description:
//
//   !!!UNFINISHED
//
//      This module identifies spots of light in a 128x128 16b video frame.
//
//      Address:
//        0 .. 24'h003FFF    frame      rw     Frame buffer, which is 128x128 uint16_t pixels
//
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spotter(
    input               clk,

    // DAP interface
    input      [23:0]   addr,
    input      [31:0]   wdata,
    output reg [31:0]   rdata = 0,
    input               we,
    input               re
);


    // 128x128 16b Frame Buffer
    
    reg          wea    =  0;
    reg  [13:0]  addra  =  0;
    reg  [15:0]  dina   =  0;
    wire [15:0]  douta;

    wire [13:0]  addrb;
    wire [15:0]  doutb;
    assign addrb = 14'b0;   // !!!STUB

    blk_mem_128x128_16b blk_mem_128x128_16b_i (
    
      .clka(  clk   ),   // input wire clka
      .wea(   wea   ),   // input wire [0 : 0] wea
      .addra( addra ),   // input wire [13 : 0] addra
      .dina(  dina  ),   // input wire [15 : 0] dina
      .douta( douta ),   // output wire [15 : 0] douta
      
      .clkb(  clk   ),   // input wire clkb
      .web(   1'b0  ),   // input wire [0 : 0] web
      .addrb( addrb ),   // input wire [13 : 0] addrb
      .dinb(  16'd0 ),   // input wire [15 : 0] dinb
      .doutb( doutb )    // output wire [15 : 0] doutb
    );


    // DAP Interface

    reg rva     =  0;     // read-from-block-mem-port-a-is-valid
    reg rva_z   =  0;     // future read-from-block-mem-port-a-is-valid 
    reg rva_zz  =  0;     // future future read-from-block-mem-port-a-is-valid 

    always @(posedge clk) begin
    
        wea     <=  0;
        rva     <=  rva_z;
        rva_z   <=  rva_zz;
        rva_zz  <=  0;
        
        if (rva)  rdata <= {16'b0, douta};
        
        if (addr[15:14] == 0) begin
            if (we) begin
                addra   <=  addr[13:0];
                dina    <=  wdata[15:0];
                wea     <=  1;
            end
            if (re) begin
                addra   <=  addr[13:0];
                rva_zz  <=  1;
            end
        end             

/*    
        if (we)
            case (addr[1:0])
                0:  leds <= wdata[3:0];
                1:  LD4  <= wdata[2:0];
                2:  LD5  <= wdata[2:0];
            endcase
        if (re)
            case (addr[1:0])
                0:  rdata <= leds;
                1:  rdata <= LD4;
                2:  rdata <= LD5;
                3:  rdata <= _sw;
                default:  rdata <= 32'hDEADBEEF;
            endcase
*/

    end


endmodule
