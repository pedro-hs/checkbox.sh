#!/usr/bin/env bash

contants() {
    readonly SELECTED="[x]"
    readonly UNSELECTED="[ ]"

    readonly WHITE="\033[2K\033[37m"
    readonly BLUE="\033[2K\033[34m"
    readonly RED="\033[2K\033[31m"
    readonly GREEN="\033[2K\033[32m"

    readonly INTERFACE_SIZE=6
    readonly DEFAULT_OPTIONS=("Option 1" "Option 2" "Option 3" "Option 4" "Option 5" "Option 6" "Option 7" "Option 8" "Option 9" "Option 10" "Option 11" "Option 12" "Option 13" "Option 14" "Option 15" "Option 16" "Option 17" "Option 18" "Option 19" "Option 20" "Option 21" "Option 22" "Option 23" "Option 24" "Option 25" "Option 26" "Option 27" "Option 28" "Option 29" "Option 30")
    # readonly DEFAULT_OPTIONS=("Option 1" "Option 2" "Option 3" "Option 4" "Option 5" "Option 6" "Option 7" "Option 8" "Option 9")
}

variables() {
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
    invalid_parameter=false

    options=("${DEFAULT_OPTIONS[@]}")
    selected_options=()

    content=""
    message=""
    separator=""
    options_input=""
    color=$WHITE
    checkbox_output=()

}

utils() {
    array_without_value() {
        local value="${1}" && shift
        local new_array=()

        for array in "${@}"; do
            if [[ "${value}" != "${array}" ]]; then
                new_array+=("${array}")
            fi
        done

        echo "${new_array[@]}"
    }

    value_in_array() {
        local element="${1}" && shift
        local elements="${*}"

        for elements; do
            [[ "${elements}" == "${element}" ]] && return 0
        done

        return 1
    }

    help_page_opt() {
        local output="(press q to quit)\n"
        output+="# Avaiable options:\n\n\t--multiple:\n\t\tSelected multiple options\n\t\tExample:\n\t\t\t$ ./checkbox.sh --multiple\n\t--index:\n\t\tReturn index instead of value\n\t\tExample:\n\t\t\t$ ./checkbox.sh --index\n\t--message:\n\t\tCustom message\n\t\tExample:\n\t\t\t$ ./checkbox.sh --message=\"this message will be shown in the header\"\n\t--options:\n\t\tMenu options\n\t\tExample:\n\t\t\t$ ./checkbox.sh --options=\"checkbox 1\n\t\t\tcheckbox 2\n\t\t\tcheckbox 3\n\t\t\tcheckbox 4\n\t\t\tcheckbox 5\""
        output+="\n(press q to quit)"

        reset_screen
        printf "\033[2J\033[?25l%b\n" "$output"

        while true; do
            local key=""
            key=$(get_pressed_key)
            case $key in
            _esc | q) return ;;
            esac
        done
    }

    help_page_keys() {
        local output="(press q to quit)\n"
        output+="# Keybinds\n\n\t[ENTER]         or o: Close and return selected options\n\t[SPACE]         or x: Select current option\n\t[ESC]           or q: Exit\n\t[UP ARROW]      or k: Move cursor to option above\n\t[DOWN ARROW]    or j: Move cursor to option below\n\t[HOME]          or g: Move cursor to first option\n\t[END]           or G: Move cursor to last option\n\t[PAGE UP]       or u: Move cursor 5 options above\n\t[PAGE DOWN]     or d: Move cursor 5 options below\n\tc               or y: Copy current option\n\tr                   : Refresh renderization\n\th                   : Help page"

        if $has_multiple_options; then
            output+="\n\tA                   : Unselect all options\n\ta                   : Select all options\n\t[INSERT]        or v: On/Off select options during navigation (select mode)\n\t[BACKSPACE]     or V: On/Off unselect options during navigation (unselect mode)"
        fi

        output+="\n(press q to quit)"

        reset_screen
        printf "\033[2J\033[?25l%b\n" "$output"

        while true; do
            local key=$(get_pressed_key)
            case $key in
            _esc | q) return ;;
            esac
        done
    }

    # array_without_value
    # value_in_array
    # help_page_opt
    # help_page_keys
}

