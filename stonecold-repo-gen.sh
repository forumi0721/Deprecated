#!/bin/sh

if [ -z "$(which repo-add 2> /dev/null)" ]; then
	echo "command not found : repo-add"
	exit 1
fi

REPO_NAME="StoneCold"
LOCAL_REPO="stonecold-repo"
TARGET_ARCH=("x86_64" "armv7h")
RSYNC_ID=forumi0721
RSYNC_SVR=192.168.0.21
RSYNC_PATH=/mnt/VOL1/nas_htdocs/arch/stonecold

rm -rf "${LOCAL_REPO}"
for arch in ${TARGET_ARCH[@]}
do
	mkdir -p "${LOCAL_REPO}/${arch}"
done

for pkg in $(find . -name *.pkg.tar.gz -o -name *.pkg.tar.bz2 -o -name *.pkg.tar.xz -o -name *.pkg.tar.lrz -o -name *.pkg.tar.lzo -o -name *.pkg.tar.Z)
do
	echo "$(basename "${pkg}") (${pkg})"
	arch=$(echo "${pkg}" | sed -e 's/^.*-//g' -e 's/\..*$//g')
	if [ "${arch}" != "any" ] && [ -z "$(echo "${TARGET_ARCH[@]}" | grep -w "${arch}")" ]; then
		echo "Skip - Not in target arch (${TARGET_ARCH[@]})"
		continue
	fi

	if [ "${arch}" = "any" ]; then
		for target in ${TARGET_ARCH[@]}
		do
			cp "${pkg}" "${LOCAL_REPO}/${target}/"
			pushd . &> /dev/null
			cd "${LOCAL_REPO}/${target}"
			repo-add ${REPO_NAME}.db.tar.gz "$(basename "${pkg}")"
			repo-add -f ${REPO_NAME}.files.tar.gz "$(basename "${pkg}")"
			popd &> /dev/null
		done
	else
		cp "${pkg}" "${LOCAL_REPO}/${arch}"
		pushd . &> /dev/null
		cd "${LOCAL_REPO}/${arch}"
		repo-add ${REPO_NAME}.db.tar.gz "$(basename "${pkg}")"
		repo-add -f ${REPO_NAME}.files.tar.gz "$(basename "${pkg}")"
		popd &> /dev/null
	fi
done

if [ -z "$(which rsync)" ]; then
	echo "Cannot found rsync"
	exit 0
fi


echo "rsync start..."
rsync -avrh --progress ${LOCAL_REPO}/* ${RSYNC_ID}@${RSYNC_SVR}:${RSYNC_PATH}
echo "Done"
echo

