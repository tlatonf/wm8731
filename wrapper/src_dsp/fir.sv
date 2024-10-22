// Copyright (c) 2024 Tlatonf

module fir (
  input  clk_i,
  input  rst_ni,
  input  wire [`WIDTH_DATA-1:0] data_i,
  output reg [`WIDTH_DATA-1:0] data_o
);
 
  reg signed [`WIDTH_DATA-1:0]  delay     [0:`NO_TAPS];
  reg signed [`WIDTH_COEFF-1:0] coeff     [1:`NO_TAPS+1];

  reg signed [`WIDTH_PROC-1:0]  product   [1:`NO_TAPS];
  reg signed [`WIDTH_PROC-1:0]  product_cast;

  reg signed [`WIDTH_SUM-1:0]   sum       [1:`NO_TAPS-1];
  reg signed [`WIDTH_SUM-1:0]   sum_cast;


  //logic [`WIDTH_DATA-1:0] data [0:$clog2(663706)-1];
  //logic [`WIDTH_DATA-1:0] data_i;
  initial begin
    coeff = '{(`NO_TAPS+1){`WIDTH_COEFF'h0}};
    $readmemb(`FILE_COEFF, coeff);
    //$readmemh(`FILE_TB_OUTPUT, data);
  end

 
  always @(posedge clk_i or negedge rst_ni) begin 
    if (!rst_ni) begin 
      delay <= '{(`NO_TAPS+1){`WIDTH_DATA'h0}};

    end else begin 
      for (int i = 0; i < `NO_TAPS; i = i + 1) begin
        if (i == 0) begin
          delay[i] <= data_i;
        end else begin
          delay[i] <= delay[i-1]; 
        end
      end

    end
  end

  always @(posedge clk_i) begin 
    for (int i = 1; i <= `NO_TAPS; i = i + 1) begin
      product[i] <= delay[i-1] * coeff[i];
    end
    product_cast <= product[1];
  end

  always @(*) begin
    for (int i = 1; i < `NO_TAPS; i = i + 1) begin
      if (i == 1) begin
        sum[i] <= product_cast + product[2];
      end else begin
        sum[i] <= sum[i-1] + product[i+1];
      end
      sum_cast <= sum[`NO_TAPS-1];
    end
  end
  
  always @ (posedge clk_i) begin
    if (!rst_ni) begin
      data_o <= '{`WIDTH_DATA{1'h0}};
    end else begin
      data_o <= {sum_cast[`WIDTH_SUM-1 -: 16]};
    end
  end

endmodule 
