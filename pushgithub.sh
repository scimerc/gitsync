#!/usr/bin/env bash

# exit on error
set -ETeuo pipefail

declare -r MAXFILESIZE=50 #MB
declare -r BRANCH_DEF='master'
declare BRANCH=$BRANCH_DEF
declare -r PUBREPNAME_DEF='origin'
declare PUBREPNAME=$PUBREPNAME_DEF
declare -r PUBREP_DEF='file://tmp'
declare PUBREP=$PUBREP_DEF

if [ "$*" == "" ] ; then
  cat << EOF
No repository specified.

USAGE:  $( basename ${BASH_SOURCE[0]} ) [OPTIONS] <path_to_repository>

OPTIONS:
  -b <branch='$BRANCH_DEF'>
  -n <name='$PUBREPNAME_DEF'>
  -r <remote='$PUBREP_DEF'

e.g.:
$( basename ${BASH_SOURCE[0]} ) -r https://github.com/scimerc myrepo
will push to the remote github https://github.com/scimerc/myrepo[.git]
EOF
  exit 0
fi

while getopts "b:n:r:" opt; do
case "${opt}" in
  n)
    BRANCH="${OPTARG}"
    echo "Branch set to: ${BRANCH}"
    ;;
  n)
    PUBREPNAME="${OPTARG}"
    echo "Remote repository name set to: ${PUBREPNAME}"
    ;;
  n)
    PUBREP="${OPTARG}"
    echo "Remote repository address set to: ${PUBREP}"
    ;;
esac
done
shift $((OPTIND-1))

CWDIR=$(pwd)

for PRJDIR in "$@" ; do

  cd ${PRJDIR}
  
  echo -e "\n${PRJDIR}:"

  if [ ! -d .git ] ; then
    printf "No git repository in '%s': skipping..\n" "${PRJDIR}"
    cd ${CWDIR}
    continue
  fi

  if [ -n "$( git status --porcelain )" ] ; then
    printf "Unclean repository in '%s': skipping..\n" "${PRJDIR}"
    cd ${CWDIR}
    continue
  fi

  lflist=$( find . -type f -size +${MAXFILESIZE}M -not -path '*.git*' )

  if [ "${lflist}" != "" ] ; then

    echo 'Adding large files support..'

    git lfs track ${lflist}
    git add .gitattributes ${lflist}
    git commit -m 'lfs' || true

  fi

  echo 'Committing and pushing changes to remote..'

  git add .
  if git remote -v | grep -qw "${PUBREPNAME}" ; then
    echo "Ignoring [${PUBREPNAME}]'${PUBREP}', as ${PRJDIR} already has a remote by that name."
    git remote set-branches --add ${PUBREPNAME} ${BRANCH}
  else
    echo "Adding [${PUBREPNAME}]'${PUBREP}' remote to repository ${PRJDIR}."
    git remote add -t ${BRANCH} ${PUBREPNAME} ${PUBREP}
  fi
  git pull ${PUBREPNAME} ${BRANCH}
  git commit -m 'merge with remote'
  git push -u ${PUBREPNAME}
  git push
  
  cd ${CWDIR}

  echo

done

