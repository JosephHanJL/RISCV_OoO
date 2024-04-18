echo "Comparing ground truth outputs to new processor"
# This only runs *.s files. How could you add *.c files?

passed=1
for source_file in programs/*.s; do
    if [ "$source_file" = "programs/crt.s" ]; then
        continue
    fi

    

        program=$(echo "$source_file" | cut -d '.' -f1 | cut -d '/' -f 2)
        if [ -f /user/stud/fall22/eb3504/Documents/Computer_Architecture/Project_3/csee4824-project-3-main/correct_out_no_pipeline/$program.out ]; then
        echo "Running $program"
        make $program.out > /dev/null

        echo "Comparing writeback output for $program"
        wb_comp=$(diff /user/stud/fall22/eb3504/Documents/Computer_Architecture/Project_3/csee4824-project-3-main/correct_out_no_pipeline/$program.wb output/$program.wb)
        if [ "$wb_comp" != "" ]; then
            echo "Program $program writeback incorrect"
            echo "@@@ Failed"
            passed=0
        fi

        echo "Comparing memory output for $program"
        mem_comp=$(diff <(grep '@@@' /user/stud/fall22/eb3504/Documents/Computer_Architecture/Project_3/csee4824-project-3-main/correct_out_no_pipeline/$program.out) <(grep '@@@' output/$program.out))
        if [ "$mem_comp" != "" ]; then
            echo "Program $program memory output incorrect"
            echo "@@@ Failed"
            passed=0
        fi
    fi
done

if [ "$passed" = "1" ]; then
    echo "@@@ Passed"
else
    echo "@@@ Failed"
fi