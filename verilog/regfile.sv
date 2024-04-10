/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename :  regfile.sv                                           //
//                                                                     //
//  Description :  This module creates the Regfile used by the ID and  //
//                 WB Stages of the Pipeline. It is now 2-way.         //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`include "verilog/sys_defs.svh"

module regfile(
    input                       clock,
    input [1:0][4:0]            read_idx_1, read_idx_2, write_idx,
    input [1:0]                 write_en,
    input [1:0][`XLEN-1:0]      write_data,

    output logic [1:0][`XLEN-1:0]    read_out_1, read_out_2
);
    
    logic [31:1] [`XLEN-1:0] registers;
    
    // Read port 1
    always_comb begin
        for (int i = 0; i < 2; i++) begin
            if (read_idx_1[i] == `ZERO_REG) begin
                read_out_1[i] = 0;
            end else if (write_en[1] && (write_idx[1] == read_idx_1[i])) begin
                read_out_1[i] = write_data[1]; // internal forwarding
            end else if (write_en[0] && (write_idx[0] == read_idx_1[i])) begin
                read_out_1[i] = write_data[0]; // internal forwarding
            end else begin
                read_out_1[i] = registers[read_idx_1[i]];
            end
        end
    end

    // Read port 2
    always_comb begin
        for (int i = 0; i < 2; i++) begin
            if (read_idx_2[i] == `ZERO_REG) begin
                read_out_2[i] = 0;
            end else if (write_en[1] && (write_idx[1] == read_idx_2[i])) begin
                read_out_2[i] = write_data[1]; // internal forwarding
            end else if (write_en[0] && (write_idx[0] == read_idx_2[i])) begin
                read_out_2[i] = write_data[0]; // internal forwarding
            end else begin
                read_out_2[i] = registers[read_idx_1[i]];
            end
        end
    end

    // Write ports
    always_ff @(posedge clock) begin
        if (write_en[1]) begin
            registers[write_idx[1]] <= write_data[1];
        end
        if (write_en[0]) begin
            if (!(write_idx[0] == write_idx[1] && write_en[1])) begin
                registers[write_idx[0]] <= write_data[0];
            end
            else if (write_idx[0] == write_idx[1]) begin
                registers[`ZERO_REG] <= write_data[0];
            end
        end
    end

endmodule // regfile

