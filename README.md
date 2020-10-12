# <center>⌨️ Terminal Checkbox</center>

Bash script that creates interactive checkboxes (menu) for the terminal

![](demo/example.gif)

<br />

## Table of Contents

- [ Features ](#features)
- [ Option Usage ](#options-usage)
- [ Keybinds Usage ](#keybinds-usage)
- [ Limitations ](#limitations)

<br />

## Features

- Select only a option or multiple options
- Select or unselect multiple options easily
- Select all or unselect all
- Pagination
- Optional Vim keybinds
- Show selected options counter for multiple options
- Show custom message
- Show current option index and options amount
- Copy current option value to clipboard
- Help tab when press h or wrongly call the script
- Cooking: start with options selected
- Cooking: accept json from input via python script

<br />

## Options Usage

### <center>Show message on header

##### --message=""

![](demo/message.gif)

> The strings \a \b \c \e \f \n \r \t \v can be used <br />
> But maybe the layout will break, in this case resize the terminal and press 'r'

> You can customize message visual using ANSI colors code <br />
> But maybe the layout will break, in this case stop the script, run the command clear and than start script again
> Example: --message="\e[2K\e[31mhello world"

### <center>Return option(s) index instead of value(s)

##### --index

![](demo/index.gif)

### <center>Select multiple options and show selected counter

##### --multiple

![](demo/default_and_multiple.gif)

### <center>Options to render on checkboxes

##### --options=""

![](demo/example.gif)

> Any of this strings \a \b \c \e \f \n \r \t \v in any part of options will be removed <br />
> Example: --options="hello\nworld\c" will be 'helloworld'

> Must have one option per line <br />
> Example:
> --options="option 1 <br />
> option 2 <br />
> option 3 <br />
> option 4"

> If --options"" is missing sample options will be loaded with 30 options

<br />

### <center>Select current option

##### Press [SPACE] or 'x'

![](demo/space.gif)

## Keybinds Usage

### <center>Close and return selected options

##### Press [ENTER] or 'o'

![](demo/enter.gif)

### <center>Quit

##### Press [ESC] or 'q'

![](demo/esc.gif)

### <center>Move arround

##### Press [UP ARROW] or 'k' to move cursor to option above

##### Press [UP DOWN] or 'j' to move cursor to option below

![](demo/up_down_arrow.gif)

<br />

##### Press [PAGE UP] or 'd' to move cursor 5 options above

##### Press [PAGE DOWN] or 'u' to move cursor 5 options below

![](demo/page_up_down.gif)

<br />

##### Press [HOME] or 'g' to move cursor to first option

##### Press [END] or 'G' to move cursor to last option

![](demo/home_end.gif)

### <center>Copy

##### Press 'c' or 'y' to copy current option

![](demo/copy.gif)

### <center>Refresh

##### Press 'r' to refresh renderization

![](demo/refresh.gif)

### <center>Help

##### Press 'h' or call script with invalid argument, and a help page will appear

![](demo/help.gif)

<br />

### \* Keybinds for --multiple option

### <center>Select or Unselect All

##### Press 'a' to select all and 'A' to unselect all

![](demo/select_unselect_all.gif)

### <center>Select or Unselect Mode

##### Press 'v' to turn on/off select mode 'V' to turn on/off unselect mode

![](demo/select_unselect_mode.gif)

> If select mode is on. Cursor will be green and when you navigate the options will be selected

> If unselect mode is on. Cursor will be red and when you navigate the options will be unselected

<br />
<br />

## Limitations

- The script uses the command 'clear'
- The script uses bash array
- Terminal must have +8 lines for the script works
- When message has customizations like colors or line break, the script doesn't validate the terminal size well
- The script don't have any test until now
