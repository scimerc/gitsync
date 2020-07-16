#!/usr/bin/env bash
# exports a repository to a gzip-compressed tarball

# exit on error
set -ETeuo pipefail

[ "$*" != "" ] || { printf "Usage: %s <dir(s)>\n" ${BASH_SOURCE[0]}; exit 0; }

CWDIR=$(pwd)

LOCTMPDIR="${TMPDIR:-/tmp}"

PRJDIRS=( "$@" )

for k in ${!PRJDIRS[@]} ; do

  if [ ! -d "${PRJDIRS[$k]}/.git" ] ; then
    printf "No git repository in '%s': skipping..\n" "${PRJDIRS[$k]}"
    continue
  fi

  PRJDIRS[$k]=$( readlink -e ${PRJDIRS[$k]} )
  PRJNAME=$( basename ${PRJDIRS[$k]} )

  # calculate md5, but only use first 6 chars
  MD5=$(find ${PRJDIRS[$k]}/.git -type f | xargs cat | md5sum)
  MD5=${MD5:0:7}
  OUTFILENAME=${PRJNAME}_"$(date +"%y%m%d-%H")"_${MD5}.git.tar.gz
  if [ -f "${OUTFILENAME}" ] ; then
    echo -n "'${OUTFILENAME}' exists in the current directory ['${CWDIR}']: "
    if [[ $- == *i* ]] ; then
      read -p "Do you want to overwrite it?[Y/n]:" -n 1 -r
      echo
      if [[ ! $REPLY =~ ^([Yy]|)$ ]]; then
        return 0
      fi
    else
      echo -e "\nNon-interactive parent shell detected: skipping.."
      continue
    fi
  fi

  echo "Cloning source repository '${PRJDIRS[$k]}'..."
  cd ${LOCTMPDIR} && rm -rf "${PRJNAME}"
  git clone ${PRJDIRS[$k]} ${PRJNAME}

  echo "Compressing into '${PRJNAME}.git.tar.gz'..."
  tar czf ${PRJNAME}.git.tar.gz ${PRJNAME}

  mv ${PRJNAME}.git.tar.gz "${CWDIR}/${OUTFILENAME}"

  echo "Repository exported to '${CWDIR}/${OUTFILENAME}'."

  cd "${CWDIR}"

done

