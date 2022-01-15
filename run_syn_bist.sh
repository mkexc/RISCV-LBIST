#!/bin/bash

# @Brief run synthesis scripts, final netlist will include clock gating scan cells
# @See ./syb/bin/syn_nangate.tcl
# @See ./syn/bin/syn_gate_nangate.tcl
# @Warning if there are already sythesized netlists in ./syn/standalone, do not run this script again!!

cd $( dirname $0)
root_dir=${PWD}
cd - &>/dev/null

cd ${root_dir}/syn/run


dc_shell -f ../bin/bist_synth.tcl | tee ../log/bist_synth.log
mv command.log ../log/command_bist_synth.log
rm -rf *
