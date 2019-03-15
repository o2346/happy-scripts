#!/bin/bash

# ICOL - Issue COntrOLLer Light
# Issue management system inspired from Redmine. Git based

top_dir=~/Documents
[ `git rev-parse --show-toplevel 2> /dev/null` ] && local_dir=`git rev-parse --show-toplevel` || local_dir=$top_dir

help() {
  echo "ICOL - Issue COntrOLLer Light"
  echo "Issue management system inspired from Redmine. Git based"
  echo ""
  echo "[ISSUE_ID]    if valid id was given, vi the target file & other options below will be ignored"
  echo "-h            show this help"
  echo "-n [TITLE]    create new issue file"
  echo "-p            browse issues which state was new or in progress. "
  echo "-P            upper case option"
  echo "-e            browse issues which state was end"
  echo "-E            upper case option"
  echo "-a            browse every issues no matter what kind of state they were"
  echo "-A            upper case option"
  echo "-s [KEYWORD]  search issues. [KEYWORD] will be grepped"
  echo "-S [KEYWORD]  upper case option"
  echo "-l [ISSUE_ID] find location of issue file"
  echo "NO OPTION     same as -P"
  echo ""
  echo "about lowercase browsing options: If current dir was a repo the one is the target."
  echo "  Works same as uppercase instead"
  echo "about uppercase options:  sweep issues in the all git repos recursively under $top_dir"
  echo "  filtered by same conditions as it's lowercase option"
  echo "note: It's designed for one-man project. If you have got several members in your group or something, you may want to use proper management system instead of this"
  return 0
}

# http://takafumi-s.hatenablog.com/entry/2017/12/12/230143
if [ "$(uname)" = "Darwin" ]; then
  shopt -s expand_aliases
  alias sed='gsed'
fi

get_directories() {
  for _repo in `find $1 -type d | grep .git`; do
    local _target=`echo $_repo | sed -e 's/\.git/docs\/issues/'`
    if [ -d $_target ]; then
      echo $_target
    fi
  done
  return 0
}

get_files() {
  for _repo in $1; do
    find $_repo -type f | grep .md
  done
  return 0
}

get_item() {
  grep "$2" $1 | sed -e "s/$2//" | sed -e 's/<.*>//' | sed -e 's/|//g'
}

get_status() {
  local re="^|Status|"
  get_item $1 $re | sed -e 's/in\sprogress/ipg/' | sed -e 's/\s*//g'
}

get_duedate() {
  local re="^|Due\sdate|"
  [ -z "`get_item $1 $re`" ] && echo "0000-00-00" || get_item $1 $re
}

get_category() {
  local re="^|Category|"
  get_item $1 $re
}

get_subject() {
  echo `head -1 $1 | sed -e 's/^.*\s\-\s//'`
}

get_gitroot() {
  local _basename=`echo $1 | sed -e 's/\/docs\/issues//'`
  echo `basename ${_basename}`/
}

get_id() {
  local _id=`basename $1 .md | grep '^[0-9a-z]\\{4\\}$'`
  [ -z $_id ] && printf "" || printf "#$_id "
}

get_locate() {
  find ~/Documents/ -name $1.md
}

# colorize due date
colorize() {
  local color="\e[29;m"
  local today=`date "+%Y%m%d"`
  local argdate=`echo $1 | sed -e 's/-//g'`
  if [ $today -gt $argdate ]; then
    color="\e[31;1m"
  elif [ $(expr $argdate - $today) -le 3 ]; then
    color="\e[33;2m"
  fi
  echo $color
}

summary() {
  local _id=`basename $1 .md`
  local _st=`get_status $1`
  local _st_color="\e[m"
  local _date=`get_duedate $1`
  local _date_color=`colorize $_date`
  local _color_end="\e[m"
  printf "\e[0m$_id\e[0m $_st_color$_st$_color_end $_date_color$_date$_color_end `get_gitroot $2` `get_category $1` `get_subject $1`\n"
  return 0
}

browse() {
  for _repos in `get_directories $1`; do
    for _file in `get_files $_repos`; do
      if [ -z "`grep -e "$2" $_file`" ]; then
        continue
      fi
      summary $_file $_repos
      if [ ${FUNCNAME[1]} = "search_keyword" ];then
        grep -e "$2" $_file
      fi
    done
  done
}

