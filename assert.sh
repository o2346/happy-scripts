#!/bin/bash

_diff=`mktemp`

# assert arg1 arg2
assert() {
  [ "$1" = "$2" ]
  local _affirmative=$?
  #"\e[29;1m`basename ${WD}`\e[m  \e[37;4m${WD}\e[m\n"
  local _ok="\e[32;1m[_____ok]\e[m"
  local _failure="\e[31;1m[FAILURE]\e[m"
  [ "$_affirmative" = 0 ] && printf $_ok || printf $_failure
  if [ "$_affirmative" != 0 ]; then
    local _1=`mktemp`
    local _2=`mktemp`
    echo $1 > $_1
    echo $2 > $_2
    diff $_1 $_2 > $_diff
  fi
  return $_affirmative
}

. $1

set | grep 'on_' | awk '{print $1}' | while read cmd; do
  eval $cmd
  affirmative=$?
  printf ' -- '$cmd'\n'
  [ "$affirmative" != 0 ] && cat $_diff >&2
done

# test.sh
# #!/bin/bash
# on_func1() {
#   assert hoge fuga
# }
# on_func2() {
#   assert 2 2
# }
# on_func3() {
#   assert "`       \
#     echo hoge fuga\
#   `"              \
#   "`              \
#     echo hoge fuga\
#   `"
# }
