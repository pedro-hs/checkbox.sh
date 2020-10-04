#!/usr/bin/env bash
#===============================================================================
#NAME
#  tui_checkbox.sh
#
#DESCRIPTION
#  Create checkboxes with single and multiple selection
#
#SOURCE
#  <https://github.com/pedro-hs/tui-checkbox>
#
#ADAPTED FROM
#  <https://gist.github.com/blurayne/f63c5a8521c0eeab8e9afd8baa45c65e>
#  <https://www.bughunter2k.de/blog/cursor-controlled-selectmenu-in-bash>
#
#===============================================================================
SELECTED="[x]"
UNSELECTED="[ ]"

WHITE="\e[2K\e[37m"
BLUE="\e[2K\e[34m"
RED="\e[2K\e[31m"
GREEN="\e[2K\e[32m"

#===============================================================================
# VARS
#===============================================================================
options=("Option 1" "Option 2" "Option 3" "Option 4" "Option 5" "Option 6" "Option 7" "Option 8" "Option 9" "Option 10" "Option 11" "Option 12" "Option 13" "Option 14" "Option 15" "Option 16" "Option 17" "Option 18" "Option 19" "Option 20" "Option 21" "Option 22" "Option 23" "Option 24" "Option 25" "Option 26" "Option 27" "Option 28" "Option 29" "Option 30")

cursor=0
start_page_index=0
options_length=${#options[@]}

has_multiple_options=false
will_return_index=false
unselect_mode_on=false
select_mode_on=false

output=()
selected_options=()

content=""
color=$WHITE

#===============================================================================
# UTILS
#===============================================================================
array_contains_value() {
    value=$1
    shift
    array=("$@")
    [[ ${array[@]} =~ $value ]] && return 0 || return 1
}

array_without_value() {
    local args=() value="${1}" s
    shift

    for s in "${@}"; do
        if [ "${value}" != "${s}" ]; then
            args+=("${s}")
        fi
    done

    echo "${args[@]}"
}

#===============================================================================
# RENDERIZATION
#===============================================================================
index_in_page() {
    index=$1

    terminal_width=$(get_terminal_width)
    end_page_index=$(get_end_page_index $terminal_width)
    handle_start_page_index $end_page_index $terminal_width

    return $([[ $index -ge $start_page_index ]] && [[ $index -le $end_page_index ]])
}

draw_line() {
    index=$1
    option=$2

    if array_contains_value "$index" "${selected_options[@]}"; then
        content+="$color$SELECTED $option\n"

    else
        content+="$color$UNSELECTED $option\n"
    fi
}

set_line_color() {
    if $has_multiple_options && $select_mode_on; then
        color=$GREEN

    elif $has_multiple_options && $unselect_mode_on; then
        color=$RED

    else
        color=$BLUE
    fi
}

draw() {
    render
    content=""

    for index in "${!options[@]}"; do
        if index_in_page $index; then
            option=${options[$index]}

            if [[ ${options[$cursor]} == $option ]]; then
                set_line_color
                draw_line $index "$option"
                color=$WHITE

            else
                draw_line $index "$option"
            fi
        fi
    done

    render
}

render() {
    clear
    echo -en "${content}"
}


#===============================================================================
# KEY ACTIONS
#===============================================================================
toggle_select_mode() {
    if $has_multiple_options; then
        unselect_mode_on=false

        if $select_mode_on; then
            select_mode_on=false

        else
            select_mode_on=true
            selected_options+=("$cursor")
        fi
    fi
}

toggle_unselect_mode() {
    if $has_multiple_options; then
        select_mode_on=false

        if $unselect_mode_on; then
            unselect_mode_on=false

        else
            unselect_mode_on=true
            selected_options=($(array_without_value "$cursor" "${selected_options[@]}"))
        fi
    fi
}

select_all() {
    if $has_multiple_options; then
        for index in ${!options[@]}; do
            selected_options+=("${index}")
        done
    fi
}

unselect_all() {
    if $has_multiple_options; then
        for index in ${!options[@]}; do
            selected_options=($(array_without_value "$index" "${selected_options[@]}"))
        done
    fi
}

page_up() {
    let cursor-=5

    if [[ "${cursor}" -lt 0 ]]; then
        cursor=0;
    fi
}

page_down() {
    let cursor+=5

    if [[ "${cursor}" -gt $((${#options[@]}-1)) ]]; then
        cursor=$((${#options[@]}-1))
    fi
}

select_option() {
    if ! array_contains_value "$cursor" "${selected_options[@]}"; then
        if $has_multiple_options; then
            selected_options+=("$cursor")

        else
            selected_options=("$cursor")
        fi

    else
        selected_options=($(array_without_value "$cursor" "${selected_options[@]}"))
    fi
}

select_option_loop() {
    if ! array_contains_value "$cursor" "${selected_options[@]}" && $has_multiple_options && $select_mode_on; then
        selected_options+=("$cursor")

    elif array_contains_value "$cursor" "${selected_options[@]}" && $has_multiple_options && $unselect_mode_on; then
        selected_options=($(array_without_value "$cursor" "${selected_options[@]}"))
    fi
}

confirm() {
    if $will_return_index; then
        output=${selected_options[@]}

    else
        for index in ${!options[@]}; do
            if array_contains_value "$index" "${selected_options[@]}"; then
                output+=("${options[index]}")
            fi
        done
    fi

    export output
}

#===============================================================================
# HANDLERS
#===============================================================================
handle_parameters() {
    while (( "$#" )); do
        opt="${1}"
        shift

        case "${opt}" in
            -i) will_return_index=true;;
            -m) has_multiple_options=true;;
        esac
    done
}

handle_key_press() {
    IFS= read -sN1 key 2>/dev/null >&2

    read -sN1 -t 0.0001 k1
    read -sN1 -t 0.0001 k2
    read -sN1 -t 0.0001 k3
    key+=${k1}${k2}${k3}

    case "${key}" in
        $'\x1b') key=_esc;;
        ' ') key=_space;;
        '') key=_enter;;
        $'\e') key=_enter;;
        $'\x0a') key=_enter;;
        $'\x7f') key=_backspace;;
        $'\x1b\x5b\x32\x7e') key=_insert;;
        $'\x1b\x5b\x35\x7e') key=_pgup;;
        $'\x1b\x5b\x36\x7e') key=_pgdown;;
        $'\e[1~'|$'\e0H'|$'\e[H') key=_home;;
        $'\e[4~'|$'\e0F'|$'\e[F') key=_end;;
        $'\e[A'|$'\e0A  '|$'\e[D'|$'\e0D') key=_up;;
        $'\e[B'|$'\e0B'|$'\e[C'|$'\e0C') key=_down;;
    esac

    echo $key
}

