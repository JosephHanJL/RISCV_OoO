`include "sys_defs.svh"

module testbench;

    logic [4:0] dones, ack;

    // dut stands for Device Under Test, the module we're testing
    priority_selector u_priority_selector (
    .dones    (dones),
    .ack      (ack)
    );

    task exit_on_error;
        begin
            $display("Time:%4.0f Dones:%b ACK:%b", $time, dones, ack);
            $finish;
        end
    endtask

    initial begin
        $monitor("Time:%4.0f Dones:%b ACK:%b", $time, dones, ack);

        dones = 5'b00000;
        #5 assert (ack == 5'b00000) else $finish;

        dones = 5'b10000;
        #5 assert (ack == 5'b10000) else $finish;

        dones = 5'b00010;
        #5 assert (ack == 5'b00010) else $finish;

        dones = 5'b10100;
        #5 assert (ack == 5'b10000) else $finish;

        dones = 5'b11111;
        #5 assert (ack == 5'b10000) else $finish;

        dones = 5'b01111;
        #5 assert (ack == 5'b01000) else $finish;

        $display("@@@ Passed");
        $finish;
    end

endmodule
