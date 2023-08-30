#!/usr/bin/env bash
exit_status=0
mydir="${0%/*}"

OVERRIDE=false
BUILD_BED2GTF=false


# Parsing arguments
for arg in "$@"
do
    case $arg in
        --override)
            OVERRIDE=true
            echo "Overriding existing CESAR installation and models"
            ;;
        --bed2gtf)
            BUILD_BED2GTF=true
            echo "Building bed2gtf"
            ;;
    esac
done

printf "Compiling C code...\n"

# Check machine architecture and set appropriate flags
if [ $(uname -m) = "arm64" ]; then
    CFLAGS="-Wall -Wextra -O2 -g -std=c99 -arch arm64" # adjust flags for M1 if necessary
else
    CFLAGS="-Wall -Wextra -O2 -g -std=c99" # original flags for x86
fi

gcc $CFLAGS -o ${mydir}/modules/chain_score_filter ${mydir}/modules/chain_score_filter.c
gcc $CFLAGS -o ${mydir}/modules/chain_filter_by_id ${mydir}/modules/chain_filter_by_id.c
gcc $CFLAGS -fPIC -shared -o ${mydir}/modules/chain_coords_converter_slib.so ${mydir}/modules/chain_coords_converter_slib.c
gcc $CFLAGS -fPIC -shared -o ${mydir}/modules/extract_subchain_slib.so ${mydir}/modules/extract_subchain_slib.c
gcc $CFLAGS -fPIC -shared -o ${mydir}/modules/chain_bst_lib.so ${mydir}/modules/chain_bst_lib.c

if ! $OVERRIDE && { [[ -f "./models/se_model.dat" ]] || [[ -f "./models/me_model.dat" ]]; }
then
    printf "Model found\n";
else
    printf "XGBoost model not found\nTraining...\n"
    eval "python3 train_model.py"
    printf "Model created\n"
fi

if ! $OVERRIDE && [[ -f "./CESAR2.0/cesar" ]]
then
    printf "CESAR installation found\n"
else
    printf "CESAR installation not found, cloning\n"
    git submodule init CESAR2.0
    git submodule update CESAR2.0
    cd CESAR2.0 && make
    printf "Don't worry about '*** are the same file' message if you see it\n"
fi

if $BUILD_BED2GTF; then
    if ! $OVERRIDE && [[ -f "./bed2gtf/some_check_file" ]]
    then
        printf "bed2gtf installation found\n"
    else
        printf "bed2gtf installation not found, cloning and building\n"
        git submodule init bed2gtf
        git submodule update bed2gtf
        # ACTUAL BUILD COMMAND HERE
    fi
fi