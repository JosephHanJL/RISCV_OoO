module if_stage (
    // Inputs
    input                       clock,
    input                       reset, 
    input                       ib_full,
    input                       if_stall,
    input [`XLEN-1:0]           bp_pc,
    input                       bp_taken,
    input [63:0]                mem2proc_data, // change to Imem2proc_data when cache mode
    // Outputs
    output IF_IB_PACKET         if_ib_packet, // to both bp and dp
    output logic [`XLEN-1:0]    proc2Imem_addr // change to if_icache_packet when cache mode
);

    logic [`XLEN-1:0] NPC, PC_reg;
    logic PC_valid;

    logic [7:0][`XLEN-1:0] PC_reg_hist;
    logic [7:0] PC_valid_hist;

    assign PC_valid = !if_stall && !ib_full && !bp_taken && !reset; // add icache valid when in icache mode 
    assign proc2Imem_addr = {PC_reg[`XLEN-1:3], 3'b0};
    assign NPC = PC_reg + 4;

    always_ff @(posedge clock) begin   
        if (reset) begin
            PC_reg <= 0;
        end else if (bp_taken) begin
            PC_reg <= bp_pc;
        end else if (PC_valid) begin
            PC_reg <= NPC;
        end
    end

    // history for memory latency
    always_ff @(posedge clock) begin
        if (reset) begin
            PC_reg_hist <= '0;
            PC_valid_hist <= '0;
        end else begin
            if (bp_taken) begin
                PC_reg_hist <= '0;
                PC_valid_hist <= '0;
            end else begin
                for (int i = 7; i > 0; i--) begin
                    PC_reg_hist[i] <= PC_reg_hist[i-1];
                    PC_valid_hist[i] <= PC_valid_hist[i-1];
                end
                PC_valid_hist[0] <= PC_valid;
                PC_reg_hist[0] <= PC_reg;
            end
        end
    end

    always_comb begin
        if_ib_packet = '0;
        if (`MEM_LATENCY_IN_CYCLES == 0) begin
            if_ib_packet.inst = (!PC_valid) ? `NOP : PC_reg[2] ? mem2proc_data[63:32] : mem2proc_data[31:0];
            if_ib_packet.valid = PC_valid; // add icache insn valid when in cache mode
            if_ib_packet.PC = PC_reg;
            if_ib_packet.NPC = NPC;
        end else begin
            if_ib_packet.inst = (!PC_valid_hist[`MEM_LATENCY_IN_CYCLES-1]) ? `NOP : PC_reg_hist[`MEM_LATENCY_IN_CYCLES-1][2] ? mem2proc_data[63:32] : mem2proc_data[31:0];
            if_ib_packet.valid = PC_valid_hist[`MEM_LATENCY_IN_CYCLES-1]; // add icache insn valid when in cache mode
            if_ib_packet.PC = PC_reg_hist[`MEM_LATENCY_IN_CYCLES-1];
            if_ib_packet.NPC = PC_reg_hist[`MEM_LATENCY_IN_CYCLES-1] + 4;
        end
    end 

    // always_ff @(posedge clock) begin
    //     if (reset) begin
    //         if_ib_packet <= '0;
    //     end else begin
    //         if_ib_packet.inst <= (!PC_valid) ? `NOP : PC_reg[2] ? mem2proc_data[63:32] : mem2proc_data[31:0];
    //         if_ib_packet.valid <= PC_valid; // add icache insn valid when in cache mode
    //         if_ib_packet.PC <= PC_reg;
    //         if_ib_packet.NPC <= NPC;
    //     end
    // end
endmodule