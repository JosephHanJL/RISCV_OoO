/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  vtuber_test.sv                                      //
//                                                                     //
//  Description :  Visual Debugger for project 4                       //
//                 Outputs only IF part                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`include "verilog/sys_defs.svh"

extern void initcurses(int,int,int,int,int,int,int,int,int,int);
extern void flushpipe();
extern void waitforresponse();
extern void initmem();
extern int get_instr_at_pc(int);
extern int not_valid_pc(int);

module testbench;
    // Remove signals and variables related to stages other than IF
    logic [`XLEN-1:0] if_NPC_dbg;
    logic [31:0]      if_inst_dbg;
    logic             if_valid_dbg;
    // used to parameterize which file is loaded into memory
    // "./vis_simv" still just uses program.mem
    // but now "./simv +MEMORY=<my_program>.mem" loads <my_program>.mem instead
    string program_memory_file;

    // Registers and wires used in the testbench
    logic        clock;
    logic        reset;
    logic [31:0] clock_count;
    logic [31:0] instr_count;
    int          wb_fileno;
    logic [63:0] debug_counter; // counter used for when pipeline infinite loops, forces termination

    logic [1:0]       proc2mem_command;
    logic [`XLEN-1:0] proc2mem_addr;
    logic [63:0]      proc2mem_data;
    logic [3:0]       mem2proc_response;
    logic [63:0]      mem2proc_data;
    logic [3:0]       mem2proc_tag;
