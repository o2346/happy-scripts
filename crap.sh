#!/bin/bash

readonly which_git=`which git`
function git() {
 if [ "`pwd`" = "$HOME" -o "`pwd`" = "$HOME/.uc" ]; then
   $which_git --git-dir=$HOME/.uc --work-tree=$HOME $*
 else
   $which_git $*
 fi
}

crap(){
  readonly local PARENT=$HOME
  help() {
    printf "# CRAwl RePositories\n"
    printf "# Issue some git commands on recognized git repos under parent directory recursively\n"
    printf "# Parent directory for Default is $PARENT\n"
    printf "# With no args, 'git status' would issued respectively\n"
    printf "\n"
    printf "usage: crap -[cpPfh] [--list-all|--dry-run] [ -d path ]\n"
    printf "    no args recursive git status for \"$PARENT\"\n"
    printf "         -c indicate current directory for parent\n"
    printf "         -p batch pull\n"
    printf "         -P batch push\n"
    printf "         -d [path] crawl specific directory located at given path\n"
    printf "         -f batch fetch\n"
    printf " --list-all merely list all repos but would not do anything else\n"
    printf "  --dry-run for some operations\n"
    printf "         -h show this message\n"
  }

  print_repo() {
    printf "\e[29;1m`basename ${1}`\e[m  \e[37;4m${1}\e[m\n"
  }

  CWD=$(pwd)

  FETCH=false
  PUSH=false
  dry_run=''
  list_all=''
  diff=''

  #long options
  POSITIONAL=()
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      --dry-run)
        dry_run='--dry-run'
        shift # past argument
        ;;
      --list-all)
        list_all=0
        shift # past argument
        ;;
      --diff)
        diff=0
        shift # past argument
        ;;
      --reunionizer)
        reunionizer=0
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

  while getopts cd:flhpP OPT
  do
    case $OPT in
      d)  PARENT=$OPTARG
        ;;
      c)  PARENT=$CWD
        ;;
      l)  SHOWLINES=18
          echo "Newest ${SHOWLINES} lines below"
          git log --graph --decorate --all -$SHOWLINES
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

  if [ "${reunionizer}" = 0 ] ; then
    echo "#!/bin/bash"
  fi

  readonly ignore="$HOME/(.vim|.themes|.tmux|n-api-article|.cache)/"
  #https://stackoverflow.com/questions/11981716/how-to-quickly-find-all-git-repos-under-a-directory/12010862#12010862
  find $PARENT -name 'branches' -o -name '.git' -type d -prune 2>/dev/null | grep -Ev "$ignore" | while read REPO; do
    cd $REPO/..
    cd `dirname $REPO`
    #if [ "$PWD" = "$HOME/.uc" ]; then
    #  is_ahead="true"
    #  cd $HOME
    #fi
    ST=`git status --porcelain 2> /dev/null`
    is_ahead=`git status -bs 2> /dev/null | grep '\[ahead'`
    WD=`pwd`
    BASENAME=`basename $(pwd)`

    if [ "${list_all}" = 0 ] ; then
      print_repo ${WD}
      continue
    fi

    if [ "${reunionizer}" = 0 ] ; then
      cat ./.git/config | grep 'url =' | awk ' {print "git clone "$NF,"'${BASENAME}'"}'
      continue
    fi

    if [ "${diff}" = 0 ] ; then
      git --no-pager diff
      continue
    fi

    if [ "$FETCH" = "true" ]; then
      GIT_TERMINAL_PROMPT=0 git fetch $dry_run
      continue
    fi

    if [ "$PULL" = "true" ]; then
      GIT_TERMINAL_PROMPT=0 git pull | egrep -iv 'Already.up.to.date'
      [ "${PIPESTATUS[0]}" = "0" ] || echo "Potential changes found on remote of $REPO"
      continue
    fi

    if [ "${ST}" = "" -a "${is_ahead}" = "" ] ; then
      continue
    fi

    print_repo ${WD}

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

  if [ "${reunionizer}" = 0 ] ; then
    echo 'cpwd=`pwd`; ls $cpwd | while read repo; do cd $cpwd/$repo && git checkout develop; done; cd $cpwd'
  fi

  cd $CWD

  # Just an idea, it might be annoying though
  #if [ "$PUSH" = true -a -z "$dry_run" ]; then
  #  echo "recrapping if anthing remains.." >&2
  #  $0
  #fi
}

crap $*
