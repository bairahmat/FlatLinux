#!/bin/bash
echo -en "Note: the system requirements to install FlatLinux are the following:\nBash-3.2\nBinutils-2.17 (versions greater than 2.24 are not recommended because they have not been tested)\nBison-2.3 (/usr/bin/yacc should be a link to Bison)\nBzip2-1.0.4\nCoreutils-6.9\nDiffutils-2.8.1\nFindutils-4.2.31\nGawk-4.0.1 (/usr/bin/awk should be a link to Gawk)\nGCC-4.1.2 including g++ (versions greater than 4.9.1 are not recommended as they have not been tested)\nGlibc-2.5.1 (versions greater than 2.20 are not recommended because they have not been tested)\nGrep-2.5.1a\nGzip-1.3.12\nLinux Kernel-2.6.32\nM4-1.4.10\nMake-3.81\nPatch-2.5.4\nPerl-5.8.8\nSed-4.1.5\nTar-1.18\nXz-5.0.0\nYou will need to manually check these dependicies before continuing.\nContinue? (y/n)"
read CONTINUE
if [ "$CONTINUE" = "n" ]
then
	exit
fi
echo -en "Which device would you like to install FlatLinux on?"
read DEVICE
echo "Where is $DEVICE mounted? Press enter if it is not mounted."
read LOC
if [ "$LOC" = "" ]
then
	echo "Where would you like to mount $DEVICE?"
	read LOC
	echo "Attempting to mount ${DEVICE}..."
	MOUNTERR=`mount $DEVICE $LOC`
	if [ "$?" -ne "0" ]
	then
		echo "Error occurred mounting $DEVICE with error code ${?}."
		exit
	fi
fi
if [ "$LOC" = "/" ]
then
	echo "This script will not install on /."
	exit
fi
mountpoint -q $LOC
if [ "$?" -ne "0" ]
then
	echo "$LOC is not a mountpoint."
	exit
fi
# If the script gets here, $LOC is where we should install it on.
echo -e "All data on $LOC will be erased and unrecoverable. You should move all important files to another location.\nAre you ready to have all files erased?(y/n)"
read confirmDelete
if [ $confirmDelete = "n" ]
then
	exit
fi
echo "Deleting all data at ${LOC}..."
dataDir="`pwd`"
cd $LOC
if [ "$?" -ne "0" ]
then
	echo "Changing to ${LOC} failed with exit code ${?}."
	exit
fi
touch test
rm -r *
if [ "$?" -ne "0" ]
then
	echo "Removing files failed with exit code ${?}."
	exit
fi
# The partition is empty now.
cp -r "${dataDir}/" .
if [ "$?" -ne "0" ]
then
	echo "Copying needed files failed with exit code ${?}."
	exit
fi
mkdir "${LOC}/tools"
if [ "$?" -ne "0" ]
then
	echo "mkdir ${LOC}/tools failed with exit code ${?}."
	exit
fi
ln -s "${LOC}/tools" /
if [ "$?" -ne "0" ]
then
	echo -e "ln -s \"${LOC}/tools\" / failed with exit code ${?}."
	exit
fi
TGT=$(uname -m)-lfs-linux-gnu
cd FlatLinux/binutils-2.24
mkdir ../binutils-build
cd ../binutils-build
../binutils-2.24/configure --prefix=/tools --with-sysroot=$LOC --with-lib-path=/tools/lib --target=$TGT --disable-nls --disable-werror
make
case $(uname -m) in
  x86_64) mkdir /tools/lib && ln -sv lib /tools/lib64 ;;
esac
make install
echo "Binutils pass 1 is done."
cd ../gcc-4.9.1
cp -r ../mpfr-3.1.2 .
cp -r ../gmp-6.0.0 .
cp -r ../mpc-1.0.2 .
mv mpfr-3.1.2 mpfr
mv gmp-6.0.0 gmp
mv mpc-1.0.2 mpc
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done
sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure
sed -i 's/if \((code.*))\)/if (\1 \&\& \!DEBUG_INSN_P (insn))/' gcc/sched-deps.c
mkdir ../gcc-build
cd ../gcc-build
../gcc-4.9.1/configure                               \
    --target=$TGT                               \
    --prefix=/tools                                  \
    --with-sysroot=$LOC                              \
    --with-newlib                                    \
    --without-headers                                \
    --with-local-prefix=/tools                       \
    --with-native-system-header-dir=/tools/include   \
    --disable-nls                                    \
    --disable-shared                                 \
    --disable-multilib                               \
    --disable-decimal-float                          \
    --disable-threads                                \
    --disable-libatomic                              \
    --disable-libgomp                                \
    --disable-libitm                                 \
    --disable-libquadmath                            \
    --disable-libsanitizer                           \
    --disable-libssp                                 \
    --disable-libvtv                                 \
    --disable-libcilkrts                             \
    --disable-libstdc++-v3                           \
    --enable-languages=c,c++
make
if [ "$?" -ne "0" ]
then
	echo "making gcc failed with exit code ${?}."
	exit
fi
make install
if [ "$?" -ne "0" ]
then
	echo "Installing gcc failed with exit code ${?}."
	exit
fi
echo "GCC pass 1 is done."
cd ..
for program in "Linux-3.16.2 API Headers" "Glibc-2.20"
do
	case $program in
	"Linux-3.16.2 API Headers")
		cd linux-3.16.2
		make mrproper
		make INSTALL_HDR_PATH=dest headers_install
		if [ "$?" -ne "0" ]
		then
			echo "Installing the linux API headers failed with exit code ${?}."
			exit
		fi
		cp -r dest/include/* /tools/include
		;;
	"Glibc-2.20")
		cd glibc-2.20
		if [ ! -r /usr/include/rpc/types.h ]
		then
			mkdir -p /usr/include/rpc
			cp -v sunrpc/rpc/*.h /usr/include/rpc
			if [ "$?" -ne "0" ]
			then
				echo "Preparing to install glibc-2.20 failed with exit code ${?}."
				exit
			fi
		fi
		mkdir ../glibc-build
		cd ../glibc-build
		../glibc-2.20/configure                           \
			--prefix=/tools                               \
			--host=$TGT                                   \
			--build=$(../glibc-2.20/scripts/config.guess) \
			--disable-profile                             \
			--enable-kernel=2.6.32                        \
			--with-headers=/tools/include                 \
			libc_cv_forced_unwind=yes                     \
			libc_cv_ctors_header=yes                      \
			libc_cv_c_cleanup=yes
		make
		if [ "$?" -ne "0" ]
		then
			echo "Making Glibc-2.20 failed with exit code ${?}."
			exit
		fi
		make install
		if [ "$?" -ne "0" ]
		then
			echo "Installing Glibc-2.20 failed with exit code ${?}."
			exit
		fi
		echo "Glibc-2.20 was installed."
	esac
	cd ..
done
