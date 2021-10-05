`ifndef _RGB2DVI_V_
`define _RGB2DVI_V_

`timescale 1ns / 1ps

module tmds_encoder(input i_clk,
                    input i_reset,
                    input [7:0] i_data,
                    input [1:0] i_ctrl, // {vsync, hsynq}
                    input i_video_on,
                    output reg [9:0] o_tmds);

function [3:0] N0;
    input [7:0] d;
    integer i;
    begin
        N0 = 0;
        for (i = 0; i < 8; i = i + 1)
            N0 = N0 + !d[i];
    end
endfunction

function [3:0] N1;
    input [7:0] d;
    integer i;
    begin
        N1 = 0;
        for (i = 0; i < 8; i = i + 1)
            N1 = N1 + d[i];
    end
endfunction

reg signed [7:0] reg_cnt = 0;

reg [8:0] q_m;

/* stage 1 */
always @(*)
  if ((N1(i_data) > 4) | (N1(i_data) == 4) & (i_data[0] == 0))
    begin
      q_m[0] =           i_data[0];
      q_m[1] = q_m[0] ~^ i_data[1];
      q_m[2] = q_m[1] ~^ i_data[2];
      q_m[3] = q_m[2] ~^ i_data[3];
      q_m[4] = q_m[3] ~^ i_data[4];
      q_m[5] = q_m[4] ~^ i_data[5];
      q_m[6] = q_m[5] ~^ i_data[6];
      q_m[7] = q_m[6] ~^ i_data[7];
      q_m[8] = 1'b0;
    end
  else
    begin
      q_m[0] =          i_data[0];
      q_m[1] = q_m[0] ^ i_data[1];
      q_m[2] = q_m[1] ^ i_data[2];
      q_m[3] = q_m[2] ^ i_data[3];
      q_m[4] = q_m[3] ^ i_data[4];
      q_m[5] = q_m[4] ^ i_data[5];
      q_m[6] = q_m[5] ^ i_data[6];
      q_m[7] = q_m[6] ^ i_data[7];
      q_m[8] = 1'b1;
    end /* (N1(i_data) > 4) | (N1(i_data) == 4) & (i_data[0] == 0) */

/* stage 2 */
always @(posedge i_clk, posedge i_reset)
  if (i_reset)
    reg_cnt <= 9'b0;
  else if (i_video_on)
    if ((reg_cnt == 0) | (N1(q_m[7:0]) == N0(q_m[7:0])))
      reg_cnt <= (q_m[8] == 0) ? 
                 reg_cnt + (N0(q_m[7:0]) - N1(q_m[7:0])) : 
                 reg_cnt + (N1(q_m[7:0]) - N0(q_m[7:0]));
    else
      reg_cnt <= ((reg_cnt > 0 & (N1(q_m[7:0]) > N0(q_m[7:0]))) |
                  (reg_cnt < 0 & (N0(q_m[7:0]) > N1(q_m[7:0])))) ?
                 reg_cnt + 2 * q_m[8] + (N0(q_m[7:0]) - N1(q_m[7:0])) :
                 reg_cnt + 2 * (~q_m[8]) + (N1(q_m[7:0]) - N0(q_m[7:0]));
  else
    reg_cnt <= 0;

always @(posedge i_clk)
  begin
    if (i_video_on)
      begin
        if ((reg_cnt == 0) | (N1(q_m[7:0]) == N0(q_m[7:0])))
          begin
            o_tmds[9]   <= ~q_m[8];
            o_tmds[8]   <=  q_m[8];
            o_tmds[7:0] <=  q_m[8] ? q_m[7:0] : ~q_m[7:0];
          end
        else
          begin
            if ((reg_cnt > 0 & (N1(q_m[7:0]) > N0(q_m[7:0]))) |
                (reg_cnt < 0 & (N0(q_m[7:0]) > N1(q_m[7:0]))))
              begin
                o_tmds[9]   <= 1;
                o_tmds[8]   <= q_m[8];
                o_tmds[7:0] <= ~q_m[7:0];
              end
            else
              begin
                o_tmds[9]   <= 0;
                o_tmds[8]   <= q_m[8];
                o_tmds[7:0] <= q_m[7:0];
              end 
        end /* ((reg_cnt == 0) | (N1(q_m[7:0]) == N0(q_m[7:0]))) */
      end
    else /* !i_video_on */
      begin
        /* hdmi control data period */
        /* i_ctrl = {vsync, hsync} */
        case (i_ctrl)
          2'b00: o_tmds <= 10'b1101010100;
          2'b01: o_tmds <= 10'b0010101011;
          2'b10: o_tmds <= 10'b0101010100;
          2'b11: o_tmds <= 10'b1010101011;
        endcase
      end
  end /* always */

endmodule

module rgb2dvi(input i_pixel_clock,
               input i_tmds_clock,
               input i_reset,
               input [7:0] i_red,
               input [7:0] i_green,
               input [7:0] i_blue,
               input i_hsync,
               input i_vsync,
               input i_video_on,
               output [2:0] o_tmds_p,
               output [2:0] o_tmds_n,
               output o_tmds_clk_p,
               output o_tmds_clk_n);
               
wire [9:0] tmds_red;
wire [9:0] tmds_green;
wire [9:0] tmds_blue;

tmds_encoder encodeR(.i_clk(i_pixel_clock),
                     .i_reset(i_reset),
                     .i_data(i_red),
                     .i_ctrl(2'b00),
                     .i_video_on(i_video_on),
                     .o_tmds(tmds_red));
                     
tmds_encoder encodeG(.i_clk(i_pixel_clock),
                     .i_reset(i_reset),
                     .i_data(i_green),
                     .i_ctrl(2'b00),
                     .i_video_on(i_video_on),
                     .o_tmds(tmds_green));
                     
tmds_encoder encodeB(.i_clk(i_pixel_clock),
                     .i_reset(i_reset),
                     .i_data(i_blue),
                     .i_ctrl({i_vsync, i_hsync}),
                     .i_video_on(i_video_on),
                     .o_tmds(tmds_blue));

reg [3:0] mod10_counter;
reg tmds_shift_load;

reg [9:0] tmds_shift_red;
reg [9:0] tmds_shift_green;
reg [9:0] tmds_shift_blue;

always @(posedge i_tmds_clock, posedge i_reset)
  if (i_reset)
    begin
      mod10_counter   <= 0;
      tmds_shift_load <= 0;
    end
  else
    begin
      mod10_counter   <= (mod10_counter == 4'd9) ? 4'd0 : mod10_counter + 4'd1;
      tmds_shift_load <= (mod10_counter == 4'd9) ? 1'b1 : 1'b0;
    end
    
 always @(posedge i_tmds_clock, posedge i_reset)
   if (i_reset)
     begin
       tmds_shift_red   <= 10'b0;
       tmds_shift_green <= 10'b0;
       tmds_shift_blue  <= 10'b0;
     end
   else
     begin
       tmds_shift_red   <= tmds_shift_load ? tmds_red   : tmds_shift_red[9:1]; 
       tmds_shift_green <= tmds_shift_load ? tmds_green : tmds_shift_green[9:1];
       tmds_shift_blue  <= tmds_shift_load ? tmds_blue  : tmds_shift_blue[9:1];
     end

  OBUFDS OBUFDS_red  (.I(tmds_shift_red[0]),   .O(o_tmds_p[2]),  .OB(o_tmds_n[2]));  
  OBUFDS OBUFDS_green(.I(tmds_shift_green[0]), .O(o_tmds_p[1]),  .OB(o_tmds_n[1]));
  OBUFDS OBUFDS_blue (.I(tmds_shift_blue[0]),  .O(o_tmds_p[0]),  .OB(o_tmds_n[0]));
  OBUFDS OBUFDS_clock(.I(i_pixel_clock),       .O(o_tmds_clk_p), .OB(o_tmds_clk_n));
  
endmodule

`endif // _RGB2DVI_V_