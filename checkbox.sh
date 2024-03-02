#!/usr/bin/env bash
#===============================================================================
#SOURCE
#  <https://github.com/pedro-hs/checkbox.sh>
#
#DESCRIPTION
#  Create customizable checkbox for the terminal
#  Check out how to use on README.md at <https://github.com/pedro-hs/checkbox.sh>
#
#===============================================================================
# CONTANTS
#===============================================================================
readonly SELECTED="[x]"
readonly UNSELECTED="[ ]"

readonly ANSI_ESCAPE="\033"
readonly WHITE="${ANSI_ESCAPE}[37m"
readonly BLUE="${ANSI_ESCAPE}[34m"
readonly RED="${ANSI_ESCAPE}[36m"
readonly GREEN="${ANSI_ESCAPE}[32m"

INTERFACE_SIZE=6
SAMPLE_OPTIONS=("Option 1" "Option 2" "Option 3" "Option 4" "Option 5" "Option 6" "Option 7" "Option 8" "Option 9" "Option 10" "Option 11" "Option 12" "Option 13" "Option 14" "Option 15" "Option 16" "Option 17" "Option 18" "Option 19" "Option 20" "Option 21" "Option 22" "Option 23" "Option 24" "Option 25" "Option 26" "Option 27" "Option 28" "Option 29" "Option 30")

#===============================================================================
# VARIABLES
#===============================================================================
cursor=0
options_length=0
terminal_width=0
start_page=0
end_page=0

has_multiple_options=false
has_index_result=false
unselect_mode_on=false
select_mode_on=false
show_copy_message=false
show_help=false

options=("${SAMPLE_OPTIONS[@]}")
selected_options=()

content=""
message=""
separator=""
options_input=""
color=$WHITE
checkbox_output=()

#===============================================================================
# HANDLE ARRAY
#===============================================================================
array_without_value() {
    local value="$1" && shift
    local new_array=()

    for array in ${@}; do
        if [[ $value != $array ]]; then
            new_array+=("$array")
        fi
    done

    echo "${new_array[@]}"
}

value_in_array() {
    local element="$1" && shift
    local elements="$@"

    for elements; do
        [[ $elements == $element ]] && return 0
    done

    return 1
}

#===============================================================================
# HELP PAGE
#===============================================================================
help_page() {
    local output="# Arguments:\n\t--multiple: Select multiple => ./checkbox.sh --multiple\n\t--index: Get selected index => ./checkbox.sh --index\n\t--message: A custom message => ./checkbox.sh --message=\"lorem ipsum\"\n\t--options: The options list => ./checkbox.sh --options=\"item 1|item 2\"\n"
    output+="\n# Keybinds:\n\t[UP/DOWN ARROWS], [HOME/END], [PAGE UP/DOWN] or k/j, g/G, u/d: Move cursor\n\to or [ENTER]: Close and return selected options\n\tx or [SPACE]: Select current option\n\tq or [ESC]: Exit\n\ty or c: Copy current option\n\tr: Refresh renderization\n\tA: Unselect all options (need --multiple)\n\ta: Select all options (need --multiple)\n\tv or [INSERT]: Select options while moving cursor (need --multiple)\n\tV or [BACKSPACE]: Unselect options while moving cursor (need --multiple)\n(press q to quit)"

    printf "$output"

    quit_help_page
}

quit_help_page() {
    while true; do
        local key=$( get_pressed_key )
        case $key in
            _esc|q) return;;
        esac
    done
}

#===============================================================================
# CHECKBOX
#===============================================================================
render_options() {
    content=""

    for index in ${!options[@]}; do
        if [[ $index -ge $start_page && $index -le $end_page ]]; then
            local option=${options[$index]}

            [[ ${options[$cursor]} == $option ]] && set_line_color
            render_option "$index" "$option"
            color=$WHITE
        fi
    done
}