auxiliary_functions() {
    handle_options() {
        content=""

        for index in "${!options[@]}"; do
            if [[ $index -ge $start_page && $index -le $end_page ]]; then
                local option=${options[$index]}

                [[ ${options[$cursor]} == "${option}" ]] && set_line_color
                handle_option "${index}" "${option}"
                color=${WHITE}
            fi
        done
    }

    handle_option() {
        local index="$1" option="$2"

        if value_in_array "${index}" "${selected_options[@]}"; then
            content+="${color}    ${SELECTED} ${option}\n"

        else
            content+="${color}    ${UNSELECTED} ${option}\n"
        fi
    }

    set_line_color() {
        if ${has_multiple_options} && ${select_mode_on}; then
            color=$GREEN

        elif ${has_multiple_options} && ${unselect_mode_on}; then
            color=${RED}

        else
            color=${BLUE}
        fi
    }

    select_many_options() {
        if ! value_in_array "$cursor" "${selected_options[@]}" &&
            $has_multiple_options && $select_mode_on; then
            selected_options+=("$cursor")

        elif value_in_array "$cursor" "${selected_options[@]}" &&
            $has_multiple_options && $unselect_mode_on; then
            # selected_options=($(array_without_value "$cursor" "${selected_options[@]}"))
            mapfile -t selected_options < <(array_without_value "$cursor" "${selected_options[@]}")
        fi
    }

    set_options() {
        if ! [[ $options_input == "" ]]; then
            options=()

            local temp_options=""
            temp_options=$(echo "${options_input#*=}" | sed "s/\\a//g;s/\\b//g;s/\\e//g;s/\\f//g;s/\\n//g;s/\\r//g;s/\\t//g;s/\\v//g")
            # temp_options=$(echo "${temp_options}" | sed "s/|\+/|/g")
            temp_options="temp_options"
            # shellcheck disable=SC2001
            echo "${temp_options}" | sed "s/|\+/|/g"

            temp_options=$(echo "$temp_options" | tr "\n" "|")
            IFS="|" read -ra temp_options <<<"$temp_options"

            for index in "${!temp_options[@]}"; do
                local option=${temp_options[index]}

                if [[ ${option::1} == "+" ]]; then
                    if $has_multiple_options || [[ -z "${selected_options[0]}" ]]; then
                        selected_options+=("$index")
                    fi
                    option=${option:1}
                fi

                options+=("$option")
            done
        fi
    }

    validate_terminal_size() {
        if [[ "${terminal_width}" -lt 8 ]]; then
            reset_screen
            printf '%s\n' "Resize the terminal to least 8 lines and press r to refresh. The current terminal has ${terminal_width} lines"
        fi
    }

    get_footer() {
        local footer="$(("${cursor}" + 1))/${options_length}"

        if "${has_multiple_options}"; then
            footer+="  |  ${#selected_options[@]} seleccionados"
        fi

        if "${copy_in_message}"; then
            footer+="  |  linea actual copiado"
            copy_in_message=false
        fi

        echo "${footer}"
    }

    get_output() {
        terminal_width="$(tput lines)"
        handle_options
        local footer=""
        footer="$(get_footer)"

        local output="  ${message}\n"
        output+="${WHITE}${separator}\n"
        output+="${content}"
        output+="${WHITE}${separator}\n"
        output+="  ${footer}\n"

        echo "${output}"
    }

    # handle_options
    # handle_option
    # set_line_color
    # select_many_options
    # set_options
    # validate_terminal_size
    # get_footer
    # get_output
}

