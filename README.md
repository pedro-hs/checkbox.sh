### ⌨️ checkbqox.sh

[![Bash](https://img.shields.io/badge/language-Bash-green.svg)](https://github.com/pedro-hs/checkbox.sh/blob/master/checkbox.sh) [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/pedro-hs/terminal-checkbox.sh/master/LICENSE.md)

Interactive checkboxes (menu) with pagination and vim keybinds for bash

![](example/demo.gif)

<br /><br />

### Table of Contents

- [ Features ](#features)
- [ Arguments Usage ](#arguments-usage)
- [ Keybinds Usage ](#keybinds-usage)
- [ Limitations ](#limitations)

<br />
<br />

### Features

- Select only a option or multiple options
- Select or unselect multiple options easily
- Select all or unselect all
- Pagination
- Optional Vim keybinds
- A .sh file with approximately 500 lines
- Start with options selected
- Show selected options counter for multiple options
- Show custom message
- Show current option index and options amount
- Copy current option value to clipboard
- Help tab when press h or wrongly call the script

<br />
<br />

### Arguments Usage

##### Checkbox options

Use the argument `--options=""`

You can add new options:

- With the character `|`

![](example/options/options_separator.gif)

<br />

- With new line

![](example/options/options_new_line.gif)

<br />

- Mixed

![](example/options/options_mixed.gif)

<br />

To start with options selected, put `+` in first character of the option

- If the argument --multiple is missing, just the first option marked with + will start selected

![](example/options/options_start_seleted.gif)

<br />

Any of this ASCII signs `\a \b \c \e \f \n \r \t \v` in any part of options will be removed.

![](example/options/options_ascii.gif)

<br />

If --options"" is missing. Sample options will be loaded with 30 options.

![](example/options/no_options.gif)

<br />

---

##### Show message on header

Use the argument `--message=""`

![](example/message.gif)

You can customize message

- Using ANSI <br />
  Example: `--message="\e[2K\e[31mhello world"`
  <br /><br />
- Using ASCII `\a \b \c \e \f \n \r \t \v` <br />
  Example: `--message="hello\rworld"`

- Maybe the layout breaks, in this case, try to refresh (press `r`)

<br />

---

##### Select multiple options

Use the argument `--multiple`

![](example/multiple.gif)

<br />

---

##### Return index instead of values

Use the argument `--index`

![](example/index.gif)

<br />

### Keybinds Usage

##### Move arround

Press `[UP ARROW]` or `'k'` to move cursor to option above

Press `[UP DOWN]` or `'j'` to move cursor to option below

![](example/keys/up_down.gif)

<br />

Press `[PAGE UP]` or `'d'` to move cursor 5 options above

Press `[PAGE DOWN]` or `'u'` to move cursor 5 options below

![](example/keys/page_up_down.gif)

<br />

Press `[HOME]` or `'g'` to move cursor to first option

Press `[END]` or `'G'` to move cursor to last option

![](example/keys/home_end.gif)

<br />

---

##### Select current option

Press `[SPACE]` or `x`

![](example/keys/confirm.gif)

<br />

---

##### Close and return selected options

Press `[ENTER]` or `'o'`

![](example/keys/confirm.gif)

<br />

---

##### Select or Unselect All (only with --multiple)

Press `'a'` to select all and `'A'` to unselect all

![](example/all.gif)

<br />

---

##### Select or Unselect Mode (only with --multiple)

Press `'v'` to turn on/off select mode `'V'` to turn on/off unselect mode

![](example/select_unselect.gif)

- If select mode is on. Cursor will be green and when you navigate the options will be selected

- If unselect mode is on. Cursor will be red and when you navigate the options will be unselected

<br />

---

##### Quit

Press `[ESC]` or `'q'`

![](example/keys/quit.gif)

<br />

---

##### Copy

Press `'c'` or `'y'` to copy current option

![](example/copy.gif)

<br />

---

##### Refresh

Press `'r'` to refresh renderization

![](example/refresh.gif)

<br />

---

##### Help

Press `'h'` or call script with invalid argument, and a help page will appear

![](example/help.gif)

<br />
<br />

### Limitations

- The script uses the command 'clear'
- The script uses bash array
- Terminal must have +8 lines for the script works (except for customizations in --mesage="", maybe the layout breaks)
- The script don't have any test until now
