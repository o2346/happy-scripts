#!/bin/bash

crap(){
  help() {
    printf "# CRAwl RePositories of git\n"
    printf "# Show some status of several git repos stored under parent directory recursively\n"
    printf "# Print if any subjects found such as uncommited changes or commits that was not pushed yet\n"
    printf "# Parent directory can be defined optionally. Default is ~/Documents\n"
    printf "\n"

    printf "usage: crap [ -c | -s | -h ] [ -d path ]\n"
    printf "no args  crawl \"~/Documents\"\n"
    printf "     -c  crawl current directory\n"
    printf "     -d  [path] crawl specific directory located at given path\n"
    printf "     -f  fetch repos with --dry-run. NOTE it require Netowork TRAFFIC and No commands except \"git fetch\" will be operated\n"
    printf "     -s  alias of \"git status -bs\"\n"
    printf "     -h  show this message\n"
  }

  CWD=$(pwd)

  PARENT=~/Documents
  FETCH=false

  while getopts cd:flshp OPT
  do
    case $OPT in
      d)  PARENT=$OPTARG
        ;;
      c)  PARENT=$CWD
        ;;
      l)  SHOWLINES=24
          echo "Newest ${SHOWLINES} lines below"
          git log --graph --decorate --oneline --all -$SHOWLINES
          return 0
        ;;
      s)  git status -bs
          return 0
        ;;
      h)  help
          return 0
        ;;
      f)  FETCH=true
        ;;
      p)  PULL=true
        ;;
      \?) help
          return 0
        ;;
    esac
  done

  for REPO in `find $PARENT -type d | grep -e ".git$"`; do
    cd `dirname $REPO`
    ST=`git status --porcelain`
    PUSH=`git status -bs | grep '\[ahead'`
    WD=`pwd`


    if [ "$FETCH" = "true" ]; then
      git fetch --dry-run
      continue
    fi

    if [ "$PULL" = "true" ]; then
      git pull | grep -v 'Already up to date.'
      continue
    fi

    if [ "${ST}" = "" -a "${PUSH}" = "" ] ; then
      continue
    fi

    printf "\e[29;1m`basename ${WD}`\e[m  \e[37;4m${WD}\e[m\n"

    if [ "${ST}" != "" -a "${PUSH}" = "" ] ; then
      git status -s
    fi

    if [ "${PUSH}" != "" ] ; then
      git status -bs
    fi

    printf "\n"
  done

  cd $CWD
}

crap $*