`ifndef CACHE_MODE
    MEM_SIZE          proc2mem_size;
`endif

    logic [3:0]            pipeline_completed_insts;
    EXCEPTION_CODE         pipeline_error_status;
    logic [4:0]            pipeline_commit_wr_idx;
    logic [`XLEN-1:0]      pipeline_commit_wr_data;
    logic                   pipeline_commit_wr_en;
    logic [`XLEN-1:0]      pipeline_commit_NPC;
    logic [`XLEN-1:0]      if_NPC_dbg;
    logic [31:0]           if_inst_dbg;
    logic                   if_valid_dbg;
    logic [`XLEN-1:0]      ex_mem_NPC_dbg;
    logic [31:0]           ex_mem_inst_dbg;
    logic                   ex_mem_valid_dbg;
    logic [`XLEN-1:0]      mem_wb_NPC_dbg;
    logic [31:0]           mem_wb_inst_dbg;
    logic                   mem_wb_valid_dbg;
    MAP_PACKET [31:0]      m_table_dbg;
    logic [`NUM_FU:0]      dones_dbg;
    logic [`NUM_FU:0]      ack_dbg;
    CDB_PACKET             cdb_packet_dbg;
    CDB_EX_PACKET          cdb_ex_packet_dbg;
    MAP_RS_PACKET          map_rs_packet_dbg;
    MAP_ROB_PACKET         map_rob_packet_dbg;
    EX_CDB_PACKET          ex_cdb_packet_dbg;
    DP_PACKET              dp_packet_dbg;
    logic                  dp_packet_req_dbg;
    RS_DP_PACKET           avail_vec_dbg;
    RS_EX_PACKET           rs_ex_packet_dbg;
    ROB_RS_PACKET          rob_rs_packet_dbg;
    ROB_MAP_PACKET         rob_map_packet_dbg;
    logic                  rob_dp_available_dbg;
    ROB_RT_PACKET          rob_rt_packet_dbg;
    logic                  dispatch_valid_dbg;
    logic [`XLEN-1:0]      id_ex_inst_dbg;
    RT_DP_PACKET           rt_dp_packet_dbg;
    IB_DP_PACKET           ib_dp_packet_dbg;
    IF_IB_PACKET           if_ib_packet_dbg;
    logic                  ib_full_dbg;
    logic                  ib_empty_dbg;
    logic                  squash_dbg;

    // Instantiate the Pipeline
    pipeline pipeline_0 (
        // Inputs
        .clock             (clock),
        .reset             (reset),
        .mem2proc_response (mem2proc_response),
        .mem2proc_data     (mem2proc_data),
        .mem2proc_tag      (mem2proc_tag),

        // Outputs
        .proc2mem_command (proc2mem_command),
        .proc2mem_addr    (proc2mem_addr),
        .proc2mem_data    (proc2mem_data),
        .proc2mem_size    (proc2mem_size),

        .pipeline_completed_insts (pipeline_completed_insts),
        .pipeline_error_status    (pipeline_error_status),
        .pipeline_commit_wr_data  (pipeline_commit_wr_data),
        .pipeline_commit_wr_idx   (pipeline_commit_wr_idx),
        .pipeline_commit_wr_en    (pipeline_commit_wr_en),
        .pipeline_commit_NPC      (pipeline_commit_NPC),

        .if_NPC_dbg       (if_NPC_dbg),
        .if_inst_dbg      (if_inst_dbg),
        .if_valid_dbg     (if_valid_dbg),
        .ex_mem_NPC_dbg   (ex_mem_NPC_dbg),
	.ex_mem_inst_dbg  (ex_mem_inst_dbg),
	.ex_mem_valid_dbg (ex_mem_valid_dbg),
	.mem_wb_NPC_dbg   (mem_wb_NPC_dbg),
	.mem_wb_inst_dbg  (mem_wb_inst_dbg),
	.mem_wb_valid_dbg (mem_wb_valid_dbg),
	.m_table_dbg      (m_table_dbg),
	.dones_dbg        (dones_dbg),
	.ack_dbg          (ack_dbg),
	.cdb_packet_dbg	  (cdb_packet_dbg),
	.cdb_ex_packet_dbg(cdb_ex_packet_dbg),
	.map_rs_packet_dbg(map_rs_packet_dbg),
	.map_rob_packet_dbg    (map_rob_packet_dbg),
	.ex_cdb_packet_dbg     (ex_cdb_packet_dbg),
	.dp_packet_dbg         (dp_packet_dbg),
	.dp_packet_req_dbg     (dp_packet_req_dbg),
	.avail_vec_dbg         (avail_vec_dbg),
	.rs_ex_packet_dbg      (rs_ex_packet_dbg),
	.rob_rs_packet_dbg     (rob_rs_packet_dbg),
	.rob_map_packet_dbg    (rob_map_packet_dbg),
	.rob_dp_available_dbg  (rob_dp_available_dbg),
	.rob_rt_packet_dbg     (rob_rt_packet_dbg),
	.dispatch_valid_dbg    (dispatch_valid_dbg),
	.id_ex_inst_dbg        (id_ex_inst_dbg),
	.rt_dp_packet_dbg      (rt_dp_packet_dbg),
	.ib_dp_packet_dbg      (ib_dp_packet_dbg),
	.if_ib_packet_dbg      (if_ib_packet_dbg),
	.ib_full_dbg           (ib_full_dbg),
	.ib_empty_dbg          (ib_empty_dbg),
	.squash_dbg            (squash_dbg)
	
    );

    // Instantiate the Data Memory
    mem memory (
        // Inputs
        .clk              (clock),
        .proc2mem_command (proc2mem_command),
        .proc2mem_addr    (proc2mem_addr),
        .proc2mem_data    (proc2mem_data),
`ifndef CACHE_MODE
        .proc2mem_size    (proc2mem_size),
`endif

        // Outputs
        .mem2proc_response (mem2proc_response),
        .mem2proc_data     (mem2proc_data),
        .mem2proc_tag      (mem2proc_tag)																																																																																																																																																																																														
    );


    // Generate System Clock
    always begin
    #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end


    // Count the number of posedges and number of instructions completed
    // till simulation ends
    always @(posedge clock) begin
        if (reset) begin
            clock_count <= 0;
            instr_count <= 0;
        end else begin
            clock_count <= (clock_count + 1);
            instr_count <= (instr_count + pipeline_completed_insts);
        end
    end


    initial begin
        clock = 0;
        reset = 0;

        // Call to initialize visual debugger
        // *Note that after this, all stdout output goes to visual debugger*
        // each argument is number of registers/signals for the group
       initcurses(
            5,  // IF
            6,  // IB
            22, // DP
            0, // RS
            0,  // ROB
            0, // MT
            0,  // EX
            0,  // MEM
            0,  // RT
            0   // Miscellaneous
        );

        // Pulse the reset signal
        reset = 1'b1;
        @(posedge clock);
        @(posedge clock);

        // set paramterized strings, see comment at start of module
        if ($value$plusargs("MEMORY=%s", program_memory_file)) begin
            $display("Loading memory file: %s", program_memory_file);
        end else begin
            $display("Loading default memory file: program.mem");
            program_memory_file = "program.mem";
        end

        // Read program contents into memory array
        $readmemh(program_memory_file, memory.unified_memory);
        @(posedge clock);
        @(posedge clock);
        #1;
        // This reset is at an odd time to avoid the pos & neg clock edges
        reset = 1'b0;
    end


    always @(negedge clock) begin
        if (!reset) begin
            #2;

            // deal with any halting conditions
            if (pipeline_error_status!=NO_ERROR) begin
                #100
                $display("\nDONE\n");
                waitforresponse();
                flushpipe();
                $finish;
            end
        end
    end 


    // This block is where we dump all of the signals that we care about to
    // the visual debugger.  Notice this happens at *every* clock edge.
    always @(clock) begin
        #2;

        // Dump clock and time onto stdout
        $display("c%h%7.0d",clock,clock_count);
        $display("t%8.0f",$time);
        $display("z%h",reset);

        // Dump register file contents
        $write("a");
        for(int i = 0; i < 32; i=i+1) begin
            $write("%h", pipeline_0.u_stage_dp.regfile.registers[i]);
        end
        $display("");

        // Dump instructions and their validity for each stage
        $write("p");
        $write("%h%h ",
               if_inst_dbg,      if_valid_dbg,
               );
        $display("");

        // Dump interesting register/signal contents onto stdout
        // format is "<reg group prefix><name> <width in hex chars>:<data>"
        // Current register groups (and prefixes) are:
        // f: IF   d: ID   e: EX   m: MEM    w: WB  v: misc. reg
        // g: IF/ID   h: ID/EX  i: EX/MEM  j: MEM/WB

        // IF signals (5) - prefix 'if'
        $display("finst 8:%h",        pipeline_0.if_ib_packet.inst);
	$display("fPC 8:%h",          pipeline_0.if_ib_packet.PC);
	$display("fNPC 8:%h",         pipeline_0.if_ib_packet.NPC);
        $display("fvalid 1:%h",       pipeline_0.if_ib_packet.valid);
	$display("fImem_addr 8:%h",   pipeline_0.proc2Imem_addr);

        // IB signals (4) - prefix 'ib'
        
        $display("ginst 8:%h",        pipeline_0.ib_dp_packet.inst);
        $display("gPC 8:%h",          pipeline_0.ib_dp_packet.PC);
	$display("gNPC 1:%h",         pipeline_0.ib_dp_packet.NPC);
        $display("gvalid 1:%h",       pipeline_0.ib_dp_packet.valid);
	$display("gib_full 1:%h",     pipeline_0.ib_full);
        $display("gib_empty 1:%h",    pipeline_0.ib_empty);

        // DP signals (13) - prefix 'dp'
        $display("dfu_sel 1:%h",     		pipeline_0.dp_packet.fu_sel);
        $display("dinst 8:%h",       		pipeline_0.dp_packet.inst);
        $display("dPC 8:%h",         		pipeline_0.dp_packet.PC);
        $display("dNPC 8:%h",         		pipeline_0.dp_packet.NPC);
        $display("drs1_value 8:%h",  		pipeline_0.dp_packet.rs1_value);
        $display("drs2_value 8:%h",  		pipeline_0.dp_packet.rs2_value);
        $display("drs1_idx 2:%h",    		pipeline_0.dp_packet.rs1_idx);
        $display("drs1_idx 2:%h",    		pipeline_0.dp_packet.rs2_idx);
        $display("drs1_valid 1:%h",  		pipeline_0.dp_packet.rs1_valid); 
        $display("drs2_valid 1:%h",  		pipeline_0.dp_packet.rs2_valid);
        $display("dopa_select 1:%h", 		pipeline_0.dp_packet.opa_select);
        $display("dopb_select 1:%h", 		pipeline_0.dp_packet.opb_select);
        $display("ddest_reg_idx 2:%h",       	pipeline_0.dp_packet.dest_reg_idx);
	$display("dhas_dest 1:%h",     	pipeline_0.dp_packet.has_dest);
        $display("dalu_func 2:%h",       	pipeline_0.dp_packet.alu_func);
        $display("drd_mem 1:%h",         	pipeline_0.dp_packet.rd_mem);
        $display("dwr_mem 1:%h",         	pipeline_0.dp_packet.wr_mem);
        $display("dcond_branch 1:%h",  	pipeline_0.dp_packet.cond_branch);
        $display("duncond_branch 1:%h",  	pipeline_0.dp_packet.uncond_branch);
        $display("dhalt 1:%h",    		pipeline_0.dp_packet.halt);
        $display("dillegal 1:%h",    		pipeline_0.dp_packet.illegal);
        $display("dcsr_op 1:%h",  		pipeline_0.dp_packet.csr_op);

        // RS signals (17) - prefix 'h'
        /* $display("henable 1:%h",      pipeline_0.id_ex_enable);
        $display("hNPC 16:%h",        pipeline_0.id_ex_reg.NPC);
        $display("hinst 8:%h",        pipeline_0.id_ex_reg.inst);
        $display("hrs1 8:%h",         pipeline_0.id_ex_reg.rs1_value);
        $display("hrs2 8:%h",         pipeline_0.id_ex_reg.rs2_value);
        $display("hdest_reg 2:%h",    pipeline_0.id_ex_reg.dest_reg_idx);
        $display("hrd_mem 1:%h",      pipeline_0.id_ex_reg.rd_mem);
        $display("hwr_mem 1:%h",      pipeline_0.id_ex_reg.wr_mem);
        $display("hopa_sel 1:%h",     pipeline_0.id_ex_reg.opa_select);
        $display("hopb_sel 1:%h",     pipeline_0.id_ex_reg.opb_select);
        $display("halu_func 2:%h",    pipeline_0.id_ex_reg.alu_func);
        $display("hcond_br 1:%h",     pipeline_0.id_ex_reg.cond_branch);
        $display("huncond_br 1:%h",   pipeline_0.id_ex_reg.uncond_branch);
        $display("hhalt 1:%h",        pipeline_0.id_ex_reg.halt);
        $display("hillegal 1:%h",     pipeline_0.id_ex_reg.illegal);
        $display("hvalid 1:%h",       pipeline_0.id_ex_reg.valid);
        $display("hcsr_op 1:%h",      pipeline_0.id_ex_reg.csr_op);

        // ROB signals (4) - prefix 'e'
        $display("eopa_mux 8:%h",     pipeline_0.stage_ex_0.opa_mux_out);
        $display("eopb_mux 8:%h",     pipeline_0.stage_ex_0.opb_mux_out);
        $display("ealu_result 8:%h",  pipeline_0.ex_packet.alu_result);
        $display("etake_branch 1:%h", pipeline_0.ex_packet.take_branch);

        // MT signals (14) - prefix 'i'
        $display("ienable 1:%h",      pipeline_0.ex_mem_enable);
        $display("iNPC 8:%h",         pipeline_0.ex_mem_reg.NPC);
        $display("iinst 8:%h",        pipeline_0.ex_mem_inst_dbg);
        $display("irs2 8:%h",         pipeline_0.ex_mem_reg.rs2_value);
        $display("ialu_result 8:%h",  pipeline_0.ex_mem_reg.alu_result);
        $display("idest_reg 2:%h",    pipeline_0.ex_mem_reg.dest_reg_idx);
        $display("ird_mem 1:%h",      pipeline_0.ex_mem_reg.rd_mem);
        $display("iwr_mem 1:%h",      pipeline_0.ex_mem_reg.wr_mem);
        $display("itake_branch 1:%h", pipeline_0.ex_mem_reg.take_branch);
        $display("ihalt 1:%h",        pipeline_0.ex_mem_reg.halt);
        $display("iillegal 1:%h",     pipeline_0.ex_mem_reg.illegal);
        $display("ivalid 1:%h",       pipeline_0.ex_mem_reg.valid);
        $display("icsr_op 1:%h",      pipeline_0.ex_mem_reg.csr_op);
        // haven't updated VTUBER to use rd_unsigned yet
        $display("imem_size 1:%h",    {pipeline_0.ex_mem_reg.rd_unsigned, pipeline_0.ex_mem_reg.mem_size});

        // EX signals (5) - prefix 'm'
        $display("mmem_data 16:%h",   pipeline_0.mem2proc_data);
        $display("mmem_result 8:%h",  pipeline_0.mem_wb_reg.result);
        $display("m2Dmem_data 16:%h", pipeline_0.proc2mem_data);
        $display("m2Dmem_addr 8:%h",  pipeline_0.proc2Dmem_addr);
        $display("m2Dmem_cmd 1:%h",   pipeline_0.proc2Dmem_command);

        // MEM signals (9) - prefix 'j'
        $display("jenable 1:%h",      pipeline_0.mem_wb_enable);
        $display("jNPC 8:%h",         pipeline_0.mem_wb_NPC_dbg);
        $display("jinst 8:%h",        pipeline_0.mem_wb_inst_dbg);
        $display("jresult 8:%h",      pipeline_0.mem_wb_reg.result);
        $display("jdest_reg 2:%h",    pipeline_0.mem_wb_reg.dest_reg_idx);
        $display("jtake_branch 1:%h", pipeline_0.mem_wb_reg.take_branch);
        $display("jhalt 1:%h",        pipeline_0.mem_wb_reg.halt);
        $display("jillegal 1:%h",     pipeline_0.mem_wb_reg.illegal);
        $display("jvalid 1:%h",       pipeline_0.mem_wb_reg.valid);

        // RT signals (3) - prefix 'w'
        $display("wwr_data 8:%h",     pipeline_0.wb_regfile_data);
        $display("wwr_idx 2:%h",      pipeline_0.wb_regfile_idx);
        $display("wwr_en 1:%h",       pipeline_0.wb_regfile_en); 

        // Misc signals(2) - prefix 'v'
        $display("vcompleted 1:%h",   pipeline_completed_insts);
        $display("vpipe_err 1:%h",    pipeline_error_status); */

        // must come last
        $display("break");

        // This is a blocking call to allow the debugger to control when we
        // advance the simulation
        waitforresponse();
    end

endmodule // module testbench
