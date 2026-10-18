`timescale 1ns / 1ps

module fifo_wrapper
    (
        input wire clk,
        input wire srst,
        input wire [15:0] data_in,
        input wire write_enable,
        input wire read_enable,
    
        output wire [15:0] data_out,
        output wire valid,
        output wire empty,
        output wire full,
        output wire almost_empty,
        output wire almost_full
    );

    sc_fifo #(.WIDTH(16),
              .DEPTH(32),
              .ALMOST_EMPTY_THRESHOLD(1),
              .ALMOST_FULL_THRESHOLD(31),
              .READ_LATENCY(1)
             ) fifo_inst
        (
            .clk(clk),
            .srst(srst),
            .data_in(data_in),
            .write_enable(write_enable),
            .read_enable(read_enable),
            .data_out(data_out),
            .valid(valid),
            .empty(empty),
            .full(full),
            .almost_empty(almost_empty),
            .almost_full(almost_full)
        );

endmodule
