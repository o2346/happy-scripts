#!/bin/bash

tmpdir=`[ -d /dev/shm ] && mktemp -d /dev/shm/assert.XXXXXX || mktemp -d`
trap "rm -rf $tmpdir" 0 1 2 3

#mktemp At Exit
mktempae() {
  local tmp=`mktemp $tmpdir/assert.XXXXXX`
  echo $tmp
}

_diff=`mktempae`

# assert arg1 arg2
assert() {
  if [ -f "$1" ]; then
    diff $1 $2 > /dev/null
  else
    [ "$1" = "$2" ]
  fi

  local _is_affirmative=$?

  local _ok="\e[32;1m[_____ok]\e[m"
  local _failure="\e[31;1m[FAILURE]\e[m"

  if [ "$_is_affirmative" = 0 ]; then
    printf $_ok
  else
    printf $_failure
    local _1=`mktempae`
    local _2=`mktempae`
    local cmd=`[ -f "$1" ] && echo 'cat' || echo 'echo'`
    $cmd $1 > $_1
    $cmd $2 > $_2
    diff $_1 $_2 > $_diff
  fi
  return $_is_affirmative
}

. $1

exit_code=0

while read cmd; do
  #filter a func directly defined in arg script
  cat $1 | grep $cmd > /dev/null || continue

  $cmd
  is_affirmative=$?
  printf ' -- '$cmd'\n'
  [ "$is_affirmative" != 0 ] && cat $_diff >&2 && ((exit_code++))
done < <(set | grep -e '^on_' | awk '{print $1}')

exit $exit_code

#!/bin/bash
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
# on_func4() {
#   local a=`mktemp`
#   local b=`mktemp`
#   printf 'hoge' > $a
#   printf 'hoge' > $b
#   assert $a $b
# }
# 
