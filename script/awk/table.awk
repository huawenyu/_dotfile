#!/usr/bin/awk -f
#
# Tested with GNU awk v4.2.1 and above
# [Link](https://gist.github.com/aayla-secura/147feaa7f5f8971ca37ace185af420b5)
#
# Copyright 2021 aayla-secura
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# A table is contained between the following lines:
# ~BEGIN FORMAT TABLE <title>~
# ...
# ~END FORMAT TABLE~
# <title> (and the space before it) can be omitted

# The table can have as many columns, separated by col_sep. Spaces are
# preserved. I.e. each line is as follows (note the lack of leading or
# trailing col_sep):
# <column 1><col_sep><column 2><col_sep><column 3>...

# The first line is the header.

# If any line consist of a single type_sep it is turned into a separator (a
# line long of repeated type_sep)

# The following characters are configurable (pass them using the -v
# option):
#  - characters affecting both input processing and output formatting:
#    - type_sep: used for middle borders where requested, see above
#      (default: -)
#    - col_sep: used for vertical borders (left, right and inter-column),
#      as well as splitting the input into columns (default: |)
#  - characters affecting output formatting only:
#    - border_sep: used for top and bottom borders (default: em dash or =
#      if no UTF-8 support)
#    - header_sep: used for the line under the header (default: border_sep)
#    - title_sep: used for padding the title on the left and right
#      (default: ~)

# Example input:
# ~BEGIN FORMAT TABLE title~
# foo|bar|baz
# 1|2|3
# -
# a|b|c
# |d
# ~END FORMAT TABLE~

#TODO: maximum width, and split the value over multiple lines if longer
# Reads input and prints each line as is except when inside a table.

function print_colored(width, value) {
  printf "%" width + (length(value) - length_colored(value)) "s", value
}

function length_colored(value, _plain_value) {
  _plain_value = gensub(/\x1b\[[0-9;]+m/, "", "g", value)
  return length(_plain_value)
}

function rep_char(n, char) {
  if (n <= 0 ) { return }
  return gensub(/ /, char, "g", sprintf("%" n "s", ""))
}

function print_table() {
  table_width = 1
  for (c = 1; c <= table["n_cols"]; c++) {
    table_width += table["widths"][c] + 3
  }

  # TITLE
  if (table["title"] != "") {
    pad_width["l"] = \
             int(( table_width - length_colored(table["title"]) - 2 ) / 2)
    pad_width["r"] = table_width - length_colored(table["title"]) - 2 \
             - pad_width["l"]
    print rep_char(pad_width["l"], title_sep) " " table["title"] " " \
          rep_char(pad_width["r"], title_sep)
  }

  #TABLE
  outer_sep_line = rep_char(table_width, border_sep)
  header_sep_line = col_sep rep_char(table_width - 2, header_sep) col_sep
  type_sep_line = gensub(header_sep, type_sep, "g", header_sep_line)
  print outer_sep_line

  for (l = 1; l <= table["n_lines"]; l++) {
    if (table["lines"][l]["sep"]) {
      print type_sep_line
      continue
    }

    for (c = 1; c <= table["n_cols"]; c++) {
      printf "%s ", col_sep
      print_colored(table["widths"][c], table["lines"][l][c])
      printf " "
    }
    print col_sep
    if (l == 1) { print header_sep_line }
  }
  print outer_sep_line

  reset_table()
}

function reset_table() {
  split("", table, ":")
  table["n_cols"] = 0
  table["n_lines"] = 0
}

BEGIN {
  if (border_sep == "") {
    border_sep = "\xe2\x80\x94"
    if (length(border_sep) > 1) {
      # no UTF-8 support
      border_sep = "="
    }
  }
  if (header_sep == "") { header_sep = border_sep }
  if (type_sep == "" ) { type_sep = "-" }
  if (title_sep == "" ) { title_sep = "~" }
  if (col_sep == "" ) { col_sep = "|" }
  inside_table = 1
}

match($0, /^~BEGIN FORMAT TABLE( (.*))?~$/, mArr) {
  table["title"] = mArr[2]
  inside_table = 1
  next
}

/^~END FORMAT TABLE~$/ {
  print_table()
  inside_table = 0
  next
}

(! inside_table) { print $0; next }

($0 == type_sep) {
  table["n_lines"]++
  table["lines"][table["n_lines"]]["sep"] = 1
  next
}

{ # save table
  n = split($0, tmpArr, col_sep)
  if (table["n_cols"] < n) { table["n_cols"] = n }
  table["n_lines"]++
  for (i in tmpArr) {
    table["lines"][table["n_lines"]][i] = tmpArr[i]
    # remove colors
    if (table["widths"][i] == "" ||
        table["widths"][i] < length_colored(tmpArr[i])) {
      table["widths"][i] = length_colored(tmpArr[i])
    }
  }
}

END {
  print_table()
}
