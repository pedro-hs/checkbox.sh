#!/usr/bin/env bash
#===============================================================================
#NAME
#  terminal_checkbox.sh
#
#DESCRIPTION
#  Creates interactive checkboxes (menu) for the terminal
#  For more info look the README.md on <https://github.com/pedro-hs/terminal-checkbox>
#  Features:
#    - Select only a option or multiple options
#    - Select or unselect multiple options easily
#    - Select all or unselect all
#    - Pagination
#    - Optional Vim keybinds
#    - Show selected options counter for multiple options
#    - Show custom message
#    - Show current option index and options amount
#    - Copy current option value to clipboard
#    - Help tab when press h or wrongly call the script
#    - Cooking: start with options selected
#    - Cooking: accept json from input via python script
#
#SOURCE
#  <https://github.com/pedro-hs/terminal-checkbox>
#
#INSPIRED BY
#  <https://gist.github.com/blurayne/f63c5a8521c0eeab8e9afd8baa45c65e>
#  <https://www.bughunter2k.de/blog/cursor-controlled-selectmenu-in-bash>
#
#===============================================================================
# CONTANTS
#===============================================================================
readonly SELECTED="[x]"
readonly UNSELECTED="[ ]"

readonly WHITE="\e[2K\e[37m"
readonly BLUE="\e[2K\e[34m"
readonly RED="\e[2K\e[31m"
readonly GREEN="\e[2K\e[32m"

readonly INTERFACE_SIZE=6
readonly DEFAULT_OPTIONS=("Option 1" "Option 2" "Option 3" "Option 4" "Option 5" "Option 6" "Option 7" "Option 8" "Option 9" "Option 10" "Option 11" "Option 12" "Option 13" "Option 14" "Option 15" "Option 16" "Option 17" "Option 18" "Option 19" "Option 20" "Option 21" "Option 22" "Option 23" "Option 24" "Option 25" "Option 26" "Option 27" "Option 28" "Option 29" "Option 30")

#===============================================================================
# VARIABLES
#===============================================================================
cursor=0
options_length=0
terminal_width=0
start_page=0
end_page=0

has_multiple_options=false
will_return_index=false
unselect_mode_on=false
select_mode_on=false
copy_in_message=false

options=("${DEFAULT_OPTIONS[@]}")
selected_options=()

content=""
message=""
separator=""
color=$WHITE

#===============================================================================
# UTILS
#===============================================================================
value_in_array() {
    local element=$1
    shift
    local elements=$@

    for elements; do
        [[ $elements == $element ]] && return 0
    done

    return 1
}

array_without_value() {
    local value=$1
    shift
    local new_array=()

    for array in ${@}; do
        if [[ $value != $array ]]; then
            new_array+=("$array")
        fi
    done

    echo "${new_array[@]}"
}

help_page_opt() {
    clear
    echo -e "(press q to quit)\n"

    echo -e "# Avaiable options:

    --multiple:
    \tSelected multiple options
    \tExample:
    \t\t$ ./terminal_checkbox.sh --multiple

    --index:
    \tReturn index instead of value\n\tExample:\n\t\t$ ./terminal_checkbox.sh --index

    --message:
    \tCustom message\n\tExample:\n\t\t$ ./terminal_checkbox.sh --message=\"this message will be shown in the header\"

    --options:
    \tMenu options\n\tExample:\n\t\t$ ./terminal_checkbox.sh --options=\"checkbox 1\n\t\tcheckbox 2\n\t\tcheckbox 3\n\t\tcheckbox 4\n\t\tcheckbox 5\""

    echo -e "\n(press q to quit)"

    while true; do
        local key=$( get_pressed_key )
        case $key in
            _esc|q) clear && exit && return;;
        esac
    done
}

help_page_keys() {
    clear
    echo -e "(press q to quit)\n"

    echo -e "# Keybinds

    \t[ENTER]         or o: Close and return selected options
    \t[SPACE]         or x: Select current option
    \t[ESC]           or q: Exit
    \t[UP ARROW]      or k: Move cursor to option above
    \t[DOWN ARROW]    or j: Move cursor to option below
    \t[HOME]          or g: Move cursor to first option
    \t[END]           or G: Move cursor to last option
    \t[PAGE UP]       or u: Move cursor 5 options above
    \t[PAGE DOWN]     or d: Move cursor 5 options below
    \tc               or y: Copy current option
    \tr                   : Refresh renderization
    \th                   : Help page"

    if $has_multiple_options; then
        echo "
        A                   : Unselect all options
        a                   : Select all options
        [INSERT]        or v: On/Off select options during navigation (select mode)
        [BACKSPACE]     or V: On/Off unselect options during navigation (unselect mode)"
    fi

    echo -e "\n(press q to quit)"

    while true; do
        local key=$( get_pressed_key )
        case $key in
            _esc|q) clear && return;;
        esac
    done
}

