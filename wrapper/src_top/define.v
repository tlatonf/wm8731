// Copyright (c) 2024 Tlatonf

`define DATA_WIDTH  24

`define ENABLE      1'b1
`define DISABLE     1'b0

`define LEFT_CLK    1'b1
`define RIGHT_CLK   1'b0

`define FILTER_SEL  2'b01
`define BYPASS_SEL  2'b10

`define PULLUP      1'b1
`define PULLDOWN    1'b0

`define I2C_DATA_WIDTH                24
`define I2C_ADDR                      8'h34
`define POWER_ON_EXCEPT_OUT_REGISTER  16'h0c10
`define LEFT_LINEIN_REGISTER          16'h0017
`define RIGHT_LINEIN_REGISTER         16'h0217
`define LEFT_LINEOU_REGISTER          16'h0479
`define RIGHT_LINEOU_REGISTER         16'h0679
`define ANALOGUE_PATH_REGISTER        16'h0812
`define DIGITAL_PATH_REGISTER         16'h0a04
`define DIGITAL_INTERFACE_REGISTER    16'h0e01
`define SAMPLING_CONTROL_REGISTER     16'h1020
`define POWER_ON_REGISTER             16'h0c00
`define ACTIVATE_CONTROL_REGISTER     16'h1201
`define RESET_REGISTER                16'h0000
