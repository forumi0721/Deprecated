#!/bin/bash

function CheckVersion {
	local retvalue=
	local pkgfile="${1}"
	local pkgdir="$(dirname "${pkgfile}")"

	#Check git
	unset pkgver
	unset source
	unset -f pkgver
	source "${pkgfile}"
	if [ -z "$(echo "${source[@]}" | grep "git+https:\/\/")" ] || [ -z "$(declare -f pkgver)" ]; then
		unset pkgver
		unset source
		unset -f pkgver
		return 0
	fi
	unset pkgver
	unset source
	unset -f pkgver

	echo "Package Path : ${pkgdir}"

	#Get current version
	if [ ! -e "${pkgfile}" ]; then
		echo "Cannot find PKGBUILD"
		return 1
	fi

	local pkgver1="$(grep '^pkgver=' "${pkgfile}" | cut -f 2 -d '=')"
	if [ -z "${pkgver1}" ]; then
		echo "Cannot get pkgver in PKGBUILD"
		return 1 
	fi

	#GetNewPkgversion
	pushd . &> /dev/null
	cd "${pkgdir}"

	echo "Get new version..."

	local lsotion=
	for file in $(ls)
	do
		lsoption+="-I ${file} "
	done
	
	makepkg --nobuild -Acdf &> /dev/null
	local pkgver2="$(grep '^pkgver=' PKGBUILD | cut -f 2 -d '=')"

	for file2 in $(ls ${lsoption})
	do
		rm -rf ${file2}
	done

	popd &> /dev/null

	echo "Done"

	#Check
	echo "Compare version..."

	if [ "${pkgver1}" = "${pkgver2}" ]; then
		retvalue=0
		echo "Already up-to-date."
	else
		retvalue=2
		echo "Update..."
	fi

	echo "Done"

	echo

	return ${retvalue}
}

UPDATE_LIST=
for src in $(find . -name PKGBUILD -type f)
do
	CheckVersion "${src}"
	if [ "$?" = "2" ]; then
		UPDATE_LIST+=("${src}")
	fi
done

if [ ! -z "${UPDATE_LIST}" ]; then
	echo "Update List"
	for update in ${UPDATE_LIST[@]}
	do
		echo "${update}"
	done
fi

exit 0

