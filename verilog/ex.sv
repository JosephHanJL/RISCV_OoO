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

    // output packets
    output EX_CDB_PACKET ex_cdb_packet
    // debug

);


    

    mult_fu u_mult_fu (
        // global signals
        .clock            (clock),
        .reset            (reset),
        .ack              (ack),
        .fu_in_packet     (fu_in_packet),
        .fu_out_packet    (fu_out_packet)
    );

    mult_fu u_mult_fu (
        // global signals
        .clock            (clock),
        .reset            (reset),
        .ack              (ack),
        .fu_in_packet     (fu_in_packet),
        .fu_out_packet    (fu_out_packet)
    );


endmodule