#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
FILENAME_CPU="cpu.txt"
FILENAME_MEM="mem.txt"
FILENAME_RSS="rss.txt"
OUTPUT_CPU=$SCRIPT_DIR/$FILENAME_CPU
OUTPUT_MEM=$SCRIPT_DIR/$FILENAME_MEM
OUTPUT_RSS=$SCRIPT_DIR/$FILENAME_RSS


# $1 line number begin
# $2 line number end
function extract_lines () {
    if [ -z "$2" ]; then
        awk "NR>=$1 {print}"
    else
        awk "NR==$1,NR==$2 {print}"
    fi
}

# $1 grep pattern
function get_line_number () {
    grep -n -m 1 -E "$1" | cut -d : -f 1
}

# grep after the specific line
# 
# $1 line num to start searching
# $2 grep pattern
# $3 file
# $4 mode
function grep_after () {
    case "$4" in
      "n") # return line number
        num=$(cat $3 | extract_lines $1 | get_line_number "$2") 
        if [ -z "$num" ]; then
            break
        else
            echo $(( $1 + $num - 1 ))
        fi
        ;;
      *) # return matched string
        cat $3 | extract_lines $1 | grep -m 1 -E "$2" 
        ;;
    esac
}

# grep after the specific line but input is reversed
# 
# $1 line num to start searching
# $2 grep pattern
# $3 file
# $4 mode
function perg_after () {
    case "$4" in
      "n") # return line number
        num=$(tac $3 | extract_lines $1 | get_line_number "$2") 
        if [ -z "$num" ]; then
            break
        else
            echo $(( $1 + $num - 1 ))
        fi
        ;;
      *) # return matched string
        tac $3 | extract_lines $1 | grep -m 1 "$2" 
        ;;
    esac
}


if test -f $OUTPUT_CPU; then
    echo "File $FILENAME_CPU already exists"
    exit
fi
if test -f $OUTPUT_MEM; then
    echo "File $FILENAME_MEM already exists"
    exit
fi
if test -f $OUTPUT_RSS; then
    echo "File $FILENAME_RSS already exists"
    exit
fi

if [ $# -eq 0 ];then
    echo "No arguments supplied. Please pass at least one vmkernel.log file."
    exit
fi

end=1
while true; # get VM info
do
    begin=$(grep_after $end "Start of system state" $@ "n")
    #begin=$(cat $VIMDUMP | grep_after2 $end "config = (vim.vm.Summary.ConfigSummary)" "n")
    echo "begin $begin"
    if [ -z "$begin" ] # if the string was not found
    then
        break
    fi

    end=$(grep_after $begin "End of system state" $@ "n")
    echo "end $end"

    #egrep -v '0.0  0.0' procstate | sed -e 's/  */ /g' | cut -d ' ' -f 6,11-13 | sort -k 1,1 -t " " -rn | head

    grep_after $end "Start of system state" $@ "" >> $OUTPUT_CPU
    cat $@ | extract_lines $begin $end | egrep -v '0.0  0.0' | sed -e 's/  */ /g' | cut -d ' ' -f 3,11-13 | sort -k 1,1 -t " " -rn | head >> $OUTPUT_CPU
    printf "\n" >> $OUTPUT_CPU

    grep_after $end "Start of system state" $@ "" >> $OUTPUT_MEM
    cat $@ | extract_lines $begin $end | egrep -v '0.0  0.0' | sed -e 's/  */ /g' | cut -d ' ' -f 4,11-13 | sort -k 1,1 -t " " -rn | head >> $OUTPUT_MEM
    printf "\n" >> $OUTPUT_MEM

    grep_after $end "Start of system state" $@ "" >> $OUTPUT_RSS
    cat $@ | extract_lines $begin $end | egrep -v '0.0  0.0' | sed -e 's/  */ /g' | cut -d ' ' -f 6,11-13 | sort -k 1,1 -t " " -rn | head >> $OUTPUT_RSS
    printf "\n" >> $OUTPUT_RSS

done

echo "$OUTPUT_CPU    generated."
echo "$OUTPUT_MEM    generated."
echo "$OUTPUT_RSS    generated."
