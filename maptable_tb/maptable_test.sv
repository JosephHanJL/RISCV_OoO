`timescale 1ns / 1ps

`include "sys_defs.svh"
`include "ISA.svh"

module map_table_tb;

    // Testbench Signals
    logic clock;
    logic reset;
    CDB_PACKET cdb_packet;
    ID_RS_PACKET id_rs_packet;
    logic dispatch_valid;
    RS_TAG fu_source;

    RS_TAG rs_tag_a;
    RS_TAG rs_tag_b;

    // Expected Outputs
    RS_TAG expected_rs_tag_a;
    RS_TAG expected_rs_tag_b;

    map_table uut (
        .clock(clock),
        .reset(reset),
        .cdb_packet(cdb_packet),
        .id_rs_packet(id_rs_packet),
        .dispatch_valid(dispatch_valid),
        .fu_source(fu_source),
        .rs_tag_a(rs_tag_a),
        .rs_tag_b(rs_tag_b)
    );

    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

    initial begin
        expected_rs_tag_a = rs_tag_a;
        reset = 1;
        dispatch_valid = 0;
        fu_source = 0;
        cdb_packet.tag = 0;
        id_rs_packet.rd_valid = 0;
        assert(expected_rs_tag_a == rs_tag_a) else begin
            $error("Test Case 1 Failed:");
            $finish;
        end

        #10; 
        reset = 0;
        dispatch_valid = 1;
        fu_source = 1;
        cdb_packet.tag = 1;
        id_rs_packet.rd_valid = 0;
        assert(rs_tag_a == 0) else begin
            $error("Test Case 2 Failed:");
            $finish;
        end

        #10; 
        reset = 0;
        dispatch_valid = 0;
        fu_source = 1;
        cdb_packet.tag = 0;
        id_rs_packet.rd_valid = 0;
        assert(rs_tag_a == 0) else begin
            $error("Test Case 3 Failed:");
            $finish;
        end
        // Case
        #10;


        #10; // Wait for update
        assert(rs_tag_a == expected_rs_tag_a && rs_tag_b == expected_rs_tag_b) else begin
            $error("Test Case 1 Failed: rs_tag_a or rs_tag_b does not match expected value.");
            $finish;
        end


        $display("All test cases passed.");
        #100;
        $finish;
    end

    initial begin
        $monitor("Time = %t, rs_tag_a = %h, rs_tag_b = %h", $time, rs_tag_a, rs_tag_b);
    end

endmodule

