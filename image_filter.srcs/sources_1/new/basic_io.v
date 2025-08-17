`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:        Richard D. Kaminsky, Ph.D.
// 
// Create Date:     7/26/2025 - 8/2/2025
// Design Name:     image_filter
// Module Name:     basic_io.v
// Project Name:
// Target Devices:  PYNQ-Z2
// Tool Versions:   Xilinx Vivado 2022.2
// Description:
// 
//      This module controls the LEDs and switches on the PYNQ-Z2 board.
//
//      Registers:
//
//        0       creationDate     ro     Firmware's creation date in 0xYYMMDDHH format
//
//        1       buildDate        ro     Firmware's build date in 0xYYMMDDHH format
//
//        2       usTime           ro     Current time in microseconds modulo 2**26
//
//        3       leds             rw     LEDs' enables (4 bits)
//                                          Bits   Name           Description
//                                          -----  -------------  ---------------------------------------------------------------------------
//                                          31:4   --             unimplemented (always 0)
//                                          3      LED3           LED #3 enable (0=off, 1=on)
//                                          2      LED2           LED #2 enable (0=off, 1=on)
//                                          1      LED1           LED #1 enable (0=off, 1=on)
//                                          0      LED0           LED #0 enable (0=off, 1=on)
//
//        4       LD4              rw     RGB LED LD4's enables (6 bits)
//                                          Bits   Name           Description
//                                          -----  -------------  ---------------------------------------------------------------------------
//                                          31:3   --             unimplemented (always 0)
//                                          2      LD4red         RGB LED LD4's red   channel (0=off, 1=on)
//                                          1      LD4green       RGB LED LD4's green channel (0=off, 1=on)
//                                          0      LD4blue        RGB LED LD4's blue  channel (0=off, 1=on)
//
//        5       LD5              rw     RGB LED LD5's enables (6 bits)
//                                          Bits   Name           Description
//                                          -----  -------------  ---------------------------------------------------------------------------
//                                          31:3   --             unimplemented (always 0)
//                                          2      LD5red         RGB LED LD5's red   channel (0=off, 1=on)
//                                          1      LD5green       RGB LED LD5's green channel (0=off, 1=on)
//                                          0      LD5blue        RGB LED LD5's blue  channel (0=off, 1=on)
//   
//        6       sw               ro     Switches and Buttons
//                                          Bits   Name           Description
//                                          -----  -------------  ---------------------------------------------------------------------------
//                                          31:6   --             unimplemented (always 0)
//                                          5      SW1            switch #1 (0=off, 1=on)
//                                          4      SW0            switch #0 (0=off, 1=on)
//                                          3      BTN3           pushbutton #3 (0=up, 1=down)
//                                          2      BTN2           pushbutton #2 (0=up, 1=down)
//                                          1      BTN1           pushbutton #1 (0=up, 1=down)
//                                          0      BTN0           pushbutton #0 (0=up, 1=down)
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module basic_io(
    input               clk,
    input [31:0]        creation_date,      // firmware's creation date in 0xYYMMDDHH format
    input [31:0]        build_date,         // firmware's build date in 0xYYMMDDHH format
    input [25:0]        us_time,            // current time in microseconds modulo 2**26

    // DAP Interface
    input      [23:0]   addr,
    input      [31:0]   wdata,
    output reg [31:0]   rdata = 0,
    input               we,
    input               re,
    
    output reg [3:0]    leds = 4'b0000,
    output reg [2:0]    LD4  = 3'b000,
    output reg [2:0]    LD5  = 3'b000,
    input      [5:0]    sw
);

    (* ASYNC_REG = "TRUE" *)  reg [6:0]  _sw;    // sw synchronized to clk 
    
    always @(posedge clk) begin
        _sw <= sw;
        if (we)
            case (addr[2:0])
                3:  leds <= wdata[3:0];
                4:  LD4  <= wdata[2:0];
                5:  LD5  <= wdata[2:0];
            endcase
        if (re)
            case (addr[2:0])
                0:  rdata <= creation_date;
                1:  rdata <= build_date;
                2:  rdata <= us_time;
                3:  rdata <= leds;
                4:  rdata <= LD4;
                5:  rdata <= LD5;
                6:  rdata <= _sw;
                default:  rdata <= 32'hDEADBEEF;
            endcase
    end

endmodule
