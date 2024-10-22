// Copyright (c) 2024 Tlatonf

module i2c_config (
  input  clk_i,
  input  rst_ni,
  output i2c_sclk_o,
  inout  i2c_sdat_io
);

  reg [`I2C_DATA_WIDTH-1:0] i2c_data;
  reg [3:0] register_index = 0;
  parameter LAST_INDEX = 4'ha;

  reg  i2c_start = `PULLDOWN;
  wire i2c_done;
  wire i2c_ack;

  parameter IDLE = 2'b00, START = 2'b01, WAIT_DONE = 2'b10, FINISH = 2'b11;
  reg [1:0] state = IDLE;

  i2c_controll controller (
    .clk_i      (clk_i),
    .i2c_sclk_o (i2c_sclk_o),
    .i2c_sdat_io(i2c_sdat_io),
    .i2c_data_i (i2c_data),
    .i2c_start_i(i2c_start),
    .i2c_done_o (i2c_done),
    .i2c_ack_o  (i2c_ack)
  );

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      register_index <= 4'd0;
      i2c_start <= `PULLDOWN;
      state <= IDLE;

    end else begin
      case (state)
        IDLE: begin
          i2c_start <= `PULLUP;
          state <= START;
        end
        START: begin
          i2c_start <= `PULLDOWN;
          state <= WAIT_DONE;
        end
        WAIT_DONE: begin
          if (i2c_done) begin
            if (i2c_ack) begin
              if (register_index == LAST_INDEX) state <= FINISH;
              else begin
                register_index <= register_index + 1'b1;
                state <= IDLE;
              end
            end else begin
              state <= IDLE;
            end
          end
        end
        FINISH: begin
          state <= IDLE;
        end
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

  always @(*) begin
    case (register_index)
      4'h0:     i2c_data <= {`I2C_ADDR, `POWER_ON_EXCEPT_OUT_REGISTER}; // power on everything except out
      4'h1:     i2c_data <= {`I2C_ADDR, `LEFT_LINEIN_REGISTER};         // left input
      4'h2:     i2c_data <= {`I2C_ADDR, `RIGHT_LINEIN_REGISTER};        // right input
      4'h3:     i2c_data <= {`I2C_ADDR, `LEFT_LINEOU_REGISTER};         // left output
      4'h4:     i2c_data <= {`I2C_ADDR, `RIGHT_LINEOU_REGISTER};        // right output
      4'h5:     i2c_data <= {`I2C_ADDR, `ANALOGUE_PATH_REGISTER};       // analog path
      4'h6:     i2c_data <= {`I2C_ADDR, `DIGITAL_PATH_REGISTER};        // digital path
      4'h7:     i2c_data <= {`I2C_ADDR, `DIGITAL_INTERFACE_REGISTER};   // digital IF
      4'h8:     i2c_data <= {`I2C_ADDR, `SAMPLING_CONTROL_REGISTER};    // sampling rate
      4'h9:     i2c_data <= {`I2C_ADDR, `POWER_ON_REGISTER};            // power on everything
      4'ha:     i2c_data <= {`I2C_ADDR, `ACTIVATE_CONTROL_REGISTER};    // activate
      default:  i2c_data <= {`I2C_ADDR, `RESET_REGISTER};               // reset
    endcase
  end

endmodule
