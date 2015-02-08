#!/bin/sh

function CheckVersion {
	local retvalue=
	local srcfile="${1}"
	local pkgdir="$(dirname "${srcfile}")"
	local pkgfile="${pkgdir}/PKGBUILD"

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

	#Import function
	echo "Import settings..."

	unset SOURCETYPE
	unset SOURCEPATH
	unset -f GetSourcePatch

	source ${srcfile}

	local sourcetype=${SOURCETYPE}
	local sourcepath=${SOURCEPATH}

	echo "Done"

	#GetSource
	echo "Get source..."

	local tempdir="$(mktemp -d)"
	local downloadpath="$(Download "${tempdir}" "${sourcetype}" "${sourcepath}")"
	if [ "$?" != "0" ]; then
		echo ${downloadpath}
		return 1
	fi

	echo "Done"

	#GetNewPkgversion
	echo "Get new version..."

	ProcessPkgVer "${downloadpath}"
	local pkgver2="$(GetNewVersion "${downloadpath}")"

	echo "Done"

	#Check
	echo "Compare version..."

	if [ "${pkgver1}" = "${pkgver2}" ]; then
		retvalue=0
		echo "Already up-to-date."
	else
		retvalue=2
		echo "Update..."
		cp -r ${downloadpath}.ORG/* ${pkgdir}/
		cp ${downloadpath}/PKGBUILD ${pkgdir}/
		if [ ! -z "$(declare -f GetSourcePatch)" ]; then
			echo "Apply patch..."
			pushd . &> /dev/null
			cd ${pkgdir}
			GetSourcePatch
			popd &> /dev/null
		fi
	fi

	echo "Done"

	#Cleanup
	echo "Cleanup..."
	rm -rf "${temp}"
	unset SOURCETYPE
	unset SOURCEPATH
	unset -f GetSourcePatch
	echo "Done"

	echo

	return ${retvalue}
}

function Download {
	local retvalue=
	local tempdir="${1}"
	local sourcetype="${2}"
	local sourcepath="${3}"
	local sourcefile="$(basename "${sourcepath}")"

	if [ "${sourcetype}" = "ABS" ]; then
		if [ ! -e "${sourcepath}" ]; then
			echo "Cannot find source"
			return 1
		fi
		cp -r "${sourcepath}" "${tempdir}/"
		pushd . &> /dev/null
		cd "${tempdir}"
		retvalue=$(ls -d */ | cut -d '/' -f 1)
		cp -r "${tempdir}/${retvalue}" "${tempdir}/${retvalue}.ORG"
		popd &> /dev/null
	elif [ "${sourcetype}" = "AUR" ]; then
		for cnt in {1..10}
		do
			wget "${sourcepath}" -O "${tempdir}/${sourcefile}" &> /dev/null
			if [ -e "${tempdir}/${sourcefile}" ]; then
				break;
			fi
		done
		if [ ! -e "${tempdir}/${sourcefile}" ]; then
			echo "Cannot get source"
			return 1
		fi
		pushd . &> /dev/null
		cd "${tempdir}"
		bsdtar -xf "${tempdir}/${sourcefile}"
		retvalue=$(ls -d */ | cut -d '/' -f 1)
		cp -r "${tempdir}/${retvalue}" "${tempdir}/${retvalue}.ORG"
		popd &> /dev/null
	else
		echo "Unknown source type"
		return 1
	fi

	echo "${tempdir}/${retvalue}"

	return 0
}

function ProcessPkgVer {
	local retvalue=
	local downloadpath="${1}"

	pushd . &> /dev/null
	cd "${downloadpath}"
	
	unset pkgver
	unset -f pkgver
	. ./PKGBUILD
	if [ ! -z "$(declare -f pkgver)" ]; then
		echo "Process makpkg..."
		makepkg --nobuild -Acdf &> /dev/null
		echo "Done"
	fi
	unset pkgver
	unset -f pkgver

	popd &> /dev/null

	return 0
}

function GetNewVersion {
	local retvalue=
	local downloadpath="${1}"

	pushd . &> /dev/null
	cd "${downloadpath}"
	
	retvalue="$(grep '^pkgver=' PKGBUILD | cut -f 2 -d '=')"
	popd &> /dev/null

	echo "${retvalue}"

	return 0
}

UPDATE_LIST=
for src in $(find . -name SOURCE)
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

