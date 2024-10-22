// Copyright (c) 2024 Tlatonf

module i2c_controll (
  input clk_i,

  output i2c_sclk_o,
  inout  i2c_sdat_io,

  input  i2c_start_i,
  output i2c_done_o,
  output i2c_ack_o,

  input [`I2C_DATA_WIDTH-1:0] i2c_data_i
);

  reg [`I2C_DATA_WIDTH-1:0] data;
  reg [4:0] stage;
  reg [6:0] sclk_divider;
  reg clock_en = `DISABLE;
  reg sdat = `PULLUP;

  wire midlow = (sclk_divider == 7'h1f);

  reg [2:0] acks;
  parameter LAST_STAGE = 5'd29;

  always @(posedge clk_i) begin
    if (i2c_start_i) begin
      sclk_divider <= 7'd0;
      stage <= 5'd0;
      clock_en = `DISABLE;
      sdat <= `PULLUP;
      acks <= {3{`PULLUP}};
      data <= i2c_data_i;
    end else begin
      if (sclk_divider == 7'd127) begin
        sclk_divider <= 7'd0;

        if (stage != LAST_STAGE) stage <= stage + 1'b1;

        case (stage)
          // after i2c_start_i
          5'd0:  clock_en <= `ENABLE;
          // receive acks
          5'd9:  acks[0] <= i2c_sdat_io;
          5'd18: acks[1] <= i2c_sdat_io;
          5'd27: acks[2] <= i2c_sdat_io;
          // before stop
          5'd28: clock_en <= 1'b0;
        endcase
      end else sclk_divider <= sclk_divider + 1'b1;

      if (midlow) begin
        case (stage)
          // i2c_start_i
          5'd0:  sdat <= `PULLDOWN;
          // byte 1
          5'd1:  sdat <= data[23];
          5'd2:  sdat <= data[22];
          5'd3:  sdat <= data[21];
          5'd4:  sdat <= data[20];
          5'd5:  sdat <= data[19];
          5'd6:  sdat <= data[18];
          5'd7:  sdat <= data[17];
          5'd8:  sdat <= data[16];
          // i2c_ack_o 1
          5'd9:  sdat <= `PULLUP;
          // byte 2
          5'd10: sdat <= data[15];
          5'd11: sdat <= data[14];
          5'd12: sdat <= data[13];
          5'd13: sdat <= data[12];
          5'd14: sdat <= data[11];
          5'd15: sdat <= data[10];
          5'd16: sdat <= data[9];
          5'd17: sdat <= data[8];
          // i2c_ack_o 2
          5'd18: sdat <= `PULLUP;
          // byte 3
          5'd19: sdat <= data[7];
          5'd20: sdat <= data[6];
          5'd21: sdat <= data[5];
          5'd22: sdat <= data[4];
          5'd23: sdat <= data[3];
          5'd24: sdat <= data[2];
          5'd25: sdat <= data[1];
          5'd26: sdat <= data[0];
          // i2c_ack_o 3
          5'd27: sdat <= `PULLUP;
          // stop
          5'd28: sdat <= `PULLDOWN;
          5'd29: sdat <= `PULLUP;
        endcase
      end
    end
  end

  // don't toggle the clock unless we're sending data
  // clock will also be kept high when sending i2c_start_i and STOP symbols
  assign i2c_sclk_o = (!clock_en) || sclk_divider[6];
  // rely on pull-up resistor to set SDAT high
  assign i2c_sdat_io = (sdat) ? 1'bz : `PULLDOWN;
  assign i2c_ack_o  = (acks == {3{`PULLDOWN}});
  assign i2c_done_o = (stage == LAST_STAGE);

endmodule
