`timescale 1ns/1ns

`define INIT_TEST \
  initial begin \
    $dumpfile(`"`DUMPFILE_PATH`"); \
    $dumpvars(1, `TEST_SUBJECT); \
  end
