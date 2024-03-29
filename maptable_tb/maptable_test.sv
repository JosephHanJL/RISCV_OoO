`timescale 1ns / 1ps

`include "sys_defs.svh"
`include "ISA.svh"

module map_table_tb;

    logic clock;
    logic reset;
    CDB_PACKET cdb_packet;
    ID_RS_PACKET id_rs_packet;
    logic dispatch_valid;
    RS_TAG fu_source;

    RS_TAG rs_tag_a;
    RS_TAG rs_tag_b;

    RS_TAG m_table_dbg [31:0];

    localparam integer f0 = 5'b00000,
                       f1 = 5'b00001,
                       f2 = 5'b00010,
                       r1 = 5'b00011,
                       r2 = 5'b00100;

    localparam integer RS1 = 3'b001,
                       RS2 = 3'b010,
                       RS3 = 3'b011,
                       RS4 = 3'b100,
                       RS5 = 3'b101,
		       Default_Tag = 3'b000;

    // Instance
    map_table uut (
        .clock(clock),
        .reset(reset),
        .cdb_packet(cdb_packet),
        .id_rs_packet(id_rs_packet),
        .dispatch_valid(dispatch_valid),
        .fu_source(fu_source),
        .rs_tag_a(rs_tag_a),
        .rs_tag_b(rs_tag_b),
		.m_table_dbg(m_table_dbg)
    );

    // Clock Generation
    always begin
        #5;
        clock = ~clock;
    end

    task exit_on_error;
        begin
            $display("@@@Failed at time %d", $time);
            $finish;
        end
    endtask


    // Test Sequence
    initial begin
	//$monitor("Time: %t, Clock: %b, test_mtable: %h, cdb_packet.tag: %b, id_rs_packet.dest_reg_idx: %b, dispatch_valid: %b, fu_source: %b, rs_tag_a: %b, rs_tag_b: %b", $time, clock, test_mtable, cdb_packet.tag, id_rs_packet.dest_reg_idx, dispatch_valid, fu_source, rs_tag_a, rs_tag_b);

	//Initialize signal
        dispatch_valid = 1'b0;
        fu_source = 3'b0;
        cdb_packet.tag = Default_Tag;
        id_rs_packet.rd_valid = 1'b0;
	id_rs_packet.dest_reg_idx = 5'b0;
	clock = 1'b0;

        // Reset
	reset = 1;
        @(negedge clock); 

	// Check that each element in the test_mtable array is correctly initialized to 0
	for (int i = 0; i < 5; i++) begin
            assert(m_table_dbg[i] === 3'b0) else exit_on_error;
        end
	
	// map_table initialization
	reset = 0;
	dispatch_valid = 1'b1;
	id_rs_packet.rd_valid = 1'b1;
	
	for (int i = 0; i < 5; i++) begin
            	fu_source = i;
		id_rs_packet.dest_reg_idx = i;
		@(negedge clock);
        end

	// Check map_table initialization
	dispatch_valid = 1'b0;
	id_rs_packet.rd_valid = 1'b0;
	for (int i = 0; i < 5; i++) begin
            	assert(m_table_dbg[i] === i) else exit_on_error;
        end

	// Ensure that map_table removes the value of the tag after detecting its presence in the CDB 
	cdb_packet.tag = RS1;
	@(negedge clock);
	for (int i = 0; i < 5; i++) begin
            	assert(m_table_dbg[i] !== cdb_packet.tag) else exit_on_error;
        end

	// Test Case for Tomasulo slides
	// Tomasulo Map Table:
	// Reg   T[index]
	// f0    5'b00000
	// f1    5'b00001
	// f2    5'b00010
	// r1    5'b00011
	// xx    5'b00100
        /*
	localparam integer f0 = 5'b00000,
                    	   f1 = 5'b00001,
                           f2 = 5'b00010,
                           r1 = 5'b00011,
                           r2 = 5'b00100;

	localparam integer RS1 = 3'b001,
                    	   RS2 = 3'b010,
                           RS3 = 3'b011,
                           RS4 = 3'b100,
                           RS5 = 3'b101,
			   Default = 3'b000;
	*/

	//Initialize signal
        dispatch_valid = 1'b0;
        fu_source = 3'b0;
        cdb_packet.tag = Default_Tag;
        id_rs_packet.rd_valid = 1'b0;
	id_rs_packet.dest_reg_idx = 5'b0;
	clock = 1'b0;

	// Reset
	reset = 1;
        @(negedge clock); 

	// Check that each element in the test_mtable array is correctly initialized to 0
	for (int i = 0; i < 5; i++) begin
            assert(m_table_dbg[i] === 3'b0) else exit_on_error;
        end
	reset = 0;
	@(negedge clock);
	
	// Tomasulo: Cycle 1
	dispatch_valid = 1'b1;
	id_rs_packet.rd_valid = 1'b1;
	id_rs_packet.dest_reg_idx = f1;
	fu_source = RS2;
	cdb_packet.tag = Default_Tag;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === RS2) else exit_on_error;
	assert(m_table_dbg[f2] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[r1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;
	
	// Tomasulo: Cycle 2
	dispatch_valid = 1'b1;
	id_rs_packet.rd_valid = 1'b1;
	id_rs_packet.dest_reg_idx = f2;
	fu_source = RS4;
	cdb_packet.tag = Default_Tag;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === RS2) else exit_on_error;
	assert(m_table_dbg[f2] === RS4) else exit_on_error;
	assert(m_table_dbg[r1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;
	
	// Tomasulo: Cycle 3
	dispatch_valid = 1'b0;
	id_rs_packet.rd_valid = 1'b0;
	id_rs_packet.dest_reg_idx = f2;
	fu_source = RS4;
	cdb_packet.tag = Default_Tag;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === RS2) else exit_on_error;
	assert(m_table_dbg[f2] === RS4) else exit_on_error;
	assert(m_table_dbg[r1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;
	
	// Tomasulo: Cycle 4
	dispatch_valid = 1'b1;
	id_rs_packet.rd_valid = 1'b1;
	id_rs_packet.dest_reg_idx = r1;
	fu_source = RS1;
	cdb_packet.tag = RS2;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f2] === RS4) else exit_on_error;
	assert(m_table_dbg[r1] === RS1) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;
	
	// Tomasulo: Cycle 5
	dispatch_valid = 1'b1;
	id_rs_packet.rd_valid = 1'b1;
	id_rs_packet.dest_reg_idx = f1;
	fu_source = RS2;
	cdb_packet.tag = Default_Tag;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === RS2) else exit_on_error;
	assert(m_table_dbg[f2] === RS4) else exit_on_error;
	assert(m_table_dbg[r1] === RS1) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;

	// Tomasulo: Cycle 6
	dispatch_valid = 1'b1;
	id_rs_packet.rd_valid = 1'b1;
	id_rs_packet.dest_reg_idx = f2;
	fu_source = RS5;
	cdb_packet.tag = Default_Tag;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === RS2) else exit_on_error;
	assert(m_table_dbg[f2] === RS5) else exit_on_error;
	assert(m_table_dbg[r1] === RS1) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;

	// Tomasulo: Cycle 7
	dispatch_valid = 1'b0;
	id_rs_packet.rd_valid = 1'b1;
	id_rs_packet.dest_reg_idx = f2;
	fu_source = RS5;
	cdb_packet.tag = RS1;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === RS2) else exit_on_error;
	assert(m_table_dbg[f2] === RS5) else exit_on_error;
	assert(m_table_dbg[r1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;

	// Tomasulo: Cycle 8
	dispatch_valid = 1'b0;
	id_rs_packet.rd_valid = 1'b1;
	id_rs_packet.dest_reg_idx = f2;
	fu_source = RS5;
	cdb_packet.tag = Default_Tag;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === RS2) else exit_on_error;
	assert(m_table_dbg[f2] === RS5) else exit_on_error;
	assert(m_table_dbg[r1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;

	// Tomasulo: Cycle 9
	dispatch_valid = 1'b0;
	id_rs_packet.rd_valid = 1'b1;
	id_rs_packet.dest_reg_idx = f2;
	fu_source = RS5;
	cdb_packet.tag = RS2;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f2] === RS5) else exit_on_error;
	assert(m_table_dbg[r1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;

	// Tomasulo: Cycle 10
	dispatch_valid = 1'b0;
	id_rs_packet.rd_valid = 1'b1;
	id_rs_packet.dest_reg_idx = f2;
	fu_source = RS5;
	cdb_packet.tag = Default_Tag;
	@(negedge clock);
	// Check
	assert(m_table_dbg[f0] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[f2] === RS5) else exit_on_error;
	assert(m_table_dbg[r1] === Default_Tag) else exit_on_error;
	assert(m_table_dbg[r2] === Default_Tag) else exit_on_error;


        $display("@@@Passed");
        $finish;
    end

endmodule

