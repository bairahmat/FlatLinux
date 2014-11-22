#!/bin/bash
export FORCE_UNSAFE_CONFIGURE=1
echo -en "Note: the system requirements to install FlatLinux are the following:\nBash-3.2\nBinutils-2.17 (versions greater than 2.24 are not recommended because they have not been tested)\nBison-2.3 (/usr/bin/yacc should be a link to Bison)\nBzip2-1.0.4\nCoreutils-6.9\nDiffutils-2.8.1\nFindutils-4.2.31\nGawk-4.0.1 (/usr/bin/awk should be a link to Gawk)\nGCC-4.1.2 including g++ (versions greater than 4.9.1 are not recommended as they have not been tested)\nGlibc-2.5.1 (versions greater than 2.20 are not recommended because they have not been tested)\nGrep-2.5.1a\nGzip-1.3.12\nLinux Kernel-2.6.32\nM4-1.4.10\nMake-3.81\nPatch-2.5.4\nPerl-5.8.8\nSed-4.1.5\nTar-1.18\nXz-5.0.0\nYou will need to manually check these dependicies before continuing.\nContinue? (y/n)"
read CONTINUE
if [ "$CONTINUE" = "n" ]
then
	exit
fi
echo -en "Which device would you like to install FlatLinux on?"
read DEVICE
echo "Where is $DEVICE mounted? Press enter if it is not mounted."
read LFS
if [ "$LFS" = "" ]
then
	echo "Where would you like to mount $DEVICE?"
	read LFS
	echo "Attempting to mount ${DEVICE}..."
	mount $DEVICE $LFS
	if [ "$?" -ne "0" ]
	then
		echo "Error occurred mounting $DEVICE with error code ${?}."
		exit
	fi
fi
if [ "$LFS" = "/" ]
then
	echo "This script will not install on /."
	exit
fi
mountpoint -q $LFS
if [ "$?" -ne "0" ]
then
	echo "$LFS is not a mountpoint."
	exit
fi
# If the script gets here, $LFS is where we should install it on.
echo -e "All data on $LFS will be erased and unrecoverable. You should move all important files to another location.\nAre you ready to have all files erased?(y/n)"
read confirmDelete
if [ $confirmDelete = "n" ]
then
	exit
fi
echo "Deleting all data at ${LFS}..."
dataDir="`pwd`"
cd $LFS
if [ "$?" -ne "0" ]
then
	echo "Changing to ${LFS} failed with exit code ${?}."
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
mkdir -v $LFS/sources
cd $LFS/sources
chmod -v a+wt $LFS/sources
wget -i $dataDir/wget-list.txt -P $LFS/sources
if [ "$?" -ne "0" ]
then
	echo "Getting programs to compile failed."
	exit
fi
mkdir -v $LFS/tools
ln -sv $LFS/tools /
OLDPATH=$PATH
export PATH=/tools/bin:/bin:/usr/bin
tar -xf binutils-2.24.tar.bz2
cd binutils-2.24
mkdir -v ../binutils-build
cd ../binutils-build
export LFS_TGT=$(uname -m)-lfs-linux-gnu
../binutils-2.24/configure     \
    --prefix=/tools            \
    --with-sysroot=$LFS        \
    --with-lib-path=/tools/lib \
    --target=$LFS_TGT          \
    --disable-nls              \
    --disable-werror
make
case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac
make install
if [ "$?" -ne "0" ]
then
	echo "Failed installing binutils pass 1"
	exit
fi
cd ..
rm -r binutils-2.24 binutils-build
#end binutils
tar -xf gcc-4.9.1.tar.bz2
cd gcc-4.9.1
tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc
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
mkdir -v ../gcc-build
cd ../gcc-build
../gcc-4.9.1/configure                               \
    --target=$LFS_TGT                                \
    --prefix=/tools                                  \
    --with-sysroot=$LFS                              \
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
make install
if [ "$?" -ne "0" ]
then
	echo "Gcc pass 1 failed."
	exit
fi
cd ..
rm -r gcc-4.9.1 gcc-build
# gcc pass 1 done
tar -xf linux-3.16.2.tar.xz
cd linux-3.16.2
make mrproper
make INSTALL_HDR_PATH=dest headers_install
if [ "$?" -ne "0" ]
then
	echo "Linux API headers failed."
	exit
