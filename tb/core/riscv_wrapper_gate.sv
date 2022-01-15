// Copyright 2018 Robert Balas <balasr@student.ethz.ch>
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Wrapper for a RI5CY testbench, containing RI5CY, Memory and stdout peripheral
// Contributor: Robert Balas <balasr@student.ethz.ch>

import constants::*;

module riscv_wrapper
    #(parameter INSTR_RDATA_WIDTH = 128,
      parameter RAM_ADDR_WIDTH = 20,
      parameter BOOT_ADDR = 'h80,
      parameter PULP_SECURE = 1)
    (input logic         clk_i,
     input logic         rst_ni,

     input logic         fetch_enable_i,
     input logic         test_en,
     output logic        tests_passed_o,
     output logic        tests_failed_o,
     output logic [31:0] exit_value_o,
     output logic        exit_valid_o,
     output logic        bist_go,
     output logic        bist_end);

    // signals connecting core to memory
    logic                         instr_req;
    logic                         instr_gnt;
    logic                         instr_rvalid;
    logic [31:0]                  instr_addr;
    logic [INSTR_RDATA_WIDTH-1:0] instr_rdata;

    logic                         data_req;
    logic                         data_gnt;
    logic                         data_rvalid;
    logic [31:0]                  data_addr;
    logic                         data_we;
    logic [3:0]                   data_be;
    logic [31:0]                  data_rdata;
    logic [31:0]                  data_wdata;

    // signals to debug unit
    logic                         debug_req_i;

    // irq signals (not used)
    logic                         irq;
    logic [0:4]                   irq_id_in;
    logic                         irq_ack;
    logic [0:4]                   irq_id_out;
    logic                         irq_sec;

    logic [95:0]                  apu_master_operands;
    logic                         core_busy;
    logic                         sec_lvl;
    //LBIST signals
    logic [63:0]                  ph_shft_o;

    logic [n_lfsr-1:0]            lfsr_seed;
    logic [n_lfsr-1:0]            lfsr_out;
    logic                         lfsr_ld;
    logic                         lfsr_en;

    logic                         misr_en;
    logic [n_misr-1:0]            misr_in;
    logic [n_misr-1:0]            misr_signature;
    logic [230:0]                 sp_cmp_in;
    
    logic [3:0]                   seed_addr_o;
    
    logic                         SCAN_EN;
    logic                         DUT_RESET;
    logic                         LFSR_MISR_RESET;

    logic                         cpu_ram_rst;

    // MUX signals
    logic [31:0]                  boot_addr_mux;
    logic [1:2]                   ext_perf_counters_mux;
    logic                         fregfile_disable_mux;
    logic                         instr_gnt_mux;
    logic                         instr_rvalid_mux;
    logic                         data_gnt_mux;
    logic                         data_rvalid_mux;
    logic                         apu_master_gnt_mux;
    logic                         apu_master_valid_mux;
    logic                         irq_mux;
    logic                         irq_sec_mux;
    logic                         debug_req_mux;
    logic                         fetch_enable_mux;
    logic [3:0]                   core_id_mux;
    logic [5:0]                   cluster_id_mux;
    logic [127:0]                 instr_rdata_mux;
    logic [31:0]                  data_rdata_mux;
    logic [31:0]                  apu_master_result_mux;
    logic [4:0]                   apu_master_flags_mux;
    logic [4:0]                   irq_id_mux;

    const logic [63:0] golden_sign = 64'hEFCF01E7782667FA;

    // interrupts (only timer for now)
    assign irq_sec     = 1'b0;

    assign debug_req_i = 1'b0;

    assign cpu_ram_rst = DUT_RESET & rst_ni;

    assign boot_addr_mux            = ( lfsr_en == 0 ) ?  BOOT_ADDR         : ph_shft_o[31:0];
    assign ext_perf_counters_mux    = ( lfsr_en == 0 ) ?  2'b0              : ph_shft_o[2:1];
    assign fregfile_disable_mux     = ( lfsr_en == 0 ) ?  1'b0              : ph_shft_o[0];
    assign instr_gnt_mux            = ( lfsr_en == 0 ) ?  instr_gnt         : ph_shft_o[1];
    assign instr_rvalid_mux         = ( lfsr_en == 0 ) ?  instr_rvalid      : ph_shft_o[2];
    assign data_gnt_mux             = ( lfsr_en == 0 ) ?  data_gnt          : ph_shft_o[3];
    assign data_rvalid_mux          = ( lfsr_en == 0 ) ?  data_rvalid       : ph_shft_o[4];  
    assign apu_master_gnt_mux       = ( lfsr_en == 0 ) ?  1'b0              : ph_shft_o[5];  
    assign apu_master_valid_mux     = ( lfsr_en == 0 ) ?  1'b0              : ph_shft_o[6];  
    assign irq_mux                  = ( lfsr_en == 0 ) ?  irq               : ph_shft_o[7];  
    assign irq_sec_mux              = ( lfsr_en == 0 ) ?  irq_sec           : ph_shft_o[8];    
    assign debug_req_mux            = ( lfsr_en == 0 ) ?  debug_req_i       : ph_shft_o[9];    
    assign fetch_enable_mux         = ( lfsr_en == 0 ) ?  fetch_enable_i    : ph_shft_o[10];  
    assign core_id_mux              = ( lfsr_en == 0 ) ?  4'h0              : ph_shft_o[3:0];  
    assign cluster_id_mux           = ( lfsr_en == 0 ) ?  6'h0              : ph_shft_o[5:0];    
    assign instr_rdata_mux          = ( lfsr_en == 0 ) ?  instr_rdata       : {ph_shft_o[63:0],ph_shft_o[63:0]};    
    assign data_rdata_mux           = ( lfsr_en == 0 ) ?  data_rdata        : ph_shft_o[31:0];    
    assign apu_master_result_mux    = ( lfsr_en == 0 ) ?  32'b0             : ph_shft_o[31:0];         
    assign apu_master_flags_mux     = ( lfsr_en == 0 ) ?  5'b0              : ph_shft_o[4:0];       
    assign irq_id_mux               = ( lfsr_en == 0 ) ?  irq_id_in         : ph_shft_o[4:0];    

    assign sp_cmp_in = {instr_addr,instr_req,data_addr,data_wdata,data_we,data_req,data_be,1'b0,1'b1,apu_master_operands,6'b0,2'b0,15'b0,irq_ack,irq_id_out,sec_lvl,core_busy};
    // instantiate the core
    riscv_core_0_128_1_16_1_1_0_0_0_0_0_0_0_0_0_3_6_15_5_1a110800
    riscv_core_i
        (
         .clk_i                  ( clk_i                 ),
         .rst_ni                 ( cpu_ram_rst           ),

         .clock_en_i             ( 1'b1                  ),
         .test_en_i              ( SCAN_EN               ),
         .test_mode_tp           ( test_en               ),

         .boot_addr_i            ( boot_addr_mux         ),
         .core_id_i              ( core_id_mux           ),
         .cluster_id_i           ( cluster_id_mux        ),

         .instr_addr_o           ( instr_addr            ),
         .instr_req_o            ( instr_req             ),
         .instr_rdata_i          ( instr_rdata_mux       ),
         .instr_gnt_i            ( instr_gnt_mux         ),
         .instr_rvalid_i         ( instr_rvalid_mux      ),

         .data_addr_o            ( data_addr             ),
         .data_wdata_o           ( data_wdata            ),
         .data_we_o              ( data_we               ),
         .data_req_o             ( data_req              ),
         .data_be_o              ( data_be               ),
         .data_rdata_i           ( data_rdata_mux        ),
         .data_gnt_i             ( data_gnt_mux          ),
         .data_rvalid_i          ( data_rvalid_mux       ),

         .apu_master_req_o       (                       ),
         .apu_master_ready_o     (                       ),
         .apu_master_gnt_i       ( apu_master_gnt_mux    ),
         .apu_master_operands_o  ( apu_master_operands   ),
         .apu_master_op_o        (                       ),
         .apu_master_type_o      (                       ),
         .apu_master_flags_o     (                       ),
         .apu_master_valid_i     ( apu_master_valid_mux  ),
         .apu_master_result_i    ( apu_master_result_mux ),
         .apu_master_flags_i     ( apu_master_flags_mux  ),

         .irq_i                  ( irq_mux               ),
         .irq_id_i               ( irq_id_mux            ),
         .irq_ack_o              ( irq_ack               ),
         .irq_id_o               ( irq_id_out            ),
         .irq_sec_i              ( irq_sec_mux           ),

         .sec_lvl_o              ( sec_lvl               ),

         .debug_req_i            ( debug_req_mux         ),

         .fetch_enable_i         ( fetch_enable_mux      ),
         .core_busy_o            ( core_busy             ),

         .ext_perf_counters_i    ( ext_perf_counters_mux ),
         .fregfile_disable_i     ( fregfile_disable_mux  ));

    // this handles read to RAM and memory mapped pseudo peripherals
    mm_ram
        #(.RAM_ADDR_WIDTH (RAM_ADDR_WIDTH),
          .INSTR_RDATA_WIDTH (INSTR_RDATA_WIDTH))
    ram_i
        (.clk_i          ( clk_i & ~lfsr_en               ),
         .rst_ni         ( cpu_ram_rst                    ),

         .instr_req_i    ( instr_req                      ),
         .instr_addr_i   ( instr_addr[RAM_ADDR_WIDTH-1:0] ),
         .instr_rdata_o  ( instr_rdata                    ),
         .instr_rvalid_o ( instr_rvalid                   ),
         .instr_gnt_o    ( instr_gnt                      ),

         .data_req_i     ( data_req                       ),
         .data_addr_i    ( data_addr                      ),
         .data_we_i      ( data_we                        ),
         .data_be_i      ( data_be                        ),
         .data_wdata_i   ( data_wdata                     ),
         .data_rdata_o   ( data_rdata                     ),
         .data_rvalid_o  ( data_rvalid                    ),
         .data_gnt_o     ( data_gnt                       ),

         .irq_id_i       ( irq_id_out                     ),
         .irq_ack_i      ( irq_ack                        ),
         .irq_id_o       ( irq_id_in                      ),
         .irq_o          ( irq                            ),

         .pc_core_id_i   ( riscv_core_i.pc_id             ),

         .tests_passed_o ( tests_passed_o                 ),
         .tests_failed_o ( tests_failed_o                 ),
         .exit_valid_o   ( exit_valid_o                   ),
         .exit_value_o   ( exit_value_o                   ));


      PHASE_SHFT
      #(
        .N (64)
      )
      ph_shft_i
      (
        .LFSR_OUT         ( lfsr_out ),
        .PH_SHFT_O        ( ph_shft_o)
      );

      LFSR
      lfsr_i(
        .CLK              ( clk_i             ),
        .RESET            ( LFSR_MISR_RESET   ),
        .LD               ( lfsr_ld           ),
        .EN               ( lfsr_en           ),
        .DIN              ( lfsr_seed         ),
        .PRN              ( lfsr_out          ),
        .ZERO_D           (                   )
      );

      MISR 
      #(
        .N(64),
        .SEED(65'b1)
      )
      misr_i(
        .clk              ( clk_i                 ),
        .rst              ( LFSR_MISR_RESET       ),
        .EN_i             ( misr_en               ),
        .DATA_IN          ( misr_in               ),
        .SIGNATURE        ( misr_signature        )
      );

      SPACE_COMP
      sp_cmp_i (
        .D_in             ( sp_cmp_in ),
        .D_out            ( misr_in   )
      );

      ROM 
      seed_rom_i (
        .addr             ( seed_addr_o ),
        .dout             ( lfsr_seed   )
      );

      controller
      #(
        .GOLDEN_SIGNATURE(golden_sign)
      )
      ctl_i
      (
        .clk              ( clk_i           ),
        .rst              ( ~rst_ni         ),
        .TEST             ( test_en         ),
        .MISR_OUT         ( misr_signature  ),
        .SEED_ADDR        ( seed_addr_o     ),
        .GO               ( bist_go         ),
        .TPG_MUX_en       ( lfsr_en         ),
        .ODE_en           ( misr_en         ),
        .END_TEST         ( bist_end        ),
        .TPG_LD           ( lfsr_ld          ),
        .SCAN_EN          ( SCAN_EN         ),
        .DUT_RESET        ( DUT_RESET       ),
        .LFSR_MISR_RESET  ( LFSR_MISR_RESET )
      );


endmodule // riscv_wrapper
