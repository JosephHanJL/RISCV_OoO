#!/bin/bash

# this function takes a color by number, then prints the rest of the arguments
# call it like: echo_color 2 this is a message
echo_color() {
    # check if in a terminal and in a compliant shell
    # use tput setaf to set the ANSI Foreground color based on the number 0-7:
    # 0:black, 1:red, 2:green, 3:yellow, 4:blue, 5:magenta, 6:cyan, 7:white
    # other numbers are valid, but not specified in the man page
    if [ -t 0 ]; then tput setaf $1; fi;
    # echo the message in this color
    echo "${@:2:$#}"
    # reset the terminal color
    if [ -t 0 ]; then tput sgr0; fi
}

for i in 4 8 15 16 23 42
do
    echo "Starting test with CAM_SIZE $i"
    # need to use -B flag to unconditionally remake simv
    cmd="make -B CAM_SIZE=$i simv"
    echo "Compiling simulation as: '$cmd'"
    $cmd &> /dev/null

    cmd="make CAM_SIZE=$i sim"
    echo "Running testbench as: '$cmd'"
    output=$($cmd | grep "@@@")

    if [[ $(echo $output | grep "Passed") ]]; then
        echo_color 2 $output
    else
        echo_color 1 $output
    fi
done

for i in 8 16 23
do
    echo "Starting synth test with CAM_SIZE $i"
    cmd="make CAM_SIZE=$i CAM_SIZE$i.vg"
    echo "Synthesizing module as: '$cmd'"
    $cmd &> /dev/null
    # need to use -B to remake syn_simv, but don't want to remake CAM_SIZE$i.vg every time
    cmd="make -B --assume-old=CAM_SIZE$i.vg CAM_SIZE=$i syn_simv"
    echo "Compiling synthesis as: '$cmd'"
    $cmd &> /dev/null

    cmd="make CAM_SIZE=$i syn"
    echo "Running synthesis testbench as: '$cmd'"
    output=$($cmd | grep "@@@")
    output=$(make CAM_SIZE=$i syn | grep "@@@")

    if [[ $(echo $output | grep "Passed") ]]; then
        echo_color 2 $output
    else
        echo_color 1 $output
    fi
done
