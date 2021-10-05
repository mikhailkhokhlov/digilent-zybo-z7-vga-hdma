`timescale 1ns / 1ps

`include "vga_sync_gen.v"
`include "rgb2dvi.v"

module generate_output(input [9:0] i_pixel_x,
                       input [9:0] i_pixel_y,
                       input i_video_on,
                       output [3:0] o_red,
                       output [3:0] o_green,
                       output [3:0] o_blue);
                       
assign o_red = (i_video_on && i_pixel_x >= 0 && i_pixel_x <= 213) ? 4'b1111 : 4'b0000;
assign o_green = (i_video_on && i_pixel_x >= 214 && i_pixel_x <= 427) ? 4'b1111 : 4'b0000;
assign o_blue = (i_video_on && i_pixel_x >= 428 && i_pixel_y <= 639) ? 4'b1111 : 4'b0000;                       
                       
endmodule                       

module vga_sync_gen_top(input i_system_clock,
                        input i_reset,
                        output [3:0] o_red,
                        output [3:0] o_green,
                        output [3:0] o_blue,
                        output o_hsync,
                        output o_vsync,
                        output [2:0] hdmi_tx_p,
                        output [2:0] hdmi_tx_n,
                        output hdmi_tx_clk_p,
                        output hdmi_tx_clk_n);
    
wire pixel_clock;
wire tmds_clock;
wire video_on;
wire [9:0] pixel_x;
wire [9:0] pixel_y;

clk_wiz_0 clock_wizard0(.i_clk_system(i_system_clock),
                        .o_clk_pixel(pixel_clock),
                        .o_clk_tmds(tmds_clock));

vga_sync_gen vga_sync_gen0(.i_pixel_clock(pixel_clock),
                           .i_reset(i_reset),
                           .o_hsync(o_hsync),
                           .o_vsync(o_vsync),
                           .o_video_on(video_on),
                           .o_hpos(pixel_x),
                           .o_vpos(pixel_y));
                           
generate_output generate_output0(.i_pixel_x(pixel_x),
                                 .i_pixel_y(pixel_y),
                                 .i_video_on(video_on),
                                 .o_red(o_red),
                                 .o_green(o_green),
                                 .o_blue(o_blue));
/*
wire [2:0] hdmi_tx_p;
wire [2:0] hdmi_tx_n;
wire hdmi_tx_clk_p;
wire hdmi_tx_clk_n;
*/
rgb2dvi rgb2dvi0(.i_pixel_clock(pixel_clock),
                 .i_tmds_clock(tmds_clock),
                 .i_reset(i_reset),
                 .i_red({o_red, 4'b0}),
                 .i_green({o_green, 4'b0}),
                 .i_blue({o_blue, 4'b0}),
                 .i_hsync(o_hsync),
                 .i_vsync(o_vsync),
                 .i_video_on(video_on),
                 .o_tmds_p(hdmi_tx_p),
                 .o_tmds_n(hdmi_tx_n),
                 .o_tmds_clk_p(hdmi_tx_clk_p),
                 .o_tmds_clk_n(hdmi_tx_clk_n));                                 
endmodule
