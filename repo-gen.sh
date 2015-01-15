#!/bin/sh

if [ -z "$(which repo-add 2> /dev/null)" ]; then
	echo "command not found : repo-add"
	exit 1
fi

rm -rf repo
archs=($(ls */*.pkg.tar.* | sed -e 's/^.*-//g' -e 's/\..*$//g' | sort -u | grep -v any))
for archdir in ${archs[@]}
do
	mkdir -p repo/${archdir}
done
for pkg in $(ls */*.pkg.tar.*)
do
	echo "Generate ${pkg}"
	arch=$(echo $pkg | sed -e 's/^.*-//g' -e 's/\..*$//g')
	if [ "${arch}" = "any" ]; then
		for archdir in ${archs[@]}
		do
			cp $pkg repo/${archdir}/
			pushd . &> /dev/null
			cd repo/${archdir}
			repo-add StoneCold.db.tar.gz "$(basename "${pkg}")"
			repo-add -f StoneCold.files.tar.gz "$(basename "${pkg}")"
			popd &> /dev/null
		done
	else
		cp $pkg repo/${arch}/
		pushd . &> /dev/null
		cd repo/${arch}
		repo-add StoneCold.db.tar.gz "$(basename "${pkg}")"
		repo-add -f StoneCold.files.tar.gz "$(basename "${pkg}")"
		popd &> /dev/null
	fi
done

if [ ! -e /media/StoneColdNAS/nas_htdocs ]; then
	if [ ! -z "$(which mnt)" ]; then
		mnt
	fi
fi

if [ -e /media/StoneColdNAS/nas_htdocs ]; then
	rm -rf /media/StoneColdNAS/nas_htdocs/arch/stonecold
	mkdir -p /media/StoneColdNAS/nas_htdocs/arch
	cp -r repo /media/StoneColdNAS/nas_htdocs/arch/stonecold
fi

