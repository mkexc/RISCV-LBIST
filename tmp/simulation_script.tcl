vcd dumpports /riscv_testbench/dut/* -file riscv_core_dumpports.vcd
#run $env(SIM_TIME) ns
run 4000000 ns
#run 1255000 ns
quit