# overlook issue files
browse_inprogress() {
  browse $1 "^|Status|New\|^|Status|in progress"
  return 0
}

browse_end() {
  browse $1 "^|Status|end"
  return 0
}

browse_all() {
  browse $1 "^"
  return 0
}


search_keyword() {
  browse $1 $2
  return 0
}
# issue id gen
isidgen() {
  LANG=c < /dev/urandom tr -dc a-z0-9 | head -c${1:-4};echo
}

#update all files like missing info
update() {
  return 0
}

new() {
  echo arg=$*
  local isid=`isidgen`
  if [ `git rev-parse --show-toplevel` ]; then
    local repo=`git rev-parse --show-toplevel`
  else
    local repo=`mktemp -d`
  fi
  local docsdir=$repo/docs; [ ! -e $docsdir ] && mkdir -p $docsdir
  local issuedir=$docsdir/issues; [ ! -e $issuedir ] && mkdir -p $issuedir
  local file=$issuedir/$isid.md
  echo "# #$isid - $*" >> $file
  echo "" >> $file
  echo "|**Issue**||" >> $file
  echo "|---|---|" >> $file
  echo "|Status|New<!-- any of \"new\", \"in progress\", \"end\" http://redmine.jp/tech_note/issue_statuses/ -->|" >> $file
  echo "|Priority|Normal<!-- \"high\" or \"normal\" or \"low\"-->|" >> $file
  echo "|Assignee|owner<!-- your name -->|" >> $file
  echo "|Category|<!-- optional -->|" >> $file
  echo "|Target version|<!-- optional, any of git tags recommended -->|" >> $file
  echo "|Start date|$(date "+%Y-%m-%d")|" >> $file
  echo "|Due date||" >> $file
  echo "|estimated|hours|" >> $file
  echo "|% Done|0%|" >> $file
  echo "|worked|hours|" >> $file
  echo "" >> $file
  echo "## Description" >> $file
  echo "" >> $file
  echo "## Related to" >> $file
  echo "" >> $file
  echo "|**ID**|**Subject**|" >> $file
  echo "|---|---|" >> $file
  echo "|||<!--``OTHER_ISSUE;;-->">> $file
  echo "" >> $file
  echo "## History" >> $file
  echo "" >> $file
  echo "---" >> $file
  echo "*this document has been generated & accessed from computer program, named \"icol\"*" >> $file
  vi $file
}

test () {
  echo "get_directories"
  get_directories $top_dir
  echo "get_files"
  for _repos in `get_directories $top_dir`; do
    get_files $_repos
  done
  echo "browse"
  browse $top_dir "^$"
  echo "browse_inprogress"
  browse_inprogress $top_dir
  echo "browse_end"
  browse_end $top_dir
  echo "browse_all"
  browse_all $top_dir
  echo "search_keyword"
  search_keyword $top_dir "漏水事故"
  echo "icol -P"
  main -P
  return 0
}

_find() {
  local file=`find $top_dir -name $1.md`
  if [ -z "$file" ]; then
    return 1
  fi
  cd `dirname $file`
  vi $file
  return 0
}

# main
main() {
  local IDRE="^[0-9a-z]{4}$"
  if [[ $1 =~ $IDRE ]]; then
    _find $1
    return 0
  fi

  while getopts hnpPeEaAs:S:ti:l: OPT
  do case $OPT in
      h) help
        return 0
        ;;
      n) new `echo $* | sed -e 's/^.*\-n//'`
        return 0
        ;;
      p) browse_inprogress $local_dir
        return 0
        ;;
      P) browse_inprogress $top_dir
        return 0
        ;;
      e) browse_end $local_dir
        return 0
        ;;
      E) browse_end $top_dir
        return 0
        ;;
      a) browse_all $local_dir
        return 0
        ;;
      A) browse_all $top_dir
        return 0
        ;;
      s) search_keyword $local_dir $OPTARG
        return 0
        ;;
      S) search_keyword $top_dir $OPTARG
        return 0
        ;;
      t) test
        return 0
        ;;
      i) get_id $OPTARG
        return 0
        ;;
      l) get_locate $OPTARG
        return 0
        ;;
  esac done
  [ $# -eq 0 ] && browse_inprogress $top_dir
  return 0
}

main $*
