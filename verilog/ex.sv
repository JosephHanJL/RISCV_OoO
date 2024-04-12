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
    input logic [`XLEN-1:0]   Dmem2proc_data;

    // output packets
    output EX_CDB_PACKET ex_cdb_packet,
    output SQUASH_PACKET squash_packet,
    output FU_MEM_PACKET fu_mem_packet
    // debug
);

    // Squash generation logic
    assign squash_packet.squash_valid = fu_out_packets[1].branch_taken || fu_out_packets[2].branch_taken;
    assign squash_packet.rob_tag = fu_out_packets[1].branch_taken ? fu_out_packets[1].rob_tag :
                                   fu_out_packets[2].branch_taken ? fu_out_packets[2].rob_tag :
                                   '0;

    // Memory logic (priority given to load FU)
    logic ld_mem_ack, st_mem_ack, ld_mem_req, st_mem_req;
    assign ld_mem_ack = ld_mem_req;
    assign st_mem_ack = st_mem_req && !ld_mem_ack;
    assign fu_mem_packet = (ld_mem_ack) ? fu_mem_packet_ld : 
                           (st_mem_ack) ? fu_mem_packet_st :
                           '0;

    

    alu_fu fu_1 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash_packet.squash_valid),
        // ack bit from CDB
        .ack              (cdb_ex_packet.ack[1]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[1]),
        // output packets
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[1])
    );

    alu_fu fu_2 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash_packet.squash_valid),
        // ack bit from CDB
        .ack              (cdb_ex_packet.ack[2]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[2]),
        // output packets
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[2])
    );

    load_fu fu_3 (
        // Inputs
        .clock            (clock),
        .reset            (reset || squash_packet.squash_valid),
        .ack              (cdb_ex_packet.ack[3]),
        .fu_in_packet     (rs_ex_packet.fu_in_packets[3]),
        .mem_ack          (ld_mem_ack),
        // Outputs
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[3]),
        .fu_mem_packet    (fu_mem_packet_ld),
        .mem_req          (ld_mem_req)
    );

    store_fu fu_4 (
        // Inputs
        .clock            (clock),
        .reset            (reset || squash_packet.squash_valid),
        .ack              (cdb_ex_packet.ack[4]),
        .fu_in_packet     (rs_ex_packet.fu_in_packets[4]),
        .mem_ack          (mem_ack),
        // Outputs
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[4]),
        .fu_mem_packet    (fu_mem_packet_st),
        .mem_req          (st_mem_req)
    );

    mult_fu fu_5 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash_packet.squash_valid),
        // ack bit from CDB)
        .ack              (cdb_ex_packet.ack[5]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[5]),
        // output packets
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[5])
    );

    mult_fu fu_6 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash_packet.squash_valid),
        // ack bit from CDB)
        .ack              (cdb_ex_packet.ack[6]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[6]),
        // output packets
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[6])
    );


endmodule