#!/bin/bash
DIR=$(dirname $(readlink -f "$0"))
RULE=0100a
SAMPLE=tty_buffer_request_room
ASPECT=$DIR/../../../../kernel-rules/files/model${RULE}-blast.aspect

ID_REGEXP='[a-zA-Z_][a-zA-Z0-9_]*'

FUNCTIONS=($(grep -Eo '(call|execution)\(.*$' $ASPECT | sed -e 's/\(call\|execution\)(//g' -e 's/(.*//g' | grep -Eo "${ID_REGEXP}\$"))
for i in ${FUNCTIONS[@]}; do
    if [[ "$i" != "$SAMPLE" ]]; then
        cp -fR "test-${SAMPLE}" "test-${i}"
        mv "test-${i}/S-${SAMPLE}.c" "test-${i}/S-${i}.c"
        mv "test-${i}/U-${SAMPLE}.c" "test-${i}/U-${i}.c"
        for j in test-${i}/*; do
            sed -i -e "s/${SAMPLE}/${i}/g" ${j}
        done
    fi
done