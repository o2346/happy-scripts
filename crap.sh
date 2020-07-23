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
  PUSH=false
  dry_run=''

  #long options
  POSITIONAL=()
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      --dry-run)
        dry_run='--dry-run'
        shift # past argument
        ;;
      *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
  done
  set -- "${POSITIONAL[@]}" # restore positional parameters
  #https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

  while getopts cd:flshpP OPT
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
      P)  PUSH=true
        ;;
      \?) help
          return 0
        ;;
      *)
        ;;
    esac
  done


  for REPO in `find $PARENT -type d | grep -e ".git$"`; do
    cd `dirname $REPO`
    ST=`git status --porcelain`
    is_ahead=`git status -bs | grep '\[ahead'`
    WD=`pwd`


    if [ "$FETCH" = "true" ]; then
      git fetch --dry-run
      continue
    fi

    if [ "$PULL" = "true" ]; then
      git pull | egrep -iv 'Already.up.to.date'
      [ "${PIPESTATUS[0]}" = "0" ] || echo "which: $REPO"
      continue
    fi

    if [ "${ST}" = "" -a "${is_ahead}" = "" ] ; then
      continue
    fi

    printf "\e[29;1m`basename ${WD}`\e[m  \e[37;4m${WD}\e[m\n"

    if [ "${ST}" != "" -a "${is_ahead}" = "" ] ; then
      git status -s
    fi

    if [ "${is_ahead}" != "" ] ; then
      git status -bs
    fi

    if [ "$PUSH" = true ]; then
      git push $dry_run
    fi

    printf "\n"
  done

  cd $CWD
}

crap $*