render_option() {
    local index="$1" option="$2"

    if value_in_array "$index" "${selected_options[@]}"; then
        content+="$color    $SELECTED $option\n"

    else
        content+="$color    $UNSELECTED $option\n"
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

select_many_options() {
    if ! value_in_array "$cursor" "${selected_options[@]}" \
        && $has_multiple_options && $select_mode_on; then
            selected_options+=("$cursor")

        elif value_in_array "$cursor" "${selected_options[@]}" \
            && $has_multiple_options && $unselect_mode_on; then
                    selected_options=($( array_without_value "$cursor" "${selected_options[@]}" ))
    fi
}

set_options() {
    if [[ $options_input == "" ]]; then
        return
    fi

    options=()

    local escaped_options=$( escape_options_ascii_signs )
    local lines=$( echo "$escaped_options" | tr "\n" "|" )
    IFS="|" read -a lines <<< "$lines"

    for index in ${!lines[@]}; do
        local option=${lines[index]}

        if [[ ${option::1} == "+" ]]; then
            if $has_multiple_options || [[ -z $selected_options ]]; then
                selected_options+=("$index")
            fi
            option=${option:1}
        fi

        options+=("$option")
    done
}

escape_options_ascii_signs() {
    local ascii_signs=("a" "b" "f" "n" "r" "t")
    local ascii_signs_escape=$(printf "s/\\\\\%s//g;" "${ascii_signs[@]}")
    echo $( echo "${options_input#*=}" | sed $ascii_signs_escape )
}

validate_terminal_size() {
    if [[ $terminal_width -lt 8 ]]; then
        printf "Resize the terminal to least 8 lines and press r to refresh. The current terminal has $terminal_width lines"
    fi
}

get_footer() {
    local footer="$(( $cursor + 1 ))/$options_length"

    if $has_multiple_options; then
        footer+="  |  ${#selected_options[@]} selected"
    fi

    if $show_copy_message; then
        footer+="  |  current line copied"
        show_copy_message=false
    fi

    echo "$footer"
}

render_checkbox() {
    terminal_width=$( tput lines )

    render_options

    local output=""

    if [[ $message != "" ]]; then
        output+="  $message\n$WHITE$separator"
    fi
    output+="\n"
    output+="$content"
    output+="$WHITE$separator\n"

    local footer="$( get_footer )"
    output+="  $footer\n"

    printf "$output"
}

clear_checkbox() {
    local header_footer_lines=3;
    local checkbox_lines=$((${#options[@]} + $header_footer_lines))
    local delete_lines_above="${ANSI_ESCAPE}[${checkbox_lines}A"

    printf "$delete_lines_above"
}

render_result() {
    if [[ ${#checkbox_output[@]} -gt 0 ]]; then
        for option in "${checkbox_output[@]}"; do
            echo "$option"
        done
    fi
}
#===============================================================================
# KEY PRESS FUNCTIONS
#===============================================================================
toggle_select_mode() {
    if $has_multiple_options; then
        unselect_mode_on=false

        if $select_mode_on; then
            select_mode_on=false

        else
            select_mode_on=true
            if ! value_in_array "$cursor" "${selected_options[@]}"; then
                selected_options+=("$cursor")
            fi
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
            selected_options=($( array_without_value "$cursor" "${selected_options[@]}" ))
        fi
    fi
}

select_all() {
    if $has_multiple_options; then
        selected_options=()

        for index in ${!options[@]}; do
            selected_options+=(${index})
        done
    fi
}

unselect_all() {
    [[ $has_multiple_options ]] && selected_options=()
}

page_up() {
    cursor=$(( $cursor - 5 ))

    [[ $cursor -le $start_page ]] \
        && start_page=$(( $cursor - 1 ))

    [[ $start_page -le 0 ]] \
        && start_page=0

    [[ $cursor -le 0 ]] \
        && cursor=0

    end_page=$(( $start_page + $terminal_width - $INTERFACE_SIZE ))
}

page_down() {
    cursor=$(( $cursor + 5 ))

    [[ $cursor -ge $end_page ]] \
        && end_page=$(( $cursor + 1 ))

    [[ $end_page -ge $options_length ]] \
        && end_page=$(( $options_length - 1 ))

    [[ $cursor -ge $options_length ]] \
        && cursor=$(( $options_length - 1 ))

    start_page=$(( $end_page + $INTERFACE_SIZE - $terminal_width ))
}

up() {
    [[ $cursor -gt 0 ]] \
        && cursor=$(( $cursor - 1 ))

    [[ $cursor -eq $start_page ]] \
        && start_page=$(( $cursor - 1 ))

    [[ $cursor -gt 0 ]] \
        && end_page=$(( $start_page + $terminal_width - $INTERFACE_SIZE ))

    select_many_options
}

down() {
    [[ $cursor -lt $(( $options_length - 1 )) ]] \
        && cursor=$(( $cursor + 1 ))

    [[ $cursor -eq $end_page ]] \
        && end_page=$(( $cursor + 1 ))

    [[ $cursor -lt $(( $options_length - 1 )) ]] \
        && start_page=$(( $end_page + $INTERFACE_SIZE - $terminal_width ))

    select_many_options
}

home() {
    cursor=0
    start_page=0
    end_page=$(( $start_page + $terminal_width - $INTERFACE_SIZE ))
}

end() {
    cursor=$(( $options_length - 1 ))
    end_page=$(( $options_length - 1 ))
    start_page=$(( $end_page + $INTERFACE_SIZE - $terminal_width ))
}

select_option() {
    if ! value_in_array "$cursor" "${selected_options[@]}"; then
        $has_multiple_options \
            && selected_options+=("$cursor") \
            || selected_options=("$cursor")

    else
        selected_options=($( array_without_value "$cursor" "${selected_options[@]}" ))
    fi
}

confirm() {
    if $has_index_result; then
        checkbox_output="${selected_options[@]}"

    else
        for index in ${!options[@]}; do
            if value_in_array "$index" "${selected_options[@]}"; then
                checkbox_output+=("${options[index]}")
            fi
        done
    fi
}

copy() {
    echo "${options[$cursor]}" | xclip -sel clip
    echo "${options[$cursor]}" | xclip
    show_copy_message=true
}

refresh() {
    terminal_width=$( tput lines )
    start_page=$(( $cursor - 1 ))
    end_page=$(( $start_page + $terminal_width - $INTERFACE_SIZE ))
}

#===============================================================================
# BASE FUNCTIONS
#===============================================================================
get_pressed_key() {
    IFS= read -sn1 key 2>/dev/null >&2

    read -sn1 -t 0.0001 k1
    read -sn1 -t 0.0001 k2
    read -sn1 -t 0.0001 k3
    key+="$k1$k2$k3"

    case $key in
        '') key=_enter;;
        ' ') key=_space;;
        $'\x1b') key=_esc;;
        $'\e[F') key=_end;;
        $'\e[H') key=_home;;
        $'\x7f') key=_backspace;;
        $'\x1b\x5b\x32\x7e') key=_insert;;
        $'\x1b\x5b\x41') key=_up;;
        $'\x1b\x5b\x42') key=_down;;
        $'\x1b\x5b\x35\x7e') key=_pgup;;
        $'\x1b\x5b\x36\x7e') key=_pgdown;;
    esac

    echo "$key"
}

