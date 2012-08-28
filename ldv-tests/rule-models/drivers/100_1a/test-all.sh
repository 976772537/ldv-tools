#!/bin/bash
REPO=~/repos/ldv-tools/
KERNEL_RULES=kernel-rules
ENV=$(ls -1 linux-* | tail -n 1)
PACKED=packed_drivers/
RULE=100_1a
LOG=log.txt

GREEN="\033[32m"
RED="\033[31m"
DEFAULT="\033[0m"

function print_verdict
{
	COLOR=$RED
	[[ "$1" == S-* && "$2" = "safe" || "$1" == U-* && "$2" = "unsafe" ]] && COLOR=$GREEN
	printf "%-16s\t[$COLOR%s$DEFAULT]\n" "$1" "$2"
}

echo -n "" >$LOG
for i in $PACKED/$RULE--test-*.tar.bz2; do
	ARR=( $( LDV_VIEW=y LDV_KERNEL_RULES=$REPO/$KERNEL_RULES BLAST_OPTIONS="-devdebug" ldv-manager envs=$ENV drivers=$i rule_models=100_1a 2>&1 | tee -a $LOG | grep -A 50 'The results of the launch' | grep -Eo '(S|U)-.*\.ko|safe|unsafe|unknown' | tr '\n' ' ') )
	if [[ "${#ARR[@]}" -eq "16" ]]; then
		for ((i = 0; i < 16; i += 2)); do
			print_verdict "${ARR[i]}" "${ARR[((i + 1))]}"
		done
	else
		echo -e "${RED}FAIL${DEFAULT}\t${ARR[@]}"
	fi
done
