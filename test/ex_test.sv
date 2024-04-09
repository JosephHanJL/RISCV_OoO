
`include "/verilog/sys_defs.svh"

module testbench;

    logic clock, reset, squash;
    RS_EX_PACKET rs_ex_packet;
    EX_CDB_PACKET ex_cdb_packet;
    CDB_EX_PACKET cdb_ex_packet;
    CDB_PACKET cdb_packet;

    ex u_ex (
        // global signals
        .clock            (clock),
        .reset            (reset),
        .squash           (squash),
        .ack              (ack),
        // input packets
        .cdb_packet       (cdb_packet),
        .cdb_ex_packet    (cdb_ex_packet),
        .rs_ex_packet     (rs_ex_packet),
        // output packets
        .ex_cdb_packet    (ex_cdb_packet)
    );

    logic [`NUM_FU-1:0] dones_dbg, ack_dbg;
    cdb u_cdb (
        // global signals
        .clock            (clock),
        .reset            (reset),
        // input packets
        .ex_cdb_packet    (ex_cdb_packet),
        // output packets
        .cdb_ex_packet    (cdb_ex_packet),
        .cdb_packet       (cdb_packet),
        // debug
        .dones_dbg        (dones_dbg),
        .ack_dbg          (ack_dbg)
    );


    // CLOCK_PERIOD is defined on the commandline by the makefile 30ns
    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

    
    task check_correct;
        if (!correct) begin
            $display("@@@ Incorrect at time %4.0f", $time);
            $display("@@@ done:%b a:%h b:%h result:%h", done, a, b, result);
            $display("@@@ Expected result:%h", cres);
            $finish;
        end
    endtask


    // Some students have had problems just using "@(posedge done)" because their
    // "done" signals glitch (even though they are the output of a register). This
    // prevents that by making sure "done" is high at the clock edge.
    task wait_until_done;
        forever begin : wait_loop
            @(negedge clock);
            if (done == 1) begin
                if (cdb_packet.rob_tag == tag_in) begin
                    disable wait_until_done;
                end
            end
        end
    endtask


    FU_IN_PACKET alu_1_in, alu_2_in;
    
    task test_alu;
        // set up packets
        
        rs_ex_packet = '0;
        rs_ex_packet.fu_in_packets[1] = alu_1_in;
        rs_ex_packet.fu_in_packets[2] = alu_2_in;
    endtask


    initial begin
        // NOTE: monitor starts using 5-digit decimal values for printing
        $monitor("Time:%4.0f done:%b a:%5d b:%5d result:%5d correct:%5d cdb_tag:%3d cdb_v:%5d dones:%5b ack:%5b",
                 $time, done, a, b, result, cres, cdb_packet.rob_tag, cdb_packet.v, dones, cdb_ex_packet.ack);

        $display("\nBeginning edge-case testing:");

        reset = 1;
        clock = 0;
    
        a = 2;
        b = 3;
        tag_in = 2;

        start = 0;
        @(negedge clock);

        start = 0;
        reset = 0;
        @(negedge clock);

        start = 1;
        a = 2;
        b = 3;
        wait_until_done();
        check_correct();

        start = 0;
        @(negedge clock);

        start = 1;
        tag_in = 3;
        a = 5;
        b = 50;
        wait_until_done();
        check_correct();
        start = 0;
        @(negedge clock);

        for (i = 0; i <= 30; i = i+1) begin
            start = 1;
            a = $random; // multiply random 32-bit numbers
            b = $random;
            tag_in = $random;
            @(negedge clock)
            start = 0;
            wait_until_done();
            check_correct();
        end

        $display("@@@ Passed\n");
        $finish;
    end

endmodule