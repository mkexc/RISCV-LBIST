file mkdir fsim_out
read_netlist syn/techlib/NangateOpenCellLibrary.v -library -define functional
read_netlist syn/output/riscv_core_scan64.v -master
run_build_model riscv_core_0_128_1_16_1_1_0_0_0_0_0_0_0_0_0_3_6_15_5_1a110800

#add_pi_constraints X -all
#remove_pi_constraints clk_i
#remove_pi_constraints clock_en_i
#remove_pi_constraints rst_ni
#remove_pi_constraints test_mode_tp
#remove_pi_constraints test_en_i
#remove_pi_constraints test_si1
#remove_pi_constraints test_si2
#remove_pi_constraints test_si3
#remove_pi_constraints test_si4
#remove_pi_constraints test_si5
#remove_pi_constraints test_si6
#remove_pi_constraints test_si7
#remove_pi_constraints test_si8
#remove_pi_constraints test_si9
#remove_pi_constraints test_si10
#remove_pi_constraints test_si11
#remove_pi_constraints test_si12
#remove_pi_constraints test_si13
#remove_pi_constraints test_si14
#remove_pi_constraints test_si15
#remove_pi_constraints test_si16
#remove_pi_constraints test_si17
#remove_pi_constraints test_si18
#remove_pi_constraints test_si19
#remove_pi_constraints test_si20
#remove_pi_constraints test_si21
#remove_pi_constraints test_si22
#remove_pi_constraints test_si23
#remove_pi_constraints test_si24
#remove_pi_constraints test_si25
#remove_pi_constraints test_si26
#remove_pi_constraints test_si27
#remove_pi_constraints test_si28
#remove_pi_constraints test_si29
#remove_pi_constraints test_si30
#remove_pi_constraints test_si31
#remove_pi_constraints test_si32
#remove_pi_constraints test_si33
#remove_pi_constraints test_si34
#remove_pi_constraints test_si35
#remove_pi_constraints test_si36
#remove_pi_constraints test_si37
#remove_pi_constraints test_si38
#remove_pi_constraints test_si39
#remove_pi_constraints test_si40
#remove_pi_constraints test_si41
#remove_pi_constraints test_si42
#remove_pi_constraints test_si43
#remove_pi_constraints test_si44
#remove_pi_constraints test_si45
#remove_pi_constraints test_si46
#remove_pi_constraints test_si47
#remove_pi_constraints test_si48
#remove_pi_constraints test_si49
#remove_pi_constraints test_si50
#remove_pi_constraints test_si51
#remove_pi_constraints test_si52
#remove_pi_constraints test_si53
#remove_pi_constraints test_si54
#remove_pi_constraints test_si55
#remove_pi_constraints test_si56
#remove_pi_constraints test_si57
#remove_pi_constraints test_si58
#remove_pi_constraints test_si59
#remove_pi_constraints test_si60
#remove_pi_constraints test_si61
#remove_pi_constraints test_si62
#remove_pi_constraints test_si63
#remove_pi_constraints test_si64

#add_po_masks -all
#remove_po_masks test_so1
#remove_po_masks test_so2
#remove_po_masks test_so3
#remove_po_masks test_so4
#remove_po_masks test_so5
#remove_po_masks test_so6
#remove_po_masks test_so7
#remove_po_masks test_so8
#remove_po_masks test_so9
#remove_po_masks test_so10
#remove_po_masks test_so11
#remove_po_masks test_so12
#remove_po_masks test_so13
#remove_po_masks test_so14
#remove_po_masks test_so15
#remove_po_masks test_so16
#remove_po_masks test_so17
#remove_po_masks test_so18
#remove_po_masks test_so19
#remove_po_masks test_so20
#remove_po_masks test_so21
#remove_po_masks test_so22
#remove_po_masks test_so23
#remove_po_masks test_so24
#remove_po_masks test_so25
#remove_po_masks test_so26
#remove_po_masks data_we_o
#remove_po_masks test_so28
#remove_po_masks test_so29
#remove_po_masks test_so30
#remove_po_masks irq_id_o[3]
#remove_po_masks test_so32
#remove_po_masks test_so33
#remove_po_masks test_so34
#remove_po_masks test_so35
#remove_po_masks test_so36
#remove_po_masks test_so37
#remove_po_masks test_so38
#remove_po_masks test_so39
#remove_po_masks test_so40
#remove_po_masks test_so41
#remove_po_masks test_so42
#remove_po_masks test_so43
#remove_po_masks test_so44
#remove_po_masks test_so45
#remove_po_masks test_so46
#remove_po_masks test_so47
#remove_po_masks test_so48
#remove_po_masks test_so49
#remove_po_masks test_so50
#remove_po_masks test_so51
#remove_po_masks test_so52
#remove_po_masks test_so53
#remove_po_masks test_so54
#remove_po_masks test_so55
#remove_po_masks test_so56
#remove_po_masks test_so57
#remove_po_masks test_so58
#remove_po_masks test_so59
#remove_po_masks test_so60
#remove_po_masks test_so61
#remove_po_masks test_so62
#remove_po_masks test_so63
#remove_po_masks test_so64

run_drc ./syn/output/riscv_core_scan64.spf

set_patterns -external run/riscv_core_dumpports.vcd -sensitive -strobe_period {100 ns} -strobe_offset {40 ns} -vcd_clock auto
#report_pi_constraints
#report_po_masks


run_simulation -sequential
set_faults -model stuck
add_faults -all

#set_patterns -internal
#run_atpg -auto_compression
run_fault_sim -sequential
set_faults -fault_coverage
report_summaries > fsim_out/fsim_stuck_lfsr.txt

write_faults lfsr_faults.flt -all -uncol -rep 
write_faults lfsr_NC_faults.flt -class NC -rep -col
write_faults lfsr_NO_faults.flt -class NO -rep -col

# --- switch to SCAN-based ATPG 

drc -force

run_drc ./syn/output/riscv_core_scan64.spf
set_patterns -delete
set_patterns -internal
read_faults lfsr_faults.flt -retain

set_atpg -abort 20 -merge high
run_atpg -auto_compression

report_summaries > fsim_out/fsim_stuck_lfsr_atpg.txt
write_patterns atpg_patterns.stil -format stil -rep
write_faults lfsr_atpg_faults.flt -all -uncollapsed -rep 
write_faults lfsr_atpg_AU_faults.flt -class AU -col -rep
write_faults lfsr_atpg_UD_faults.flt -class UD -col -rep
write_faults lfsr_atpg_ND_faults.flt -class ND -col -rep
