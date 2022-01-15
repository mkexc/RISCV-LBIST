# @Brief scan insertion script
# @Note  original risc-v synthesized netlist is needed or the clock gated one
# @Note clock gating netlist is used
# @Warning this script is executed inside the ../run/ directory, do not change the relative paths!

# setup script
set setupScript "../bin/NangateOpenCell.dc_setup_scan.tcl"
# output netlist name
set coreNetOut "riscv_core_wrapper_LBIST.v"

# output directory
set outDir "../../gate/"

source $setupScript

if {![file exists $outDir]} {
	file mkdir $outDir
}

analyze -format verilog		-work work ../../gate/riscv_core_scan64.v
analyze -format sverilog 	-work work ../../tb/core/cluster_clock_gating_nangate.sv
analyze -format sverilog 	-work work ../../tb/core/constants.sv
analyze -format vhdl 		-work work ../../bist/constants.vhd
analyze -format vhdl 		-work work ../../bist/CONTROLLER/ROM.vhd 
analyze -format vhdl 		-work work ../../bist/CONTROLLER/controller.vhd 
analyze -format vhdl 		-work work ../../bist/LFSR/lfsr.vhd
analyze -format vhdl 		-work work ../../bist/LFSR/PHASE_SHFT.vhd
analyze -format vhdl 		-work work ../../bist/MISR/misr.vhd
analyze -format vhdl 		-work work ../../bist/MISR/SPACE_COMP.vhd
analyze -format sverilog  	-work work ../../tb/core/riscv_wrapper_gate.sv

elaborate riscv_wrapper -lib work
compile_ultra -incremental -no_autoungroup

report_area > area_report_LBIST.rpt

write -hierarchy -format verilog -output $outDir$coreNetOut

#quit
