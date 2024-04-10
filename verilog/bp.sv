module bp(
    input clock,
    input reset,
    input [1:0][31:0] ex_bp_packet_in,  // Example input, adjust as needed
    input [1:0][31:0] if_pc_in,         // PC from IF stage
    input [1:0][31:0] inst,             // Instruction
    input [1:0] valid,                  // Valid signals for the instructions

    // Outputs
    output reg [1:0][31:0] bp_pc_out,   // Predicted PC (same as input PC for not taken)
    output reg [1:0][31:0] bp_npc_out,  // Next predicted PC (input PC + 4 for not taken)
    output reg [1:0] bp_taken           // Predicted branch taken signals (always 0 for not taken)
);

// Assuming 32-bit instructions and PC. Adjust sizes as necessary.

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // On reset, clear outputs
            bp_pc_out <= 0;
            bp_npc_out <= 0;
            bp_taken <= 0;
        end else begin
            // Always predict branches as not taken
            bp_pc_out <= if_pc_in;                     // Current PC
            bp_npc_out[0] <= if_pc_in[0] + 4;          // Next PC for sequential execution
            bp_npc_out[1] <= if_pc_in[1] + 4;          // Assuming PC increments by 4 for the next instruction
            bp_taken <= 2'b00;                         // Branch not taken for both instructions
        end
    end

endmodule