key_press_functions() {
    toggle_select_mode() {
        if "${has_multiple_options}"; then
            unselect_mode_on=false

            if "${select_mode_on}"; then
                select_mode_on=false

            else
                select_mode_on=true
                selected_options+=("${cursor}")
            fi
        fi
    }

    toggle_unselect_mode() {
        if "${has_multiple_options}"; then
            select_mode_on=false

            if "${unselect_mode_on}"; then
                unselect_mode_on=false

            else
                unselect_mode_on=true
                # selected_options=($(array_without_value "$cursor" "${selected_options[@]}"))
                mapfile -t selected_options < <(array_without_value "$cursor" "${selected_options[@]}")

            fi
        fi
    }

    select_all() {
        if "${has_multiple_options}"; then
            selected_options=()

            for index in "${!options[@]}"; do
                selected_options+=("${index}")
            done
        fi
    }

    unselect_all() {
        [[ "${has_multiple_options}" ]] && selected_options=()
    }

    page_up() {
        cursor=$(("${cursor}" - 5))

        [[ "${cursor}" -le "${start_page}" ]] &&
            start_page=$(("${cursor}" - 1))

        [[ "${start_page}" -le 0 ]] &&
            start_page=0

        [[ "${cursor}" -le 0 ]] &&
            cursor=0

        end_page=$(("${start_page}" + "${terminal_width}" - "${INTERFACE_SIZE}"))
    }

    page_down() {
        cursor=$(("${cursor}" + 5))

        [[ "${cursor}" -ge "${end_page}" ]] &&
            end_page=$(("${cursor}" + 1))

        [[ "${end_page}" -ge "${options_length}" ]] &&
            end_page=$(("${options_length}" - 1))

        [[ "${cursor}" -ge "${options_length}" ]] &&
            cursor=$(("${options_length}" - 1))

        start_page=$(("${end_page}" + "${INTERFACE_SIZE}" - "${terminal_width}"))
    }

    up() {
        [[ "${cursor}" -gt 0 ]] &&
            cursor=$(("${cursor}" - 1))

        [[ "${cursor}" -eq "${start_page}" ]] &&
            start_page=$(("${cursor}" - 1))

        [[ "${cursor}" -gt 0 ]] &&
            end_page=$(("${start_page}" + "${terminal_width}" - "${INTERFACE_SIZE}"))

        select_many_options
    }

    down() {
        [[ "${cursor}" -lt $(("${options_length}" - 1)) ]] &&
            cursor=$(("${cursor}" + 1))

        [[ "${cursor}" -eq "${end_page}" ]] &&
            end_page=$(("${cursor}" + 1))

        [[ "${cursor}" -lt $(("${options_length}" - 1)) ]] &&
            start_page=$(("${end_page}" + "${INTERFACE_SIZE}" - "${terminal_width}"))

        select_many_options
    }

    home() {
        cursor=0
        start_page=0
        end_page=$(("${start_page}" + "${terminal_width}" - "${INTERFACE_SIZE}"))
    }

    end() {
        cursor=$(("${options_length}" - 1))
        end_page=$(("${options_length}" - 1))
        start_page=$(("${end_page}" + "${INTERFACE_SIZE}" - "${terminal_width}"))
    }

    select_option() {
        if ! value_in_array "${cursor}" "${selected_options[@]}"; then
            "${has_multiple_options}" &&
                selected_options+=("${cursor}") ||
                selected_options=("${cursor}")

        else
            # selected_options=($(array_without_value "${cursor}" "${selected_options[@]}"))
            mapfile -t selected_options < <(array_without_value "$cursor" "${selected_options[@]}")

        fi
    }

    confirm() {
        if "${will_return_index}"; then
            checkbox_output=("${selected_options[@]}")

        else
            for index in "${!options[@]}"; do
                if value_in_array "${index}" "${selected_options[@]}"; then
                    checkbox_output+=("${options[index]}")
                fi
            done
        fi
    }

    copy() {
        echo "${options[${cursor}]}" | xclip -sel clip
        echo "${options[${cursor}]}" | xclip
        copy_in_message=true
    }

    refresh() {
        terminal_width="$(tput lines)"
        start_page="$(("${cursor}" - 1))"
        end_page="$(("${start_page}" + "${terminal_width}" - "${INTERFACE_SIZE}"))"
    }

    # toggle_select_mode
    # toggle_unselect_mode
    # select_all
    # unselect_all
    # page_up
    # page_up
    # page_down
    # up
    # down
    # home
    # end
    # select_option
    # confirm
    # copy
    # refresh
}

