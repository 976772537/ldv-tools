DIR=$(dirname $(readlink -f "$0"))
RULE=100_1a
SAMPLE=tty_buffer_request_room
REGR=$DIR/../../regr-task-${RULE}

FUNCTION=$1
[[ -n "$FUNCTION" ]] || { echo "Please specify function name as \$1" >&2; exit 1; }

head -n 2 $REGR | sed -e "s/${SAMPLE}/${FUNCTION}/g" >>$REGR
