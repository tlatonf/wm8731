module wrapper (
  input CLOCK_50,
  input [3:0] KEY,
  input [9:0] SW,
  output [9:0] LEDR,

  output FPGA_I2C_SCLK,
  inout  FPGA_I2C_SDAT,

  output AUD_XCK,
  inout  AUD_BCLK,
  inout  AUD_ADCLRCK,
  input  AUD_ADCDAT,
  inout  AUD_DACLRCK,
  output AUD_DACDAT
);
  reg [9:0] counter;
  
  wire CLOCK_12M, CLOCK_48M;
  reg CLOCK_48K;
  
  pll clock_generator (
    .refclk(CLOCK_50),
	 .rst(KEY[0]),
	 .outclk_0(CLOCK_12M),
	 .outclk_1(CLOCK_48M)
  );
  
  always @(posedge CLOCK_48M or negedge KEY[0]) begin
    if (!KEY[0]) begin
      counter <= 0;
      CLOCK_48K <= 0;
    end else begin
      if (counter < 1000 - 1) begin
        counter <= counter + 1;
      end else begin
        counter <= 0;
        CLOCK_48K <= ~CLOCK_48K;
      end
    end
  end
  
  top top_inst (
    .config_clk_i (CLOCK_12M),
    .codec_clk_i  (CLOCK_12M),
    .filter_clk_i (CLOCK_48K),
    .rst_ni       (KEY[0]),
    .sel_i        (SW[1:0]),

    .i2c_sclk_o   (FPGA_I2C_SCLK),
    .i2c_sdat_io  (FPGA_I2C_SDAT),

    .xck_o        (AUD_XCK),
    .bclk_o       (AUD_BCLK),
    .daclrck_o    (AUD_DACLRCK),
    .dacdat_o     (AUD_DACDAT),
    .adclrck_o    (AUD_ADCLRCK),
    .adcdat_i     (AUD_ADCDAT)
  );

endmodule