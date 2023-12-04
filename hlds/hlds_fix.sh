#!/bin/sh
#Patching Linux hlds on Debian Bookworm on 11/26/2023 -SPINX

#Error:./libstdc++.so.6: version `CXXABI_1.3.8' not found (required by /home/myuserid/Steam/steamapps/common/Half-Life/filesystem_stdio.so)
#email debug.log to linux@valvesoftware.com

#Run this in the Half-Life root directory (where valve, gearbox, cstrike, etc. directories reside)

TEST_LIB=filesystem_stdio.so

test_ldd_local() {
	LANG=C LD_LIBRARY_PATH=. ldd -v "$1"
}

#This function returns SUCCESS if it does find the problem!
error_ldd_dependencies() {
	#Usually we get error messages matching this pattern: "version \`(GCC|CXXABI)_[0-9.]*' not found",
	#but matching for simply "not found" finds missing .so file too.
	test_ldd_local "${TEST_LIB}" 2>&1 | grep -qP "not found"
}

if ! which ldd grep > /dev/null
then
	printf "Mandatory tools missing! Requirements: grep, ldd, which.\n"
	exit 1
fi

if [ ! -f "${TEST_LIB}" ]
then
	printf "The %s file does not exist, ensure you are in the Half-Life root directory!\n" "${TEST_LIB}"
	exit 1
fi

printf "Checking ABI dependencies of %s...\n" "${TEST_LIB}"
test_ldd_local "${TEST_LIB}"

#Check if installation is affected
if ! error_ldd_dependencies
then
	printf "\nThe library dependencies of %s file can be resolved successfully, no action required.\n" "${TEST_LIB}"
	exit 0
fi

printf "\nTrying to remove local libstdc++.so.6 and libgcc_s.so.1...\n"
rm -v libstdc++.so.6 libgcc_s.so.1

if ! error_ldd_dependencies
then
	printf "\nFixed!\n"
else
	printf "\n%s\n%s\n%s\n\n" \
		"Local installations of libstdc++.so.6 and libgcc_s.so.1 have been removed, but the dependencies of" \
		"${TEST_LIB} still can't be resolved. You might need to install these packages:" \
		"sudo apt install libc6:i386 libgcc-s1:i386 libstdc++6:i386"
	exit 1
fi