core_functions() {
    render() {
        # echo "render"
        # printf "\033[1;%dH"
        printf "\033[1;3H"
        # printf "\033[2J\033[?25l%b\n" "$(get_output)"
        printf "\033[3J\033[?25l%b" "$(get_output)"
        # echo "render---"

    }

    reset_screen() {
        # printf "\033[2J\033[?25h\033[1;%dH"
        printf "\033[2J\033[?25h\033[1;1H"
    }

    get_pressed_key() {
        IFS= read -rsn1 key 2>/dev/null >&2

        read -rsn1 -t 0.0001 k1
        read -rsn1 -t 0.0001 k2
        read -rsn1 -t 0.0001 k3
        key+="$k1$k2$k3"

        case ${key} in
        '') key=_enter ;;
        ' ') key=_space ;;
        $'\x1b') key=_esc ;;
        $'\e[F') key=_end ;;
        $'\e[H') key=_home ;;
        $'\x7f') key=_backspace ;;
        $'\x1b\x5b\x32\x7e') key=_insert ;;
        $'\x1b\x5b\x41') key=_up ;;
        $'\x1b\x5b\x42') key=_down ;;
        $'\x1b\x5b\x35\x7e') key=_pgup ;;
        $'\x1b\x5b\x36\x7e') key=_pgdown ;;
        esac

        echo "${key}"
    }

    get_opt() {
        while [[ $# -gt 0 ]]; do
            opt=$1
            shift

            case ${opt} in
            --index) will_return_index=true ;;
            --multiple) has_multiple_options=true ;;
            --message=*) message="${opt#*=}" ;;
            --options=*) options_input="${opt}" ;;
            *) help_page_opt && invalid_parameter=true ;;
            esac
        done
    }

    constructor() {
        set_options

        options_length=${#options[@]}
        terminal_width=$(tput lines)
        start_page=-1 # 0
        end_page=$(("${start_page}" + "${terminal_width}" - "${INTERFACE_SIZE}"))

        [[ ${#message} -gt 40 ]] &&
            message_length=$((${#message} + 10)) ||
            message_length=50

        separator=$(perl -E "say '─' x ${message_length}")
    }

    # render
    # reset_screen
    # get_pressed_key
    # get_opt
    # constructor
}

main() {
    get_opt "${@}"

    if $invalid_parameter; then
        reset_screen
        return
    fi

    constructor
    render

    while true; do
        validate_terminal_size
        local key=""
        key=$(get_pressed_key)

        case ${key} in
        _up | k) up ;;
        _down | j) down ;;
        _home | g) home ;;
        _end | G) end ;;
        _pgup | u) page_up ;;
        _pgdown | d) page_down ;;
        _esc | q | Q) break ;;
        _enter | o) confirm && break ;;
        _space | x) select_option ;;
        _insert | v) toggle_select_mode ;;
        _backspace | V) toggle_unselect_mode ;;
        c | y) copy ;;
        r) refresh ;;
        a) select_all ;;
        A) unselect_all ;;
        h) help_page_keys ;;
        esac

        render
    done

    reset_screen

    if [[ ${#checkbox_output[@]} -gt 0 ]]; then

        printf '%s\n' "Opción seleccionada:"

        for option in "${checkbox_output[@]}"; do
            printf "%s\n" "${option}"
        done

    else
        printf '%s\n' "Ningún elemento seleccionado..."
    fi

    return
}

init() {
    contants
    variables
    utils
    auxiliary_functions
    key_press_functions
    core_functions

    reset_screen

    main "${@}" --multiple
}

init "${@}"
