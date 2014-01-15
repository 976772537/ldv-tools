#!/bin/bash

# Die if a program is not in PATH
# Usage: program_required <program_name>
program_required()
{
	local prg="$1"; shift
	local msg="$1"; shift

	if ! command -v "$prg" >/dev/null 2>&1; then
		message "Program \"$prg\" is required but not found in PATH"
		if [ -n "$msg" ]; then
			fatal "$msg"
		else
			exit 1
		fi
	fi
}

# Filter out the first element from a comma-separated list of elements.
# Usage: strip_first <list>
strip_first()
{
	printf "%s" "$1" | sed -e 's/^[^,]*,\{0,1\}//g'
}

# Filter out all but the first element from a comma-separated list of elements.
# Usage: leave_first <list>
leave_first()
{
	printf "%s" "$1" | sed -e 's/,.*$//g'
}

# Filter out all but the second element from a comma-separated list of elements.
# Usage: leave_second <list>
leave_second()
{
	leave_first "$(strip_first "$1")"
}

# Filter out all but the third element from a comma-separated list of elements.
# Usage: leave_third <list>
leave_third()
{
	leave_second "$(strip_first "$1")"
}