fi
cp -rv dest/include/* /tools/include
cd ..
rm -r linux-3.16.2
#api headers done
tar -xf glibc-2.20.tar.xz
cd glibc-2.20
if [ ! -r /usr/include/rpc/types.h ]
then
  mkdir -pv /usr/include/rpc
  cp -v sunrpc/rpc/*.h /usr/include/rpc
fi
mkdir -v ../glibc-build
cd ../glibc-build
../glibc-2.20/configure                             \
      --prefix=/tools                               \
      --host=$LFS_TGT                               \
      --build=$(../glibc-2.20/scripts/config.guess) \
      --disable-profile                             \
      --enable-kernel=2.6.32                        \
      --with-headers=/tools/include                 \
      libc_cv_forced_unwind=yes                     \
      libc_cv_ctors_header=yes                      \
      libc_cv_c_cleanup=yes
make
make install
if [ "$?" -ne "0" ]
then
	echo "Glibc failed."
	exit
fi
cd ..
rm -r glibc-2.20 glibc-build
#glibc-2.20
tar -xf gcc-4.9.1.tar.bz2
cd gcc-4.9.1
mkdir -pv ../gcc-build
cd ../gcc-build
../gcc-4.9.1/libstdc++-v3/configure \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-shared                \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/4.9.1
make
make install
if [ "$?" -ne "0" ]
then
	echo "Libstdc++ failed."
	exit
fi
cd ..
rm -r gcc-4.9.1 gcc-build
#libstdc++ done
tar -xf binutils-2.24.tar.bz2
cd binutils-2.24
mkdir -v ../binutils-build
cd ../binutils-build
CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../binutils-2.24/configure     \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot
make
make install
if [ "$?" -ne "0" ]
then
	echo "Binutils pass 2 failed."
	exit
fi
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin
cd ..
rm -r binutils-2.24 binutils-build
#binutils pass 2 done
tar -xf gcc-4.9.1.tar.bz2
cd gcc-4.9.1
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
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
tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc
sed -i 's/if \((code.*))\)/if (\1 \&\& \!DEBUG_INSN_P (insn))/' gcc/sched-deps.c
mkdir -v ../gcc-build
cd ../gcc-build
CC=$LFS_TGT-gcc                                      \
CXX=$LFS_TGT-g++                                     \
AR=$LFS_TGT-ar                                       \
RANLIB=$LFS_TGT-ranlib                               \
../gcc-4.9.1/configure                               \
    --prefix=/tools                                  \
    --with-local-prefix=/tools                       \
    --with-native-system-header-dir=/tools/include   \
    --enable-languages=c,c++                         \
    --disable-libstdcxx-pch                          \
    --disable-multilib                               \
    --disable-bootstrap                              \
    --disable-libgomp
make
make install
if [ "$?" -ne "0" ]
then
	echo "Gcc pass 2 failed."
	exit
fi
ln -sv gcc /tools/bin/cc
cd ..
rm -r gcc-4.9.1 gcc-build
#gcc done
tar -xf tcl8.6.2-src.tar.gz
cd tcl8.6.2
cd unix
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Tcl failed."
	exit
fi
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh
cd ../..
rm -r tcl8.6.2
#end tcl
tar -xf expect5.45.tar.gz
cd expect5.45
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
make
make SCRIPTS="" install
if [ "$?" -ne "0" ]
then
	echo "Expect failed."
	exit
fi
cd ..
rm -r expect5.45
#expect done
tar -xf dejagnu-1.5.1.tar.gz
cd dejagnu-1.5.1
./configure --prefix=/tools
make install
if [ "$?" -ne "0" ]
then
	echo "DejaGNU failed."
	exit
fi
cd ..
rm -r dejagnu-1.5.1
#DejaGNU done
tar -xf check-0.9.14.tar.gz
cd check-0.9.14
PKG_CONFIG= ./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Check failed."
	exit
fi
cd ..
rm -r check-0.9.14
#check done
tar -xf ncurses-5.9.tar.gz
cd ncurses-5.9
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make
make install
if [ "$?" -ne "0" ]
then
	echo "Ncurses failed."
	exit
fi
cd ..
rm -r ncurses-5.9
#Ncurses done
tar -xf bash-4.3.tar.gz
cd bash-4.3
./configure --prefix=/tools --without-bash-malloc
make 
make install
if [ "$?" -ne "0" ]
then
	echo "Bash failed."
	exit
fi
ln -sv bash /tools/bin/sh
cd ..
rm -r bash-4.3
#bash done
tar -xf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
make
make PREFIX=/tools install
if [ "$?" -ne "0" ]
then
	echo "Bzip2 failed."
	exit
fi
cd ..
rm -r bzip2-1.0.6
#bzip2 done
tar -xf coreutils-8.23.tar.xz
cd coreutils-8.23
./configure --prefix=/tools --enable-install-program=hostname
make
make install
if [ "$?" -ne "0" ]
then
	echo "Coreutils failed."
	exit
fi
cd ..
rm -r coreutils-8.23
#coreutils done
tar -xf diffutils-3.3.tar.xz
cd diffutils-3.3
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Diffutils failed."
	exit
fi
cd ..
rm -r diffutils-3.3
#diffutils done
tar -xf file-5.19.tar.gz
cd file-5.19
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "File failed."
exit
fi
cd ..
rm -r file-5.19
#file done.
tar -xf findutils-4.4.2.tar.gz
cd findutils-4.4.2
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Findutils failed."
	exit
fi
cd ..
rm -r findutils-4.4.2
#findutils done
tar -xf gawk-4.1.1.tar.xz
cd gawk-4.1.1
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Gawk failed."
	exit
fi
cd ..
rm -r gawk-4.1.1
#gawk done
tar -xf gettext-0.19.2.tar.xz
cd gettext-0.19.2
cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared
make -C gnulib-lib
make -C src msgfmt
make -C src msgmerge
make -C src xgettext
if [ "$?" -ne "0" ]
then
	echo "Gettext failed."
	exit
fi
cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
cd ../..
rm -r  gettext-0.19.2
#gettext done
tar -xf grep-2.20.tar.xz
cd grep-2.20
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Grep failed."
	exit
fi
cd ..
rm -r grep-2.20
#grep done
tar -xf gzip-1.6.tar.xz
cd gzip-1.6
./configure --prefix=/tools
make 
make install
if [ "$?" -ne "0" ]
then
	echo "Gzip failed."
	exit
fi
cd ..
rm -r gzip-1.6
#gzip done
tar -xf m4-1.4.17.tar.xz
cd m4-1.4.17
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "M4 failed."
	exit
fi
cd ..
rm -r m4-1.4.17
#m4 done
tar -xf make-4.0.tar.bz2
cd make-4.0
./configure --prefix=/tools --without-guile
make
make install
if [ "$?" -ne "0" ]
then
	echo "Make failed."
	exit
fi
cd ..
rm -r make-4.0
#make done
tar -xf patch-2.7.1.tar.xz
cd patch-2.7.1
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Patch failed."
	exit
fi
cd ..
rm -r patch-2.7.1
#patch done
tar -xf perl-5.20.0.tar.bz2
cd perl-5.20.0
sh Configure -des -Dprefix=/tools -Dlibs=-lm
make
if [ "$?" -ne "0" ]
then
	echo "Perl failed."
	exit
fi
cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.20.0
cp -Rv lib/* /tools/lib/perl5/5.20.0
cd ..
rm -r perl-5.20.0
#perl done
tar -xf sed-4.2.2.tar.bz2
cd sed-4.2.2
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Sed failed."
	exit
fi
cd ..
rm -r sed-4.2.2
#sed done
tar -xf tar-1.28.tar.xz
cd tar-1.28
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Tar failed."
	exit
fi
cd ..
rm -r tar-1.28
#tar done
tar -xf texinfo-5.2.tar.xz
cd texinfo-5.2
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Texinfo failed."
	exit
fi
cd ..
rm -r texinfo-5.2
#texinfo done
tar -xf util-linux-2.25.1.tar.xz
cd util-linux-2.25.1
./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            PKG_CONFIG=""
make
make install
if [ "$?" -ne "0" ]
then
	echo "Util-linux failed."
	exit
fi
cd ..
rm -r util-linux-2.25.1
#util-linux done
tar -xf xz-5.0.5.tar.xz
cd xz-5.0.5
./configure --prefix=/tools
make
make install
if [ "$?" -ne "0" ]
then
	echo "Xz failed."
	exit
fi
cd ..
rm -r xz-5.0.5
#xz done
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*
chown -R root:root $LFS/tools
mkdir -pv $LFS/{dev,proc,sys,run}
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3
mount -v --bind /dev $LFS/dev
mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
cp ${dataDir}/install2.sh $LFS
echo "At the prompt, type '/install2.sh'. If you would like to skip all make checks, type 'yes n | /install2.sh'"
chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='\u:\w\$ '              \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h /install2.sh "$DEVICE" $1
export PATH="$PATH:/sbin:/usr/sbin"
update-grub2
echo "Installation is complete. Root password is PASSWORD"
echo $SECONDS
