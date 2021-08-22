`include "Main.v"
`include "TestBench.v"

module MainTest();

  `INIT_TEST

  integer i;

  reg clk = 0;

  Main uut(.i_Clk(clk));

  initial begin
    for (i = 0; i < 100; i = i + 1) begin
      #20 clk = ~clk;
    end
  end

endmodule
