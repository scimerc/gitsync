#!/usr/bin/env bash

# exit on error
set -ETeuo pipefail

declare -r MAXFILESIZE=50 #MB
declare -r BRANCH_DEF='master'
declare BRANCH=$BRANCH_DEF
declare -r PUBREPNAME_DEF='origin'
declare PUBREPNAME=$PUBREPNAME_DEF

if [ "$*" == "" ] ; then
  cat << EOF
no public repository specified.
usage: $( basename ${BASH_SOURCE[0]} ) \
[-b <branch='$BRANCH_DEF'>] \
[-n <name='$PUBREPNAME_DEF'>] \
<path_to_repository>
 e.g.: $( basename ${BASH_SOURCE[0]} ) https://github.com/scimerc/myrepo.git
EOF
  exit 0
fi

while getopts "b:n:" opt; do
case "${opt}" in
  n)
    BRANCH="${OPTARG}"
    echo "branch set to: ${BRANCH}"
    ;;
  n)
    PUBREPNAME="${OPTARG}"
    echo "remote repository name set to: ${PUBREPNAME}"
    ;;
esac
done
shift $((OPTIND-1))

PUBREP="$1"
PRJDIR="$( cd $( dirname $( readlink -e "${BASH_SOURCE[0]}" ) )/../ ; pwd )"

cd ${PRJDIR}

lflist=$( find . -type f -size +${MAXFILESIZE}M -not -path '*.git*' )

if [ "${lflist}" != "" ] ; then

  echo 'adding large files support..'

  git lfs track ${lflist}
  git add .gitattributes ${lflist}
  git commit -m 'lfs' || true

fi

echo 'committing and pushing changes to remote..'

git add .
git remote -v | grep -qw "${PUBREPNAME}" || git remote add ${PUBREPNAME} ${PUBREP}
git pull ${PUBREPNAME} ${BRANCH}
git commit -m 'merge with remote'
git push -u ${PUBREPNAME}
git push

