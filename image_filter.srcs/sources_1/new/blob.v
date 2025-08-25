`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:        
// 
// Create Date:     8/25/2025
// Design Name:     image_filter
// Module Name:     blob.v
// Project Name:
// Target Devices:  PYNQ-Z2
// Tool Versions:   Xilinx Vivado 2022.2
// Description:
//
//   !!!UNFINISHED
//
//      This module accumulates a blob of nonzero-intensity pixels.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module blob(
    input               clk,

    // Pixel stream in
    input               pixel_valid_nz,  // pixel_x/y/i are valid and pixel_i is nonzero
    input      [6:0]    pixel_x,         // pixel's X coordinate
    input      [6:0]    pixel_y,         // pixel's Y coordinate
    input      [15:0]   pixel_i,         // intensity (1..65535) 

    // Blob stream
    // 162-bit Blob struct, listed MSBit first:
    //   Bits  Field
    //     1   valid flag (1 = this struct is valid, 0 = invalid)
    //   4*7   bounding box' parameters x0, y0, x1, and y1 (= pixel set x0<=x<=x1 and y0<=y<=y1) 
    //    15   number of nonzero pixels (1 .. 16384)
    //    16   max. intensity
    //    30   sum of intensities
    //    36   sum over x * intensity
    //    36   sum over y * intensity
    // Each field is an unsigned integer.
    input      [161:0]  blob_in,
    output reg [161:0]  blob_out,

    // Control
    input               can_grab,       // iff 1 and this blob is null, accept any nonzero pixel

    // Status
    output              empty,          // iff 1, this blob is null
    output              captured,       // iff 1, !empty and pixel_* is adjacent or inside the bounding box bbX0, bbY0, bbX1, bbY1

    // Flush
    input               flush,          // when pulsed, flush blob if valid && bbY1<=flush_y
    input      [6:0]    flush_y
);

    // Blob
    reg         valid   = 0;    // if 0, the blob is null; if 1, blob is defined by the fields below
    reg [6:0]   bbX0    = 0;    // min. X-coordinate of bounding box (0 .. 127)
    reg [6:0]   bbY0    = 0;    // min. Y-coordinate of bounding box (0 .. 127)
    reg [6:0]   bbX1    = 0;    // max. X-coordinate of bounding box (bbX0 .. 127)
    reg [6:0]   bbY1    = 0;    // max. Y-coordinate of bounding box (bbY0 .. 127)
    reg [14:0]  count   = 0;    // number of nonzero-intensity pixels (typically 1 .. 16384)
    reg [15:0]  max_i   = 0;    // max. intensity (0 .. 65535)
    reg [29:0]  sum_i   = 0;    // sum of intensities (0 .. 65535*128*128)
    reg [35:0]  sum_xi  = 0;    // sum over X-coordinate * intensity (0 .. 68181565440)
    reg [35:0]  sum_yi  = 0;    // sum over Y-coordinate * intensity (0 .. 68181565440)

    wire absorb  =  pixel_x >= (bbX0 == 0   ? 0   : bbX0 - 1)  &&   // assuming pixel_valid_nz && valid, would pixel be absorbed?
                    pixel_x <= (bbX1 == 127 ? 127 : bbX1 + 1)  &&
                    pixel_y >= (bbY0 == 0   ? 0   : bbY0 - 1)  &&
                    pixel_y <= (bbY1 == 127 ? 127 : bbY1 + 1);

    assign empty     =  !valid;
    assign captured  =  pixel_valid_nz && valid && absorb;          // will pixel be absorbed into an existing blob?
    
    wire [22:0]  xi  =  pixel_x * pixel_i;   // !!!Verify multiplication's bit width is 23 (= 7 + 16)
    wire [22:0]  yi  =  pixel_y * pixel_i;   // !!!Verify multiplication's bit width is 23 (= 7 + 16)


    always @(posedge clk) begin

        blob_out <= blob_in;

        if (pixel_valid_nz)
            if (valid) begin                // blob currently exists?
                if (absorb) begin           //   pixel_* is adjacent or inside the blob's bounding box?
                    bbX0    <=  pixel_x; 
                    bbY0    <=  pixel_y; 
                    bbX1    <=  pixel_x; 
                    bbY1    <=  pixel_y;
                    count   <=  count + 1;
                    if (max_i < pixel_i)  max_i <= pixel_i;
                    sum_i   <=  sum_i + pixel_i;
                    sum_xi  <=  sum_xi + xi; 
                    sum_yi  <=  sum_yi + yi;
                end
            end
            else if (can_grab) begin        // blob is currently null (empty), and this module may grab the pixel?
                valid   <=  1;
                bbX0    <=  pixel_x; 
                bbY0    <=  pixel_y; 
                bbX1    <=  pixel_x; 
                bbY1    <=  pixel_y;
                count   <=  1;
                max_i   <=  pixel_i;
                sum_i   <=  pixel_i;
                sum_xi  <=  xi; 
                sum_yi  <=  yi;
            end

        if (flush  &&  valid  &&  bbY1 <= flush_y) begin    // flush the current blob, if any?
            blob_out <= { 1'b1,                             // Note, flush and pixel_valid_nz shouldn't be asserted at the same time
                          bbX0, bbY0, bbX1, bbY1,
                          count,
                          max_i,
                          sum_i,
                          sum_xi,
                          sum_yi  };
            valid <= 0;
        end
    end

endmodule
