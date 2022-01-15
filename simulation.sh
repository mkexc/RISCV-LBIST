#!/bin/sh

mkdir -p run
cd run

# Build the files

vlib work

vlog +define+functional ../syn/techlib/NangateOpenCellLibrary.v
vcom ../bist/constants.vhd
vcom ../bist/LFSR/lfsr.vhd
vcom ../bist/LFSR/PHASE_SHFT.vhd
vlog ../syn/output/riscv_core_scan64.v
vcom ../bist/riscv_core_testbench.vhd

# Invoke QuestaSim shell and run the TCL script
vsim -t 1ps -c -novopt work.riscv_testbench -do ../simulation_script.tcl -wlf riscv_core_sim.wlf
