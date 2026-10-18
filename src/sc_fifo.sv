`timescale 1ns / 1ps

module sc_fifo #( parameter int WIDTH = 16,                     // 16-bits wide per address
                  parameter int DEPTH = 32,                     // 32 address locations
                  parameter int ALMOST_EMPTY_THRESHOLD = 1,
                  parameter int ALMOST_FULL_THRESHOLD = 31,
                  parameter int READ_LATENCY = 1                // Output is one clock cycle delay
                )
    (
        input logic clk,
        input logic srst,                                       // Synchronous Reset
        input logic [WIDTH - 1:0] data_in,
        input logic write_enable,
        input logic read_enable,
        
        output logic [$clog2(DEPTH + 1) - 1:0] data_count,
        output logic [WIDTH - 1:0] data_out,
        output logic valid,
        output logic almost_full,
        output logic almost_empty,
        output logic full,
        output logic empty
    );
    
    localparam ADDR_WIDTH = $clog2(DEPTH);                      // Which memory location to access
    
    (* ram_style = "block" *)                                   // Specifically map to Block RAM
    
    logic [WIDTH - 1:0] mem [0:DEPTH - 1];                      // Memory Array columns x rows
    logic [ADDR_WIDTH - 1:0] write_pointer;                     // Write to memory location
    logic [ADDR_WIDTH - 1:0] read_pointer;                      // Read to memory location
    logic write_accept;                                         // Write if not full
    logic read_accept;                                          // Read if not empty
    logic [WIDTH - 1:0] data_pipeline [0:READ_LATENCY - 1];     // What data was read
    logic valid_pipeline [0:READ_LATENCY - 1];                  // When that read is ready
    
    integer i;
    
    // READ/WRITE ENABLE LOGIC
    always_comb
        begin
            write_accept = write_enable && !full;               // Allow to write in data when FIFO is not full
            read_accept = read_enable && !empty;                // Allow to read out data when FIFO is not empty
        end
        
    // WRITE OPERATION
    always_ff @(posedge clk)
        begin
            if (srst)
                begin
                    write_pointer <= 1'b0;
                end
                
            else if (write_accept)
                begin
                    mem[write_pointer] <= data_in;
                    write_pointer <= write_pointer + 1'b1;
                end
        end

    // READ OPERATION AND READ LATENCY
    always_ff @(posedge clk)
        begin
            if (srst)
                begin
                    read_pointer <= 1'b0;
                    for (i = 0; i < READ_LATENCY; i = i + 1)
                        begin
                            data_pipeline[i] <= 1'b0;
                            valid_pipeline[i] <= 1'b0;
                        end
                end

            else
                begin
                    if (read_accept)
                        begin
                            data_pipeline[0] <= mem[read_pointer];
                            read_pointer <= read_pointer + 1'b1;
                        end

                    valid_pipeline[0] <= read_accept;
                    
                    for (i = 1; i < READ_LATENCY; i = i + 1)
                        begin
                            data_pipeline[i] <= data_pipeline[i - 1];
                            valid_pipeline[i] <= valid_pipeline[i - 1];
                        end
                    
                end
        end
        
        // FIFO DATA COUNT
        always_ff @(posedge clk)
            begin
                if (srst)
                    begin
                        data_count <= 1'b0;
                    end
                
                else
                    begin
                        case ({write_accept, read_accept})
                            
                            2'b10:
                                data_count <= data_count + 1'b1;
                            
                            2'b01:
                                data_count <= data_count - 1'b1;
                            
                            default:
                                data_count <= data_count;
                        endcase
                    end
            end
        
        // FIFO STATUS FLAGS
        always_comb
            begin
                empty = (data_count == 0);
                full = (data_count == DEPTH);
                almost_empty = (data_count <= ALMOST_EMPTY_THRESHOLD);
                almost_full = (data_count >= ALMOST_FULL_THRESHOLD);
            end
        
        // FIFO OUTPUTS
        always_comb
            begin
                data_out = data_pipeline[READ_LATENCY - 1];
                valid = valid_pipeline[READ_LATENCY - 1];
            end
                                
endmodule
