# oldstty=$(stty -g)
# stty raw -echo min 0
# echo -en "\033[6n" > /dev/tty
# IFS=';' read -r -d R -a pos
# stty $oldstty
# row=$((${pos[0]:2} - 1))
# col=$((${pos[1]} - 1))
# echo "Row: ${row}"
# echo "Col: ${col}"
# echo -en "\E[6n"
# read -sdR current_line_info
# current_line_position=${current_line_info#*[}
# echo
# echo "${current_line_position}"
