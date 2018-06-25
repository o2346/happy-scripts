#!/bin/bash

# assert arg1 arg2
assert() {
 [ "$1" = "$2" ] && printf '    ok' || printf 'FAILED'
}

. $1

set | grep 'on_' | awk '{print $1}' | while read cmd; do
  eval $cmd
  printf ' -- '$cmd'\n'
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