get_terminal_width() {
    terminal_width=$(tput lines)

    if [[ $terminal_width > $options_length ]]; then
        terminal_width=$options_length
    fi

    echo $terminal_width
}

get_end_page_index() {
    terminal_width=$1

    end_page_index=$((start_page_index + terminal_width - 2))
    ((end_page_index > options_length)) && ((end_page_index=$((options_length - terminal_width))))

    echo $end_page_index
}

handle_start_page_index() {
    end_page_index=$1
    terminal_width=$2

    if [[ $cursor -gt $end_page_index ]]; then
        start_page_index=$((end_page_index + 1))
        ((start_page_index > $options_length)) && ((start_page_index=$((options_length - terminal_width))))

    elif [[ $cursor -lt $end_page_index && ! $cursor -gt $start_page_index ]]; then
        start_page_index=$((start_page_index - 1))
        ((start_page_index < 0)) && ((start_page_index=0))
    fi

}

#===============================================================================
# MAIN
#===============================================================================
main() {
    handle_parameters $1 $2
    draw

    while true; do
        key=$(handle_key_press)

        case "$key" in
            _up|k) ((cursor > 0)) && ((cursor--));select_option_loop;;
            _down|j) ((cursor < ${#options[@]}-1)) && ((cursor++));select_option_loop;;
            _pgup|u) page_up;;
            _pgdown|d) page_down;;
            _enter|c) confirm; return;;
            _esc|q) exit && return;;
            _space|x) select_option;;
            _home|g) ((cursor=0));;
            _end|G) ((cursor=${#options[@]}-1));;
            _insert|v) toggle_select_mode;;
            _backspace|V) toggle_unselect_mode;;
            r) render;;
            a) select_all;;
            A) unselect_all;;
        esac

        draw
    done
}

main $1 $2
echo ${output[@]}
