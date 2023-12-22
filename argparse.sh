#!/bin/bash

is_number() {
    local re='^[+-]?[0-9]+([.][0-9]+)?$'
    [[ $1 =~ $re ]]
}

is_integer() {
    local re='^[+-]?[0-9]+$'
    [[ $1 =~ $re ]]
}

is_ipv4() {
    local re='^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$'
    [[ $1 =~ $re ]]
}


parse_args() {
    local -n arg_definitions=$1
    local -n arg_outputs=$2
    local prog=$3
    local -a errors
    local usage_synopsis
    local usage_options
    local i
    shift 2

    arg_definitions['help']='-h|--help;optional;;;;usage'

    for key in "${!arg_definitions[@]}"; do
        val=${arg_definitions[$key]}
        IFS=';' read -r opts_str required nargs validator help <<< "$val"
        IFS='|' read -ra opts <<< "$opts_str"

        if [[ "$required" == "optional" ]]; then
            usage_synopsis+="["
        fi
        usage_synopsis+="$opts_str "
        i=0
        while (( i++ < nargs)); do
            usage_synopsis+="${key^^}"
            if (( nargs > 1 )); then
                usage_synopsis+="$i"
            fi
        done
        if [[ "$required" == "optional" ]]; then
            usage_synopsis+="]"
        fi
        usage_synopsis+=" "
        usage_options+="$opts_str $help\n"

        for o in "${opts[@]}"; do
            local read_next=0
            local read_values=()
            for a in "$@"; do
                if (( read_next > 0 )); then
                    read_values+=( "$a" )
                    arg_outputs[$key]=${read_values[*]}
                    (( read_next-- || 0 ))
                    continue
                fi
                if [[ "$o" == "$a" ]]; then
                    if (( nargs )); then
                        read_next=$nargs
                    else
                        (( arg_outputs["$key"]++ || 0 ))
                    fi
                fi
            done
        done
        if [[ "$required" == "required" ]] && \
           ! [[ "${arg_outputs[$key]}" ]]; then
            errors+=( "${opts_str} is required" )
        fi
        if ! ${validator:-:} "${arg_outputs[$key]}"; then
            errors+=( "${opts_str} validation failed ($validator)" )
        fi
    done
    if [[ "${arg_outputs["help"]}" ]]; then
        echo -e "$prog  $usage_synopsis\n"
        echo -e "$usage_options"
    fi
    if (( ${#errors} )); then
        echo "${errors[@]}"
        exit 1
    fi

}

# todo:
# consumed multiple times?

declare -A definitions=(
    ["foo"]="-f|--foo;required;1;is_integer;help"
    ["verbose"]="-v;optional;0;;help"
)

declare -A outputs=()

parse_args definitions outputs "$0" "$@"
export definitions

for k in "${!outputs[@]}"; do
    echo "$k=${outputs[$k]}"
done
