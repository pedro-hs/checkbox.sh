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

options=("Option 1" "Option 2" "Option 3" "Option 4" "Option 5" "Option 6" "Option 7" "Option 8" "Option 9" "Option 10" "Option 11" "Option 13" "Option 14" "Option 15" "Option 16" "Option 17" "Option 18" "Option 19")
cursor=0
page_start_index=0
page_end_index=0
multiple_options=false
return_index=false
select_mode=false
unselect_mode=false
output=()
selected_options=()

#===============================================================================
array_contains_value() {
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
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

set_page() {
    lines_amount=$(tput lines)
    columns_amount=$(tput cols)
    page_end_index=$((page_start_index + lines_amount - 2))

    if [[ $cursor -gt $page_end_index ]]; then
        page_start_index=$((page_end_index + 1))
        ((page_start_index > ${!options[@]}-1)) && ((page_start_index=${!options[@]}))

    elif [[ $cursor -lt $page_end_index ]]; then
        page_start_index=$((page_start_index - 1))
        ((page_start_index < 0)) && ((page_start_index=0))
    fi
}

draw_line() {
    index=$1
    option=$2

    if array_contains_value "$index" "${selected_options[@]}"; then
        echo "$SELECTED $option"

    else
        echo "$UNSELECTED $option"
    fi
}

set_line_color() {
    if $multiple_options && $select_mode; then
        tput setaf 2

    elif $multiple_options && $unselect_mode; then
        tput setaf 1

    else
        tput setaf 4
    fi
}

draw() {
    for index in "${!options[@]}"; do
        set_page

        if [[ $index -ge $page_start_index ]] && [[ $index -le $page_end_index ]]; then
            option=${options[$index]}

            if [[ ${options[$cursor]} == $option ]]; then
                set_line_color
                draw_line $index "$option"
                tput sgr0

            else
                draw_line $index "$option"
            fi
        fi
    done
}

erase() {
    # for option in "${options[@]}"; do
    #     tput cuu1
    # done
    # tput ed
    clear
}

handle_key_press() {
    IFS= read -sN1 key 2>/dev/null >&2

    read -sN1 -t 0.0001 k1;
    read -sN1 -t 0.0001 k2;
    read -sN1 -t 0.0001 k3;
    key+=${k1}${k2}${k3}

    case "${key}" in
        '') key=_enter;;
        ' ') key=_space;;
        $'\x1b') key=_esc;;
        $'\x1b\x5b\x36\x7e') key=_pgdown;;
        $'\x1b\x5b\x35\x7e') key=_pgup;;
        $'\x7f') key=_backspace;;
        $'\x1b\x5b\x32\x7e') key=_insert;;
        $'\e[A'|$'\e0A  '|$'\e[D'|$'\e0D') key=_up;;
        $'\e[B'|$'\e0B'|$'\e[C'|$'\e0C') key=_down;;
        $'\e[1~'|$'\e0H'|$'\e[H') key=_home;;
        $'\e[4~'|$'\e0F'|$'\e[F') key=_end;;
        $'\e') key=_enter;;
        $'\x0a') key=_enter;;
    esac

    echo $key
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
        if $multiple_options; then
            selected_options+=("$cursor")

        else
            selected_options=("$cursor")
        fi

    else
        selected_options=($(array_without_value "$cursor" "${selected_options[@]}"))
    fi
}

select_option_loop() {
    if ! array_contains_value "$cursor" "${selected_options[@]}" && $multiple_options && $select_mode; then
        selected_options+=("$cursor")

    elif array_contains_value "$cursor" "${selected_options[@]}" && $multiple_options && $unselect_mode; then
        selected_options=($(array_without_value "$cursor" "${selected_options[@]}"))
    fi
}

confirm() {
    if $return_index; then
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

select_all() {
    if $multiple_options; then
        for index in ${!options[@]}; do
            selected_options+=("${index}")
        done
    fi
}

unselect_all() {
    if $multiple_options; then
        for index in ${!options[@]}; do
            selected_options=($(array_without_value "$index" "${selected_options[@]}"))
        done
    fi
}

handle_parameters() {
    while (( "$#" )); do
        opt="${1}"
        shift

        case "${opt}" in
            -i) return_index=true;;
            -m) multiple_options=true;;
        esac
    done
}

toggle_select_mode() {
    if $multiple_options; then
        unselect_mode=false

        if $select_mode; then
            select_mode=false

        else
            select_mode=true
            selected_options+=("$cursor")
        fi
    fi
}

toggle_unselect_mode() {
    if $multiple_options; then
        select_mode=false

        if $unselect_mode; then
            unselect_mode=false

        else
            unselect_mode=true
            selected_options=($(array_without_value "$cursor" "${selected_options[@]}"))
        fi
    fi
}

main() {
    tput civis
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
            a) select_all;;
            A) unselect_all;;
        esac

        erase
        draw
    done
}

main $1 $2
echo ${output[@]}
