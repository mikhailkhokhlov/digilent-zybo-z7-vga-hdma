`ifndef _VGA_SYNC_GEN_V_
`define  _VGA_SYNC_GEN_V_

module vga_sync_gen (input wire i_pixel_clock,
                     input wire i_reset,
                     output wire o_hsync,
                     output wire o_vsync,
                     output wire o_video_on,
                     output wire [9:0] o_hpos,
                     output wire [9:0] o_vpos);

localparam HSYNC        = 96;
localparam HBACK_PORCH  = 48;
localparam HFRONT_PORCH = 16;
localparam HVIDEO_ON    = 640;

localparam VSYNC        = 2;
localparam VBACK_PORCH  = 33;
localparam VFRONT_PORCH = 10;
localparam VVIDEO_ON    = 480;

reg [9:0] reg_hpos, next_hpos;
reg [9:0] reg_vpos, next_vpos;
reg reg_hsync, next_hsync;
reg reg_vsync, next_vsync;

wire end_of_line;
wire end_of_frame;

always @(posedge i_pixel_clock, posedge i_reset)
begin
  if (i_reset)
    begin
      reg_hpos <= 0;
      reg_vpos <= 0;
      reg_hsync <= 0;
      reg_vsync <= 0;
    end
  else
    begin
      reg_hpos <= next_hpos; 
      reg_vpos <= next_vpos;
      reg_hsync <= next_hsync;
      reg_vsync <= next_vsync;
    end
end

assign end_of_line = (reg_hpos == (HSYNC + HBACK_PORCH + HVIDEO_ON + HFRONT_PORCH));
assign end_of_frame = (reg_vpos == (VSYNC + VBACK_PORCH + VVIDEO_ON + VFRONT_PORCH));

always @*
begin
  if (end_of_line)
    next_hpos = 0;
  else
    next_hpos = reg_hpos + 1;
end

always @*
begin
  next_vpos = reg_vpos;

  if (end_of_frame)
    next_vpos = 0;
  else if (end_of_line)
    next_vpos = reg_vpos + 1;
end

assign o_hpos = reg_hpos;
assign o_vpos = reg_vpos;

assign o_hsync = (reg_hpos >= (HVIDEO_ON + HFRONT_PORCH)) && 
                 (reg_hpos <= (HVIDEO_ON + HFRONT_PORCH + HSYNC - 1));

assign o_vsync = (reg_vpos >= (VVIDEO_ON + VFRONT_PORCH)) &&
                 (reg_vpos >= (VVIDEO_ON + VFRONT_PORCH + VSYNC - 1));

assign o_video_on = (reg_hpos < HVIDEO_ON) && (reg_vpos < VVIDEO_ON);

endmodule

`endif // _VGA_SYNC_GEN_V_