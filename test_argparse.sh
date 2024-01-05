source argparse.sh

assert() {
   if ! test "$@"; then
        echo >&2 "Assert FAILED: $*"
        return 1
    fi
}

declare -A definitions=(
    ["foo"]="-f|--foo;required;1;is_integer;help"
    ["verbose"]="-v;optional;0;;help"
)

declare -A outputs=()
parse_args definitions outputs "$0" --foo 100 -v

assert ${outputs["foo"]} == 100; rv+=$?
assert ${outputs["verbose"]} == 1; rv+=$?

exit $rv
