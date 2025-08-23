`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:        Richard D. Kaminsky, Ph.D.
// 
// Create Date:     7/22/2025 - 8/23/2025
// Design Name:     image_filter
// Module Name:     top.v
// Project Name:
// Target Devices:  PYNQ-Z2
// Tool Versions:   Xilinx Vivado 2022.2
// Description:
// 
//      Example project for a PYNQ-Z2 board.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top(
    inout [14:0]  DDR_addr,
    inout [2:0]   DDR_ba,
    inout         DDR_cas_n,
    inout         DDR_ck_n,
    inout         DDR_ck_p,
    inout         DDR_cke,
    inout         DDR_cs_n,
    inout [3:0]   DDR_dm,
    inout [31:0]  DDR_dq,
    inout [3:0]   DDR_dqs_n,
    inout [3:0]   DDR_dqs_p,
    inout         DDR_odt,
    inout         DDR_ras_n,
    inout         DDR_reset_n,
    inout         DDR_we_n,

    inout         FIXED_IO_ddr_vrn,
    inout         FIXED_IO_ddr_vrp,
    inout [53:0]  FIXED_IO_mio,
    inout         FIXED_IO_ps_clk,
    inout         FIXED_IO_ps_porb,
    inout         FIXED_IO_ps_srstb,

//  input         Vaux1_v_n,
//  input         Vaux1_v_p,
//  input         Vaux5_v_n,
//  input         Vaux5_v_p,
//  input         Vaux6_v_n,
//  input         Vaux6_v_p,
//  input         Vaux9_v_n,
//  input         Vaux9_v_p,
//  input         Vaux13_v_n,
//  input         Vaux13_v_p,
//  input         Vaux15_v_n,
//  input         Vaux15_v_p,
//  input         Vp_Vn_v_n,
//  input         Vp_Vn_v_p,

//  inout         arduino_direct_iic_scl_io,    // presently not used
//  inout         arduino_direct_iic_sda_io,    // presently not used

//  inout         arduino_direct_spi_io0_io,    // presently not used
//  inout         arduino_direct_spi_io1_io,    // presently not used
//  inout         arduino_direct_spi_sck_io,    // presently not used
//  inout         arduino_direct_spi_ss_io,     // presently not used

// HDMI Sink
//  input         hdmi_in_clk_n,                // presently not used
//  input         hdmi_in_clk_p,                // presently not used
//  input [2:0]   hdmi_in_data_n,               // presently not used
//  input [2:0]   hdmi_in_data_p,               // presently not used
//  inout         hdmi_in_ddc_scl_io,           // presently not used
//  inout         hdmi_in_ddc_sda_io,           // presently not used
//  output        hdmi_in_hpd,                  // presently not used

// HDMI Source
//  output        hdmi_out_clk_n,
//  output        hdmi_out_clk_p,
//  output [2:0]  hdmi_out_data_n,
//  output [2:0]  hdmi_out_data_p,
//  output        hdmi_out_hpd,

// PMODA port having 200 ohm series resistors
//  inout [7:0]   pmoda_rpi_gpio_tri_io,        // presently not used

// PMODB port having 200 ohm series resistors
//  inout [7:0]   pmodb_gpio_tri_io,            // presently not used

// Rapberry Pi port
//  inout [19:0]  rpi_gpio_tri_io,              // presently not used

// Audio CODEC
//  inout         IIC_1_scl_io,
//  inout         IIC_1_sda_io,
//  output        audio_clk_10MHz,              // presently not used
//  output        bclk,                         // presently not used
//  output        lrclk,                        // presently not used
//  input         sdata_i,                      // presently not used
//  output        sdata_o,                      // presently not used
//  output [1:0]  codec_addr,                   // presently not used

    input         debug_rx,
    output        debug_tx,

    output [3:0]  leds_4bits_tri_o,
    output [2:0]  LD4_rgb_o,
    output [2:0]  LD5_rgb_o,
    input [1:0]   sws_2bits_tri_i,
    input [3:0]   btns_4bits_tri_i
);


localparam [31:0]  CREATION_DATE  =  32'h25072212,   // PL firmware's creation date in 0xYYMMDDHH format
                   BUILD_DATE     =  32'h25082316;   // PL firmware's build date in 0xYYMMDDHH format

localparam real    CLK_FREQ       =  100e6,          // clk's frequency (Hz)
                   BAUD_RATE      =  921600;         // Debug Serial Port's baud rate in bits/s (115200 .. 921600)
// NOTE:  CLK_FREQ and BAUD_RATE must also be manually set on the "dap" block in the "system" block design
// (double-click the "dap" block in IP Integrator and enter the values above).

wire         clk;           // clock used by AXI4 peripherals; CLK_FREQ Hz
wire [25:0]  us_time;       // 26-bit free-running timer at 1 MHz

wire         dap_tx;        // serial output from the Debug Access Port
wire         dcm_tx;        // serial output from the Debug Capture Module, used to dump the buffer 
assign debug_tx = dap_tx & dcm_tx; 

wire [23:0]  addr_0;
wire [31:0]  wdata_0, rdata_0;
wire         we_0, re_0;

wire [23:0]  addr_1;
wire [31:0]  wdata_1, rdata_1;
wire         we_1, re_1;

wire [23:0]  addr_2;
wire [31:0]  wdata_2, rdata_2;
wire         we_2, re_2;


system_wrapper  system_wrapper_i (
    .DDR_addr( DDR_addr ),
    .DDR_ba( DDR_ba ),
    .DDR_cas_n( DDR_cas_n ),
    .DDR_ck_n( DDR_ck_n ),
    .DDR_ck_p( DDR_ck_p ),
    .DDR_cke( DDR_cke ),
    .DDR_cs_n( DDR_cs_n ),
    .DDR_dm( DDR_dm ),
    .DDR_dq( DDR_dq ),
    .DDR_dqs_n( DDR_dqs_n ),
    .DDR_dqs_p( DDR_dqs_p ),
    .DDR_odt( DDR_odt ),
    .DDR_ras_n( DDR_ras_n ),
    .DDR_reset_n( DDR_reset_n ),
    .DDR_we_n( DDR_we_n ),
    .FIXED_IO_ddr_vrn( FIXED_IO_ddr_vrn ),
    .FIXED_IO_ddr_vrp( FIXED_IO_ddr_vrp ),
    .FIXED_IO_mio( FIXED_IO_mio ),
    .FIXED_IO_ps_clk( FIXED_IO_ps_clk ),
    .FIXED_IO_ps_porb( FIXED_IO_ps_porb ),
    .FIXED_IO_ps_srstb( FIXED_IO_ps_srstb ),

    .creation_date( CREATION_DATE ),
    .build_date( BUILD_DATE ),
    .us_time( us_time ),
    .rx( debug_rx ),
    .tx( dap_tx ),

    .addr_0( addr_0 ),
    .wdata_0( wdata_0 ),
    .rdata_0( rdata_0 ),
    .we_0( we_0 ),
    .re_0( re_0 ),

    .addr_1( addr_1 ),
    .wdata_1( wdata_1 ),
    .rdata_1( rdata_1 ),
    .we_1( we_1 ),
    .re_1( re_1 ),

    .addr_2( addr_2 ),
    .wdata_2( wdata_2 ),
    .rdata_2( rdata_2 ),
    .we_2( we_2 ),
    .re_2( re_2 ),

    .sysclk( clk )
);


// Module #0: Basic I/O
// Firmware creation/build dates, current time, LEDs, switches, and pushbuttons
basic_io  basic_io_i (
    .clk(            clk                ),
    .creation_date(  CREATION_DATE      ),
    .build_date(     BUILD_DATE         ),
    .us_time(        us_time            ),

    // DAP interface
    .addr(           addr_0             ),
    .wdata(          wdata_0            ),
    .rdata(          rdata_0            ),
    .we(             we_0               ),
    .re(             re_0               ),

    // LEDs, switches, and pushbuttons on the PYNQ-Z2 board
    .leds(           leds_4bits_tri_o   ),
    .LD4(            LD4_rgb_o          ),
    .LD5(            LD5_rgb_o          ),
    .sw(  {sws_2bits_tri_i, btns_4bits_tri_i}  )
);


// DCM Tester -- Outputs a 2 32-bit word telemetry packet every 1 second
wire         test_req;
wire         test_ack;
wire         test_nak;
wire [31:0]  test_data;
wire         test_valid;
wire [25:0]  test_us_time;
dcm_tester #(.CLK_FREQ(CLK_FREQ)) dcm_tester_i (
    .clk(      clk           ),
    .req(      test_req      ),
    .ack(      test_ack      ),
    .nak(      test_nak      ),
    .dout(     test_data     ),
    .valid(    test_valid    ),
    .us_time(  test_us_time  )
);


// Module #1: Debug Capture Module
debug_capture_module #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE))  debug_capture_module_i (
    .clk(       clk         ),
    .us_time(   us_time     ),

    // DAP interface
    .addr(      addr_1      ),
    .wdata(     wdata_1     ),
    .rdata(     rdata_1     ),
    .we(        we_1        ),
    .re(        re_1        ),
    
    // DAP serial interface
    .tx(        dcm_tx      ),

    // Telemetry port 0
    .req0(      test_req      ),
    .ack0(      test_ack      ),
    .nak0(      test_nak      ),
    .din0(      test_data     ),
    .valid0(    test_valid    ),
    .us_time0(  test_us_time  ),

    // Telemetry port 1
    .req1(      1'b0        ),
    .ack1(                  ),
    .nak1(                  ),
    .din1(      32'b0       ),
    .valid1(    1'b0        ),
    .us_time1(              ),

    // Telemetry port 2
    .req2(      1'b0        ),
    .ack2(                  ),
    .nak2(                  ),
    .din2(      32'b0       ),
    .valid2(    1'b0        ),
    .us_time2(              ),

    // Telemetry port 3
    .req3(      1'b0        ),
    .ack3(                  ),
    .nak3(                  ),
    .din3(      32'b0       ),
    .valid3(    1'b0        ),
    .us_time3(              ),

    // Telemetry port 4
    .req4(      1'b0        ),
    .ack4(                  ),
    .nak4(                  ),
    .din4(      32'b0       ),
    .valid4(    1'b0        ),
    .us_time4(              ),

    // Telemetry port 5
    .req5(      1'b0        ),
    .ack5(                  ),
    .nak5(                  ),
    .din5(      32'b0       ),
    .valid5(    1'b0        ),
    .us_time5(              )
);


// Module #2: Spotter
// Finds spots of light in an image. The image may have a significant amount of telegraph (popcorn) noise.
spotter  spotter_i (
    .clk(       clk         ),

    // DAP interface
    .addr(      addr_2      ),
    .wdata(     wdata_2     ),
    .rdata(     rdata_2     ),
    .we(        we_2        ),
    .re(        re_2        )
);


endmodule
