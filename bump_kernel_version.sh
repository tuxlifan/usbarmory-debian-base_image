#!/usr/bin/env bash

#
# Dependencies:
#   bash, echo, git, grep, sed, tail, wc
#   sort with --version-sort (-V)
#

MAKEFILE=Makefile.config

if [ "$(git diff --exit-code --staged)" ]; then
    echo "Something is staged already. Bailing out!"
    exit 1
fi
if [ "$(git diff --exit-code ${MAKEFILE})" ]; then
    echo "${MAKEFILE} has been modified. Bailing out!"
    exit 1
fi
if [ "x$(git symbolic-ref --short HEAD)" != "xmaster" ]; then
    echo "Not on master branch. Bailing out!"
    exit 1
fi

if [ -z $1 ]; then
    read -p "Please enter the new version number: " VERSION
else
    VERSION="$1"
fi
LINUX_VER=$(grep LINUX_VER ${MAKEFILE}|cut -d= -f2)

if [ "x${VERSION}" == "x${LINUX_VER}" ]; then
    echo "Version number already in ${MAKEFILE}. Nothing to do."
    exit 0
fi
if [ "x${VERSION}" != "x$(echo -e "${VERSION}\n${LINUX_VER}"|sort --version-sort|tail -n1)" ]; then
    echo "Your version number is not newer. Bailing out!"
    exit 1
fi

sed -i -e '/^LINUX_VER=/s#=.*$#='${VERSION}'#' ${MAKEFILE}
git add ${MAKEFILE}

if [ "1" != "$(git diff --staged|grep '^+[^+]'|wc -l)" ]; then
    echo "Something went wrong with 'sed' and 'git add'. More than one line changed! Bailing out!"
    exit 1
fi

git commit -m "Bump kernel version to ${VERSION}" -o ${MAKEFILE}

echo "All done. Now you can 'make linux'"
