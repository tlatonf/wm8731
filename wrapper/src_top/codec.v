// Copyright (c) 2024 Tlatonf

module codec #(
    parameter OVERSAMPLE = 250,
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter CHANNELS   = 2
) (
    input wire xclk_i,
    input wire rst_ni,

    input wire signed [DATA_WIDTH-1:0] right_i,
    input wire signed [DATA_WIDTH-1:0] left_i,

    output wire signed [DATA_WIDTH-1:0] right_o,
    output wire signed [DATA_WIDTH-1:0] left_o,
    output wire                         ready_o,

    output wire xck_o,
    output wire bclk_o,
    output wire daclrck_o,
    output wire dacdat_o,
    output wire adclrck_o,
    input  wire adcdat_i
);

  localparam BCLK_VALUE = (OVERSAMPLE / (DATA_WIDTH * CHANNELS * 2)) - 1;
  localparam LRCK_VALUE = (OVERSAMPLE / (CHANNELS)) - 1;

  reg [DATA_WIDTH-1:0] dac_right = 0, dac_left = 0;
	reg [DATA_WIDTH-1:0] adc_left = 0, adc_right = 0;
	reg [DATA_WIDTH-1:0] adc_left_reg = 0, adc_right_reg = 0;

  reg [$clog2(DATA_WIDTH):0] bclk_counter = BCLK_VALUE, lrck_counter = 2 * (DATA_WIDTH - 1);
  reg [$clog2(DATA_WIDTH)-1:0] bits_counter = DATA_WIDTH - 1;
  reg lrck = 1, bclk = 1, valid_out = `DISABLE;
  reg done = `DISABLE;

  parameter IDLE = 2'b00, BLCK = 2'b01;
  reg [1:0] state = IDLE;

  always @(posedge xclk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      dac_right <= 0;
      dac_left <= 0;
      adc_left <= 0;
      adc_right <= 0;

      lrck <= 1'b1;
      bclk <= 1'b1;
      bclk_counter <= BCLK_VALUE;
      lrck_counter <= 2*(DATA_WIDTH-1);
      bits_counter <= DATA_WIDTH-1;
      valid_out <= `DISABLE;
      done <= `DISABLE;

      state <= IDLE;

    end else begin
      case (state)
        IDLE: begin
          adc_left_reg <= adc_left;
          adc_right_reg <= adc_right;
          valid_out <= `ENABLE;

          dac_right <= 0;
          dac_left <= 0;
          adc_left <= 0;
          adc_right <= 0;

          bclk <= 1'b0;
          bclk_counter <= BCLK_VALUE;
          lrck_counter <= 2*(DATA_WIDTH-1);
          bits_counter <= DATA_WIDTH-1;
          done <= `DISABLE;

          dac_right <= right_i;
          dac_left <= left_i;
          lrck <= 1'b1;

          state <= BLCK;
        end
        BLCK: begin
          valid_out <= `DISABLE;
          if (bclk_counter == 1'b0) begin
            if (bclk == 1'b1) begin
              lrck_counter <= lrck_counter - 1'b1;
							case (lrck)
								`LEFT_CLK: dac_left <= {dac_left[DATA_WIDTH-2:0], 1'b0};
								`RIGHT_CLK: dac_right <= {dac_right[DATA_WIDTH-2:0], 1'b0};
							endcase
            end else begin
              if (!done) begin
                done <= (bits_counter == 0) ? `ENABLE : `DISABLE;
								case (lrck)
									`LEFT_CLK: begin
                  	adc_left <= {adc_left[DATA_WIDTH-2:0], adcdat_i};
                  	bits_counter <= bits_counter - 1'b1;
                	end
									`RIGHT_CLK: begin
                  	adc_right <= {adc_right[DATA_WIDTH-2:0], adcdat_i};
                  	bits_counter <= bits_counter - 1'b1;
                	end
								endcase
              end
            end

            bclk <= !bclk;
            bclk_counter <= BCLK_VALUE;

            if (lrck == `LEFT_CLK && lrck_counter == 0) begin
              lrck <= 1'b0;
              lrck_counter <= 2*(DATA_WIDTH-1);
              bits_counter <= DATA_WIDTH-1;
              done <= `DISABLE;

              state <= BLCK;
            end
            if (lrck == `RIGHT_CLK && lrck_counter == 0) begin
              lrck_counter <= 2 * (DATA_WIDTH - 1);
              bits_counter <= DATA_WIDTH - 1;
              //valid_out		<= `ENABLE;
              done <= `DISABLE;

              state <= IDLE;
            end
          end else begin
            bclk_counter <= bclk_counter - 1'b1;
            state <= BLCK;
          end
        end
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

  assign xck_o = xclk_i;
  assign bclk_o = bclk;
  assign daclrck_o = lrck;
  assign adclrck_o = lrck;
  assign dacdat_o = (lrck == `LEFT_CLK) ? (dac_left[DATA_WIDTH-1]) : (dac_right[DATA_WIDTH-1]);
  assign left_o = adc_left_reg;
  assign right_o = adc_right_reg;
  assign ready_o = valid_out;

endmodule