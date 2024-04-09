`include "verilog/sys_defs.svh"

module mult_fu(
    // global signals
    input logic clock,
    input logic reset,

    // input packets
    input FU_PACKET fu_packet,

    // output packets
    

    // debug
    output MAP_PACKET m_table_dbg [31:0]
);

endmodule