get_arguments() {
    while [[ $# -gt 0 ]]; do
        opt=$1
        shift

        case $opt in
            --index) has_index_result=true;;
            --multiple) has_multiple_options=true;;
            --message=*) message="${opt#*=}";;
            --options=*) options_input="$opt";;
            --help) show_help=true;;
            *) show_help=true;;
        esac
    done
}

constructor() {
    set_options

    options_length=${#options[@]}
    terminal_width=$( tput lines )
    start_page=0
    end_page=$(( $start_page + $terminal_width - $INTERFACE_SIZE ))

    [[ ${#message} -gt 40 ]] \
        && message_length=$(( ${#message} + 10 )) \
        || message_length=50

    separator=$( perl -E "say '-' x $message_length" )
}

#===============================================================================
# MAIN
#===============================================================================
main() {
    get_arguments "$@"

    if $show_help; then
        help_page
        printf "\n"
        return
    fi

    constructor
    render_checkbox

    while true; do
        validate_terminal_size
        local key=$( get_pressed_key )

        case $key in
            _up|k) up;;
            _down|j) down;;
            _home|g) home;;
            _end|G) end;;
            _pgup|u) page_up;;
            _pgdown|d) page_down;;
            _esc|q) break;;
            _enter|o) confirm && break;;
            _space|x) select_option;;
            _insert|v) toggle_select_mode;;
            _backspace|V) toggle_unselect_mode;;
            c|y) copy;;
            r) refresh;;
            a) select_all;;
            A) unselect_all;;
        esac

        clear_checkbox
        render_checkbox
    done

    render_result
}

main "$@"