#===============================================================================
# AUXILIARY FUNCTIONS
#===============================================================================
handle_options() {
    content=""

    for index in ${!options[@]}; do
        if [[ $index -ge $start_page && $index -le $end_page ]]; then
            local option=${options[$index]}
            [[ ${options[$cursor]} == $option ]] && set_line_color

            handle_option "$index" "$option"
            color=$WHITE
        fi
    done
}

handle_option() {
    local index=$1 option=$2

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
    options=()
    options=$( echo "${opt#*=}" | sed 's/\\a//g;s/\\b//g;s/\\c//g;s/\\e//g;s/\\f//g;s/\\n//g;s/\\r//g;s/\\t//g;s/\\v//g' )
    readarray -t lines <<<"$options"
    options=("${lines[@]}")
}

validate_terminal_size() {
    [[ $terminal_width -lt 8 ]] \
        && clear \
        && echo "Resize the terminal to least 8 lines and press r to refresh. The current terminal has $terminal_width lines"
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
        if $has_multiple_options; then
            selected_options+=("$cursor")

        else
            selected_options=("$cursor")
        fi

    else
        selected_options=($( array_without_value "$cursor" "${selected_options[@]}" ))
    fi
}

confirm() {
    local output=()

    if $will_return_index; then
        output=${selected_options[@]}

    else
        for index in ${!options[@]}; do
            if value_in_array "$index" "${selected_options[@]}"; then
                output+=("${options[index]}")
            fi
        done
    fi

    clear
    echo -e "Selected:\n"

    for item in "${output[@]}"; do
        echo "$item"
    done

    echo
}

copy() {
    echo "${options[$cursor]}" | xclip -sel clip
    echo "${options[$cursor]}" | xclip
    copy_in_message=true
}

refresh() {
    terminal_width=$( tput lines )
    start_page=$(( $cursor - 1 ))
    end_page=$(( $start_page + $terminal_width - $INTERFACE_SIZE ))
}

#===============================================================================
# CORE FUNCTIONS
#===============================================================================
render() {
    terminal_width=$( tput lines )
    handle_options
    footer="$(( $cursor + 1 ))/$options_length"

    if $has_multiple_options; then
        footer+="  |  ${#selected_options[@]} selected"
    fi

    if $copy_in_message; then
        footer+="  |  current line copied"
        copy_in_message=false
    fi

    clear
    echo -en "  $message\n"
    echo -en "$WHITE"
    echo -en "$separator\n"
    echo -en "$content"
    echo -en "$WHITE"
    echo -en "$separator\n"
    echo -en "  $footer\n"
}

get_pressed_key() {
    IFS= read -sN1 key 2>/dev/null >&2

    read -sN1 -t 0.0001 k1
    read -sN1 -t 0.0001 k2
    read -sN1 -t 0.0001 k3
    key+="$k1$k2$k3"

    case $key in
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

    echo "$key"
}

get_opt() {
    while [[ $# -gt 0 ]]; do
        opt=$1
        shift

        case $opt in
            --index) will_return_index=true;;
            --multiple) has_multiple_options=true;;
            --message=*) message="${opt#*=}";;
            --options=*) set_options;;
            *) help_page_opt;;
        esac
    done
}

constructor() {
    options_length=${#options[@]}
    terminal_width=$( tput lines )
    start_page=0
    end_page=$(( $start_page + $terminal_width - $INTERFACE_SIZE ))
    message_length=${#message}

    local default_length=40
    if $has_multiple_options; then
        default_length=50
    fi

    if [[ $message_length -gt $default_length ]]; then
        separator=$( perl -E "say '-' x $(( $message_length + 10 ))" )

    else
        separator=$( perl -E "say '-' x $default_length" )
    fi
}

#===============================================================================
# MAIN
#===============================================================================
main() {
    get_opt "$@"
    constructor
    render

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
            _esc|q) clear && exit && return;;
            _enter|o) confirm && return;;
            _space|x) select_option;;
            _insert|v) toggle_select_mode;;
            _backspace|V) toggle_unselect_mode;;
            c|y) copy;;
            r) refresh;;
            a) select_all;;
            A) unselect_all;;
            h) help_page_keys;;
        esac

        render
    done
}

main "$@"
