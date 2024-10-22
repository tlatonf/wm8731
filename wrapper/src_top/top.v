// Copyright (c) 2024 Tlatonf

module top (
  input config_clk_i,
  input codec_clk_i,
  input filter_clk_i,
  input rst_ni,
  input [1:0] sel_i,

  output i2c_sclk_o,
  inout  i2c_sdat_io,

  output wire xck_o,
  output wire bclk_o,
  output wire daclrck_o,
  output wire dacdat_o,
  output wire adclrck_o,
  input  wire adcdat_i
);
 
  wire [`DATA_WIDTH-1:0] adc_left, adc_right;
  reg  [`DATA_WIDTH-1:0] dac_left, dac_right;
  wire  [`DATA_WIDTH-1:0] filter_left_out, filter_right_out;

  i2c_config wm8731_config (
    .clk_i      (config_clk_i),
    .rst_ni     (rst_ni),
    .i2c_sclk_o (i2c_sclk_o),
    .i2c_sdat_io(i2c_sdat_io)
  );

  codec wm8731_codec (
    .xclk_i    (codec_clk_i),
    .rst_ni    (rst_ni),

    .left_o    (adc_left),
    .right_o   (adc_right),
    .left_i    (dac_left),
    .right_i   (dac_right),

    .ready_o   (done),

    .xck_o     (xck_o),
    .bclk_o    (bclk_o),
    .daclrck_o (daclrck_o),
    .dacdat_o  (dacdat_o),
    .adclrck_o (adclrck_o),
    .adcdat_i  (adcdat_i)
  );

  fir filter_left (
    .clk_i  (filter_clk_i),
    .rst_ni (rst_ni),
    .data_i (adc_left),
    .data_o (filter_left_out)
  );

  fir filter_right (
    .clk_i  (!filter_clk_i),
    .rst_ni (rst_ni),
    .data_i (adc_right),
    .data_o (filter_right_out)
  );

  always @(*) begin
    case (sel_i)
      `FILTER_SEL: begin
        dac_left <= filter_left_out;
        dac_right <= filter_right_out;
      end
      `BYPASS_SEL: begin
        dac_left <= adc_left;
        dac_right <= adc_right;
      end
      default: begin
        dac_left <= 0;
        dac_right <= 0;
      end
    endcase
  end

endmodule