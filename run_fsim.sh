#!/bin/bash

cd $( dirname $0)
root_dir=${PWD}
cd - &>/dev/null

cd ${root_dir}/syn/run

# Invoke TetraMAX and run the TCL script, see log file into ./syn/log dir
tmax  ../fsim_stuck_script.tcl -shell | tee ../log/tmax_stuck_log.log 
tmax  ../fsim_transition_script.tcl -shell | tee ../log/tmax_transition_log.log 

