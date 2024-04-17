echo "Generating ground truth outputs from original processor"

# This only runs *.s files. How could you add *.c files?
for source_file in programs/*.s; do
    if [ "$source_file" = "programs/crt.s" ]; then
        continue
    fi
    program=$(echo "$source_file" | cut -d '.' -f1 | cut -d '/' -f 2)

    echo "@@@ Running $program"

    make $program.out

done
