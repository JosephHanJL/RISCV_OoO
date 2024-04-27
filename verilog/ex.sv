// Version 1.0

`include "verilog/sys_defs.svh"

`define TESTBENCH

// Fully combinational module to link RS to each FU

module ex(
    // global signals
    input logic clock,
    input logic reset,

    // input packets
    input CDB_PACKET cdb_packet,
    input CDB_EX_PACKET cdb_ex_packet,
    input RS_EX_PACKET rs_ex_packet,
    input logic [`XLEN-1:0]   Dmem2proc_data,
    input ROB_EX_PACKET rob_ex_packet,

    // output packets
    output EX_CDB_PACKET ex_cdb_packet,
    output FU_MEM_PACKET fu_mem_packet,
    output FU_DONE_PACKET fu_done_packet,
    output BRANCH_PACKET branch_packet
);

    // Memory logic (priority given to load FU)
    FU_MEM_PACKET fu_mem_packet_ld, fu_mem_packet_st;
    logic ld_mem_ack, st_mem_ack, ld_mem_req, st_mem_req;
    FU_OUT_PACKET [`NUM_FU:0] fu_out_packet_comb;
    logic [`NUM_FU:0] result_stored;
    // For pulsing fu_done_packet high for every instruction completed
    ROB_TAG [`NUM_FU:0] last_rob_tag;
    assign ld_mem_ack = ld_mem_req;
    assign st_mem_ack = st_mem_req && !ld_mem_ack;
    assign fu_mem_packet = (ld_mem_ack) ? fu_mem_packet_ld : 
                           (st_mem_ack) ? fu_mem_packet_st :
                           '0;

    // assign fu_done_packet = {ex_cdb_packet.fu_out_packets[6].done, ex_cdb_packet.fu_out_packets[5].done, ex_cdb_packet.fu_out_packets[4].done,ex_cdb_packet.fu_out_packets[3].done,
    //                         ex_cdb_packet.fu_out_packets[2].done,ex_cdb_packet.fu_out_packets[1].done,ex_cdb_packet.fu_out_packets[0].done};


    // Branch generation logic
    always_comb begin
        branch_packet = '0;
        if (ex_cdb_packet.fu_out_packets[1].take_branch) begin
            branch_packet.rob_tag = ex_cdb_packet.fu_out_packets[1].rob_tag;
            branch_packet.branch_valid = 1;
            branch_packet.PC = ex_cdb_packet.fu_out_packets[1].branch_loc;
        end else if (ex_cdb_packet.fu_out_packets[2].take_branch) begin
            branch_packet.rob_tag = ex_cdb_packet.fu_out_packets[2].rob_tag;
            branch_packet.branch_valid = 1;
            branch_packet.PC = ex_cdb_packet.fu_out_packets[2].branch_loc;
        end
    end    

    
    always_comb begin
        for (int i = 0; i <= `NUM_FU; i++) begin
            result_stored[i] = ((cdb_ex_packet.ack[i] || ~ex_cdb_packet.fu_out_packets[i].done) && rs_ex_packet.fu_in_packets[i].issue_valid);
        end
    end

    always_comb begin
        for (int i = 0; i <= `NUM_FU; i++) begin
            fu_done_packet[i] = (cdb_ex_packet.ack[i]);//(fu_out_packet_comb[i].rob_tag != ex_cdb_packet.fu_out_packets[i].rob_tag) && (fu_out_packet_comb[i].done);
        end
        fu_done_packet[1] = result_stored[1];
        fu_done_packet[2] = result_stored[2];
    end

    alu_fu fu_1 (
        // global signals
        .clock            (clock),
        .reset            (reset),
        // ack bit from CDB
        .ack              (cdb_ex_packet.ack[1]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[1]),
        // output packets
        .fu_out_packet_comb (fu_out_packet_comb[1]),
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[1])
    );

    alu_fu fu_2 (
        // global signals
        .clock            (clock),
        .reset            (reset),
        // ack bit from CDB
        .ack              (cdb_ex_packet.ack[2]),      
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[2]),
        // output packets
        .fu_out_packet_comb (fu_out_packet_comb[2]),
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[2])
    );

    load_fu fu_3 (
        // Inputs
        .clock            (clock),
        .reset            (reset),
        .ack              (cdb_ex_packet.ack[3]),
        .fu_in_packet     (rs_ex_packet.fu_in_packets[3]),
        .mem_ack          (ld_mem_ack),
        // Outputs
        .fu_out_packet_comb (fu_out_packet_comb[3]),
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[3]),
        .fu_mem_packet    (fu_mem_packet_ld),
        .mem_req          (ld_mem_req),
        .Dmem2proc_data   (Dmem2proc_data)
    );

    store_fu fu_4 (
        // Inputs
        .clock            (clock),
        .reset            (reset),
        .ack              (cdb_ex_packet.ack[4]),
        .fu_in_packet     (rs_ex_packet.fu_in_packets[4]),
        .mem_ack          (st_mem_ack),
        // Outputs
        .fu_out_packet_comb (fu_out_packet_comb[4]),
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[4]),
        .fu_mem_packet    (fu_mem_packet_st),
        .mem_req          (st_mem_req)
    );

    mult_fu fu_5 (
        // global signals
        .clock            (clock),
        .reset            (reset),
        // ack bit from CDB)
        .ack              (cdb_ex_packet.ack[5]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[5]),
        // output packets
        .fu_out_packet_comb (fu_out_packet_comb[5]),
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[5])
    );

    mult_fu fu_6 (
        // global signals
        .clock            (clock),
        .reset            (reset),
        // ack bit from CDB)
        .ack              (cdb_ex_packet.ack[6]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[6]),
        // output packets
        .fu_out_packet_comb (fu_out_packet_comb[6]),
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[6])
    );


endmodule
