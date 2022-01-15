#BUILD
file mkdir ../../fsim_out
read_netlist ../techlib/NangateOpenCellLibrary.v -library -define functional
read_netlist ../output/riscv_core_scan64.v -master
run_build_model riscv_core_0_128_1_16_1_1_0_0_0_0_0_0_0_0_0_3_6_15_5_1a110800

#DRC
run_drc ../output/riscv_core_scan64.spf

#TEST
#FSIM WITH EXTERNAL PATTERNS
set_patterns -external ../../run/riscv_core_dumpports.vcd -sensitive -strobe_period {100 ns} -strobe_offset {40 ns} -vcd_clock auto

run_simulation -sequential
set_faults -model stuck
add_faults -all

run_fault_sim -sequential
set_faults -fault_coverage
report_summaries > ../../fsim_out/fsim_stuck_lfsr.txt

write_faults ../../fsim_out/lfsr_faults.flt -all -uncol -rep 
write_faults ../../fsim_out/lfsr_NC_faults.flt -class NC -rep -col
write_faults ../../fsim_out/lfsr_NO_faults.flt -class NO -rep -col

#switch to SCAN-based ATPG 

drc -force

run_drc ../output/riscv_core_scan64.spf
set_patterns -delete
set_patterns -internal
read_faults lfsr_faults.flt -retain

set_atpg -abort 20 -merge high
run_atpg -auto_compression

report_summaries > ../../fsim_out/fsim_stuck_lfsr_atpg.txt
write_patterns ../../fsim_out/atpg_patterns.stil -format stil -rep
write_faults ../../fsim_out/lfsr_atpg_faults.flt -all -uncollapsed -rep 
write_faults ../../fsim_out/lfsr_atpg_AU_faults.flt -class AU -col -rep
write_faults ../../fsim_out/lfsr_atpg_UD_faults.flt -class UD -col -rep
write_faults ../../fsim_out/lfsr_atpg_ND_faults.flt -class ND -col -rep
