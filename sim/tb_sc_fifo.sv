`timescale 1ns / 1ps

module tb_sc_fifo();

    parameter int WIDTH = 16;
    parameter int DEPTH = 32;
    parameter int ALMOST_EMPTY_THRESHOLD = 1;
    parameter int ALMOST_FULL_THRESHOLD = 31;
    parameter int READ_LATENCY = 1;

    logic clk;
    logic srst;
    logic [WIDTH - 1:0] data_in;
    logic write_enable;
    logic read_enable;
    logic [$clog2(DEPTH + 1) - 1:0] data_count;
    logic [WIDTH - 1:0] data_out;
    logic valid;
    logic almost_full;
    logic almost_empty;
    logic full;
    logic empty;
    logic [WIDTH - 1:0] test_data [0:DEPTH - 1];

    integer i;

    sc_fifo #
        (
            .WIDTH(WIDTH),
            .DEPTH(DEPTH),
            .ALMOST_EMPTY_THRESHOLD(ALMOST_EMPTY_THRESHOLD),
            .ALMOST_FULL_THRESHOLD(ALMOST_FULL_THRESHOLD),
            .READ_LATENCY(READ_LATENCY)
        ) DUT
        (
            .clk(clk),
            .srst(srst),
            .data_in(data_in),
            .write_enable(write_enable),
            .read_enable(read_enable),
            .data_count(data_count),
            .data_out(data_out),
            .valid(valid),
            .almost_full(almost_full),
            .almost_empty(almost_empty),
            .full(full),
            .empty(empty)
        );

    initial
        begin
            $readmemh("input_data.txt", test_data);
            clk = 1'b0;
        end

    always #10 clk = ~clk;

    // RESET TASK
    task reset_fifo;
        begin
            @(negedge clk);
            srst = 1'b1;
            write_enable = 1'b0;
            read_enable = 1'b0;
            data_in = '0;
            @(posedge clk);
            @(negedge clk);
            srst = 1'b0;
        end
    endtask

    // WRITE TASK
    task write_fifo(input logic [WIDTH - 1:0] data);
        begin
            @(negedge clk);
            data_in = data;
            write_enable = 1'b1;
            read_enable = 1'b0;
            @(posedge clk);
            @(negedge clk);
            write_enable = 1'b0;
        end
    endtask

    // READ AND CHECK TASK
    task read_fifo(input logic [WIDTH - 1:0] expected_data);
        begin
            @(negedge clk);
            read_enable = 1'b1;
            write_enable = 1'b0;
    
            @(posedge clk);
            #1;
    
            // Wait for additional pipeline stages
            for (int j = 1; j < READ_LATENCY; j = j + 1)
                begin
                    @(posedge clk);
                    #1;
                end
    
            if (valid !== 1'b1)
                begin
                    $error("READ ERROR: valid should be 1");
                end
    
            if (data_out !== expected_data)
                begin
                    $error("READ ERROR: expected %h, received %h", expected_data, data_out);
                end
    
            @(negedge clk);
            read_enable = 1'b0;
        end
    endtask

    // CHECK DATA COUNT TASK
    task check_count(input int expected_count);
        begin
            if (data_count !== expected_count)
                begin
                    $error("COUNT ERROR: expected %0d, received %0d", expected_count, data_count);
                end
        end
    endtask

    // BEGIN TESTS
    initial
        begin
        // Initial values
            srst = 1'b0;
            data_in = '0;
            write_enable = 1'b0;
            read_enable = 1'b0;

        // TEST 1: RESET
            reset_fifo();
            
            if (data_count !== 0)
                begin
                    $error("RESET ERROR: data_count should be 0");
                end
            if (empty !== 1'b1)
                begin
                    $error("RESET ERROR: empty should be 1");
                end
            if (full !== 1'b0)
                begin
                    $error("RESET ERROR: full should be 0");
                end
            if (valid !== 1'b0)
                begin
                    $error("RESET ERROR: valid should be 0");
                end
            if (data_out !== '0)
                begin
                    $error("RESET ERROR: data_out should be 0");
                end

            $display("RESET TEST PASSED");

        // TEST 2: REQUIRED DATA PATTERNS
            reset_fifo();
            write_fifo(16'h0000);
            write_fifo(16'hFFFF);
            write_fifo(16'hAAAA);
            write_fifo(16'h5555);
            check_count(4);

            if (empty !== 1'b0)
                begin
                    $error("PATTERN ERROR: FIFO should not be empty");
                end

            read_fifo(16'h0000);
            read_fifo(16'hFFFF);
            read_fifo(16'hAAAA);
            check_count(1);

            if (almost_empty !== 1'b1)
                begin
                    $error("ALMOST EMPTY ERROR: almost_empty should be 1");
                end

            read_fifo(16'h5555);
            check_count(0);

            if (empty !== 1'b1)
                begin
                    $error("EMPTY ERROR: FIFO should be empty");
                end

            $display("DATA PATTERN / FIFO ORDER TEST PASSED");

        // TEST 3: FILL ALL MEMORY LOCATIONS
            reset_fifo();

            for (i = 0; i < DEPTH; i = i + 1)
                begin
                    write_fifo(i);
                    check_count(i + 1);

                    if ((i + 1) == ALMOST_FULL_THRESHOLD)
                        begin
                            if (almost_full !== 1'b1)
                                begin
                                    $error("ALMOST FULL ERROR: almost_full should be 1");
                                end
                        end
                end

            check_count(DEPTH);

            if (full !== 1'b1)
                begin
                    $error("FULL ERROR: full should be 1");
                end
            if (almost_full !== 1'b1)
                begin
                    $error("FULL ERROR: almost_full should be 1");
                end
            if (empty !== 1'b0)
                begin
                    $error("FULL ERROR: empty should be 0");
                end

            $display("ALL MEMORY LOCATIONS WRITTEN");

        // TEST 4: OVERFLOW
            write_fifo(16'hDEAD);
            check_count(DEPTH);

            if (full !== 1'b1)
                begin
                    $error("OVERFLOW ERROR: FIFO should remain full");
                end

            $display("OVERFLOW TEST PASSED");

        // TEST 5: READ ALL MEMORY LOCATIONS
            for (i = 0; i < DEPTH; i = i + 1)
                begin
                    read_fifo(i);
                end

            check_count(0);

            if (empty !== 1'b1)
                begin
                    $error("EMPTY ERROR: FIFO should be empty");
                end
            if (full !== 1'b0)
                begin
                    $error("EMPTY ERROR: full should be 0");
                end
            if (almost_empty !== 1'b1)
                begin
                    $error("EMPTY ERROR: almost_empty should be 1");
                end

            $display("FULL FIFO READBACK TEST PASSED");

        // TEST 6: UNDERFLOW
            @(negedge clk);
            read_enable = 1'b1;
            write_enable = 1'b0;
            @(posedge clk);
            @(negedge clk);
            read_enable = 1'b0;
            check_count(0);

            if (empty !== 1'b1)
                begin
                    $error("UNDERFLOW ERROR: FIFO should remain empty");
                end
            if (valid !== 1'b0)
                begin
                    $error("UNDERFLOW ERROR: valid should remain 0");
                end

            $display("UNDERFLOW TEST PASSED");

        // TEST 7: NORMAL SIMULTANEOUS READ / WRITE
            reset_fifo();
            write_fifo(16'hAAAA);
            write_fifo(16'hBBBB);
            check_count(2);
            @(negedge clk);
            data_in = 16'hCCCC;
            write_enable = 1'b1;
            read_enable = 1'b1;
            @(posedge clk);
            @(negedge clk);
            write_enable = 1'b0;
            read_enable = 1'b0;
            check_count(2);

            if (valid !== 1'b1)
                begin
                    $error("SIMULTANEOUS ERROR: valid should be 1");
                end

            if (data_out !== 16'hAAAA)
                begin
                    $error("SIMULTANEOUS ERROR: expected AAAA, received %h", data_out);
                end

            read_fifo(16'hBBBB);
            read_fifo(16'hCCCC);
            check_count(0);

            $display("NORMAL SIMULTANEOUS READ/WRITE TEST PASSED");

        // TEST 8: SIMULTANEOUS READ / WRITE WHILE EMPTY
            reset_fifo();
            @(negedge clk);
            data_in = 16'h1234;
            write_enable = 1'b1;
            read_enable = 1'b1;
            @(posedge clk);
            @(negedge clk);
            write_enable = 1'b0;
            read_enable = 1'b0;
            check_count(1);

            if (empty !== 1'b0)
                begin
                    $error("EMPTY SIMULTANEOUS ERROR: FIFO should contain one item");
                end
            if (valid !== 1'b0)
                begin
                    $error("EMPTY SIMULTANEOUS ERROR: read should not be valid");
                end

            read_fifo(16'h1234);
            check_count(0);

            $display("EMPTY SIMULTANEOUS READ/WRITE TEST PASSED");

        // TEST 9: SIMULTANEOUS READ / WRITE WHILE FULL
            reset_fifo();

            for (i = 0; i < DEPTH; i = i + 1)
                begin
                    write_fifo(i);
                end

            check_count(DEPTH);

            if (full !== 1'b1)
                begin
                    $error("FULL SIMULTANEOUS SETUP ERROR: FIFO should be full");
                end

            @(negedge clk);
            data_in = 16'hDEAD;
            write_enable = 1'b1;
            read_enable = 1'b1;
            @(posedge clk);
            @(negedge clk);
            write_enable = 1'b0;
            read_enable = 1'b0;
            check_count(DEPTH - 1);

            if (full !== 1'b0)
                begin
                    $error("FULL SIMULTANEOUS ERROR: full should clear after read");
                end
            if (valid !== 1'b1)
                begin
                    $error("FULL SIMULTANEOUS ERROR: read should be valid");
                end
            if (data_out !== 16'h0000)
                begin
                    $error("FULL SIMULTANEOUS ERROR: expected 0000, received %h", data_out);
                end

            $display("FULL SIMULTANEOUS READ/WRITE TEST PASSED");
            $display("ALL FIFO TESTS COMPLETED");
            
        // TEST 10: GENERATED PYTHON DATA
            $display("PYTHONG GENERATED DATA TEST");
            
            reset_fifo();
            
            for (int j = 0; j < DEPTH; j++)
                begin
                    write_fifo(test_data[j]);
                end
            
            check_count(DEPTH);
            
            for (int j = 0; j < DEPTH; j++)
                begin
                    read_fifo(test_data[j]);
                end
            
            check_count(0);
            
            $display("PYTHON GENERATED DATA TEST COMPLETED");
            $display("ALL TESTS COMPLETED");

            $finish;
            
        end

endmodule
