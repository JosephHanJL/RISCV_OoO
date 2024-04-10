module if_stage (
    input                       clock,
    input                       reset, 
    input                       stall_dp,
    input                       squash_valid,
    input [`XLEN-1:0]           squashed_PC,
    input [1:0][`XLEN-1:0]      bp_pc, bp_npc,
    input                       bp_taken,
    input [1:0][63:0]           mem2proc_data, // change to Imem2proc_data when cache mode

    output IF_DP_PACKET [1:0]   if_dp_packet, // to both bp and dp
    output [1:0][`XLEN-1:0]     proc2Imem_addr // change to if_icache_packet when cache mode
);

    logic [`XLEN-1:0] PC_reg  [1:0];
    logic [`XLEN-1:0] NPC_reg [1:0];
    logic PC_valid;

    assign PC_valid = ~stall_dp; // add icache valid when in icache mode 
    assign NPC_reg[0] = squash_valid? squashed_PC : bp_pc[0];
    assign NPC_reg[1] = squash_valid? squashed_PC + 4 : bp_pc[1];

    always_comb begin
        for (int i = 0; i < 2; i++) begin
            if_dp_packet[i].inst = (stall_dp) ? `NOP : PC_reg[i][2] ? mem2proc_data[i][63:32] : mem2proc_data[i][31:0];
            if_dp_packet[i].valid = PC_valid; // add icache insn valid when in cache mode
            if_dp_packet[i].PC = PC_reg[i];
            if_dp_packet[i].NPC = squash_valid? squashed_PC+2*i : bp_npc[i];
        end
    end

    always_ff @(posedge clock) begin   
        if (reset) 
            for (int i = 0; i < 2; i++) begin
                PC_reg[i] <= i*4;
            end
        else if (squash_valid | PC_valid) begin
            PC_reg <= NPC_reg;
        end
    end

endmodule







