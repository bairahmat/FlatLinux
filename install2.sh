#!/tools/bin/bash
mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v  /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}
case $(uname -m) in
 x86_64) ln -sv lib /lib64
         ln -sv lib /usr/lib64
         ln -sv lib /usr/local/lib64 ;;
esac
mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin
ln -sv /tools/bin/perl /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
ln -sv bash /bin/sh
ln -sv /proc/self/mounts /etc/mtab
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
nogroup:x:99:
users:x:999:
EOF
#exec /tools/bin/bash --login +h
touch /var/log/{btmp,lastlog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
cd /sources
tar -xf linux-3.17.4.tar.xz
cd linux-3.17.4
make mrproper
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include
cd ..
rm -r linux-3.17.4
#api headers done
tar -xf man-pages-3.72.tar.xz
cd man-pages-3.72
make install
cd ..
rm -r man-pages-3.72
#man-pages done
tar -xf glibc-2.20.tar.xz
cd glibc-2.20
patch -Np1 -i ../glibc-2.20-fhs-1.patch
mkdir -v ../glibc-build
cd ../glibc-build
../glibc-2.20/configure    \
    --prefix=/usr          \
    --disable-profile      \
    --enable-kernel=2.6.32 \
    --enable-obsolete-rpc
make
#echo "Run glibc tests?(y/n)"
#read tests
#if [ "$tests" -ne "n" ]
#then
#	make check
#	echo "If more tests than posix/tst-getaddrinfo4 fail, press Ctrl-C and restart."
#	read wait
#fi
touch /etc/ld.so.conf
make install
if [ "$?" -ne "0" ]
then
	echo "Glibc failed."
	exit
fi
cp -v ../glibc-2.20/nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
mkdir -pv /usr/lib/locale
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
tar -xf ../tzdata2014g.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
if [ -f /usr/share/zoneinfo/${2} ]
then
	cp -v /usr/share/zoneinfo/${2} /etc/localtime
else
	tzselect
	echo "Enter the last line printed."
	read zone
	cp -v /usr/share/zoneinfo/${zone} /etc/localtime
fi
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
cd ..
rm -r glibc-2.20 glibc-build
#glibc done
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs
tar -xf zlib-1.2.8.tar.xz
cd zlib-1.2.8
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Zlib failed."
	exit
fi
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
cd ..
rm -r zlib-1.2.8
#zlib done
tar -xf file-5.19.tar.gz
cd file-5.19
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "File failed."
	exit
fi
cd ..
rm -r file-5.19
#file done
tar -xf binutils-2.24.tar.bz2
cd binutils-2.24
rm -fv etc/standards.info
sed -i.bak '/^INFO/s/standards.info //' etc/Makefile.in
patch -Np1 -i ../binutils-2.24-load_gcc_lto_plugin_by_default-1.patch
patch -Np1 -i ../binutils-2.24-lto_testsuite-1.patch
mkdir -v ../binutils-build
cd ../binutils-build
../binutils-2.24/configure --prefix=/usr   \
                           --enable-shared \
                           --disable-werror
make tooldir=/usr
#make -k check
#if [ "$?" -ne "0" ]
#then
#	echo "Binutils tests failed. Continue anyway? (y/n)"
#	read continue
#	if [ "$continue" -ne "y" ]
#	then
#		exit
#	fi
#fi
make tooldir=/usr install
cd ..
rm -r binutils-2.24 binutils-build
#binutils done
tar -xf gmp-6.0.0a.tar.xz
cd gmp-6.0.0
./configure --prefix=/usr \
            --enable-cxx  \
            --docdir=/usr/share/doc/gmp-6.0.0a
make
make html
make install
if [ "$?" -ne "0" ]
then
	echo "Gmp failed."
	exit
fi
make install-html
cd ..
rm -r gmp-6.0.0
#gmp done
tar -xf mpfr-3.1.2.tar.xz
cd mpfr-3.1.2
patch -Np1 -i ../mpfr-3.1.2-upstream_fixes-2.patch
./configure --prefix=/usr        \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-3.1.2
make
make html
make install
if [ "$?" -ne "0" ]
then
	echo "Mpfr failed."
	exit
fi
make install-html
cd ..
rm -r mpfr-3.1.2
#mpfr done
tar -xf mpc-1.0.2.tar.gz
cd mpc-1.0.2
./configure --prefix=/usr --docdir=/usr/share/doc/mpc-1.0.2
make
make html
make install
if [ "$?" -ne "0" ]
then
	echo "Mpc failed."
	exit
fi
make install-html
cd ..
rm -r mpc-1.0.2
#mpc done
tar -xf gcc-4.9.1.tar.bz2
cd gcc-4.9.1
sed -i 's/if \((code.*))\)/if (\1 \&\& \!DEBUG_INSN_P (insn))/' gcc/sched-deps.c
patch -Np1 -i ../gcc-4.9.1-upstream_fixes-1.patch
mkdir -v ../gcc-build
cd ../gcc-build
SED=sed                       \
../gcc-4.9.1/configure        \
     --prefix=/usr            \
     --enable-languages=c,c++ \
     --disable-multilib       \
     --disable-bootstrap      \
     --with-system-zlib
make
make install
if [ "$?" -ne "0" ]
then
	echo "Gcc failed."
	exit
fi
ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc
install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/4.9.1/liblto_plugin.so /usr/lib/bfd-plugins/
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd ..
rm -r gcc-build gcc-4.9.1
#gcc done
tar -xf bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
if [ "$?" -ne "0" ]
then
	echo "Bzip2 failed."
	exit
fi
cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat
cd ..
rm -r bzip2-1.0.6
#bzip2 done
tar -xf pkg-config-0.28.tar.gz
cd pkg-config-0.28
./configure --prefix=/usr         \
            --with-internal-glib  \
            --disable-host-tool   \
            --docdir=/usr/share/doc/pkg-config-0.28
make
make install
if [ "$?" -ne "0" ]
then
	echo "Pkg-config failed."
	exit
fi
cd ..
rm -r pkg-config-0.28
#pkg-config done
tar -xf ncurses-5.9.tar.gz
cd ncurses-5.9
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --enable-pc-files       \
            --enable-widec
make
make install
if [ "$?" -ne "0" ]
then
	echo "Ncurses failed."
	exit
fi
mv -v /usr/lib/libncursesw.so.5* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv lib${lib}w.a      /usr/lib/lib${lib}.a
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncurses++w.a /usr/lib/libncurses++.a
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
ln -sfv libncursesw.a      /usr/lib/libcursesw.a
ln -sfv libncurses.a       /usr/lib/libcurses.a
mkdir -v       /usr/share/doc/ncurses-5.9
cp -v -R doc/* /usr/share/doc/ncurses-5.9
cd ..
rm -r ncurses-5.9
#ncurses done
tar -xf attr-2.4.47.src.tar.gz
cd attr-2.4.47
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
./configure --prefix=/usr --bindir=/bin
make
make install install-dev install-lib
if [ "$?" -ne "0" ]
then
	echo "Attr failed."
	exit
fi
chmod -v 755 /usr/lib/libattr.so
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
cd ..
rm -r attr-2.4.47
#attr done
tar -xf acl-2.2.52.src.tar.gz
cd acl-2.2.52
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" \
    libacl/__acl_to_any_text.c
./configure --prefix=/usr \
            --bindir=/bin \
            --libexecdir=/usr/lib
make
make install install-dev install-lib
if [ "$?" -ne "0" ]
then
	echo "Acl failed."
	exit
fi
chmod -v 755 /usr/lib/libacl.so
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
cd ..
rm -r acl-2.2.52
#acl done
tar -xf libcap-2.24.tar.xz
cd libcap-2.24
make
make RAISE_SETFCAP=no prefix=/usr install
if [ "$?" -ne "0" ]
then
	echo "Libcap failed."
	exit
fi
chmod -v 755 /usr/lib/libcap.so
mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
cd ..
rm -r libcap-2.24
#libcap done
tar -xf sed-4.2.2.tar.bz2
cd sed-4.2.2
./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed-4.2.2
make
make html
make install
if [ "$?" -ne "0" ]
then
	echo "Sed failed."
	exit
fi
make -C doc install-html
cd ..
rm -r sed-4.2.2
#sed done
tar -xf shadow-4.2.1.tar.xz
cd shadow-4.2.1
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs
sed -i 's/1000/999/' etc/useradd
./configure --sysconfdir=/etc --with-group-name-max-length=32
make
make install
if [ "$?" -ne "0" ]
then
	echo "Shadow failed."
	exit
fi
mv -v /usr/bin/passwd /bin
pwconv
grpconv
echo 'root:PASSWORD' | chpasswd
cd ..
rm -r shadow-4.2.1
#shadow done
tar -xf psmisc-22.21.tar.gz
cd psmisc-22.21
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Psmisc failed."
	exit
fi
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin
cd ..
rm -r psmisc-22.21
#psmisc done
tar -xf procps-ng-3.3.9.tar.xz
cd procps-ng-3.3.9
./configure --prefix=/usr                           \
            --exec-prefix=                          \
            --libdir=/usr/lib                       \
            --docdir=/usr/share/doc/procps-ng-3.3.9 \
            --disable-static                        \
            --disable-kill
make
make install
if [ "$?" -ne "0" ]
then
	echo "Procps failed."
	exit
fi
mv -v /usr/bin/pidof /bin
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
cd ..
rm -r procps-3.3.9
#procps done
tar -xf e2fsprogs-1.42.12.tar.gz
cd e2fsprogs-1.42.12
mkdir -v build
cd build
LIBS=-L/tools/lib                    \
CFLAGS=-I/tools/include              \
PKG_CONFIG_PATH=/tools/lib/pkgconfig \
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
make install
if [ "$?" -ne "0" ]
then
	echo "E2fsprogs failed."
	exit
fi
make install-libs
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
cd ../..
rm -r e2fsprogs-1.42.12
#e2fsprogs done
tar -xf coreutils-8.23.tar.xz
cd coreutils-8.23
patch -Np1 -i ../coreutils-8.23-i18n-1.patch &&
touch Makefile.in
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make
make install
if [ "$?" -ne "0" ]
then
	echo "Coreutils failed."
	exit
fi
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,sleep,nice,test,[} /bin
cd ..
rm -r coreutils-8.23
#coreutils done
tar -xf iana-etc-2.30.tar.bz2
cd iana-etc-2.30
make
make install
if [ "$?" -ne "0" ]
then
	echo "Iana-etc failed."
	exit
fi
cd ..
rm -r iana-etc-2.30
#iana-etc done
tar -xf m4-1.4.17.tar.xz
cd m4-1.4.17
./configure --prefix=/usr
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
tar -xf flex-2.5.39.tar.bz2
cd flex-2.5.39
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.5.39
make
make install
if [ "$?" -ne "0" ]
then
	echo "Flex failed."
	exit
fi
ln -sv flex /usr/bin/lex
cd ..
rm -r flex-2.5.39
#flex done
tar -xf bison-3.0.2.tar.xz
cd bison-3.0.2
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Bison failed."
	exit
fi
cd ..
rm -r bison-3.0.2
#bison done
tar -xf grep-2.20.tar.xz
cd grep-2.20
./configure --prefix=/usr --bindir=/bin
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
tar -xf readline-6.3.tar.gz
cd readline-6.3
patch -Np1 -i ../readline-6.3-upstream_fixes-2.patch
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr --docdir=/usr/share/doc/readline-6.3
make SHLIB_LIBS=-lncurses
make SHLIB_LIBS=-lncurses install
if [ "$?" -ne "0" ]
then
	echo "Readline failed."
	exit
fi
mv -v /usr/lib/lib{readline,history}.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-6.3
cd ..
rm -r readline-6.3
#readline done
tar -xf bash-4.3.tar.gz
cd bash-4.3
patch -Np1 -i ../bash-4.3-upstream_fixes-3.patch
./configure --prefix=/usr                    \
            --bindir=/bin                    \
            --docdir=/usr/share/doc/bash-4.3 \
            --without-bash-malloc            \
            --with-installed-readline
make
make install
if [ "$?" -ne "0" ]
then
	echo "Bash failed."
	exit
fi
#exec /bin/bash --login +h
cd ..
rm -r bash-4.3
#bash done
tar -xf bc-1.06.95.tar.bz2
cd bc-1.06.95
patch -Np1 -i ../bc-1.06.95-memory_leak-1.patch
./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info
make
make install
if [ "$?" -ne "0" ]
then
	echo "Bc failed."
	exit
fi
cd ..
rm -r bc-1.06.95
#bc done
tar -xf libtool-2.4.2.tar.gz
cd libtool-2.4.2
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Libtools failed."
	exit
fi
cd ..
rm -r libtool-2.4.2
#libtool done
tar -xf gdbm-1.11.tar.gz
cd gdbm-1.11
./configure --prefix=/usr --enable-libgdbm-compat
make
make install
if [ "$?" -ne "0" ]
then
	echo "Gdbm failed."
	exit
fi
cd ..
rm -r gdbm-1.11
#gdbm done
tar -xf expat-2.1.0.tar.gz
cd expat-2.1.0
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Expat failed."
	exit
fi
install -v -dm755 /usr/share/doc/expat-2.1.0
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.1.0
cd ..
rm -r expat-2.1.0
#expat done
tar -xf inetutils-1.9.2.tar.gz
cd inetutils-1.9.2
echo '#define PATH_PROCNET_DEV "/proc/net/dev"' >> ifconfig/system/linux.h 
./configure --prefix=/usr  \
            --localstatedir=/var   \
            --disable-logger       \
            --disable-whois        \
            --disable-servers
make
make install
if [ "$?" -ne "0" ]
then
	echo "Inetutils failed."
	exit
fi
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin
cd ..
rm -r inetutils-1.9.2
#inetutils failed
tar -xf perl-5.20.0.tar.bz2
cd perl-5.20.0
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib
make
make install
if [ "$?" -ne "0" ]
then
	echo "Perl failed."
	exit
fi
unset BUILD_ZLIB BUILD_BZIP2
cd ..
rm -r perl-5.20.0
#perl done
tar -xf XML-Parser-2.42_01.tar.gz
cd XML-Parser-2.42_01
perl Makefile.PL
make
make install
if [ "$?" -ne "0" ]
then
	echo "XML Parser failed."
	exit
fi
cd ..
rm -r XML-Parser-2.42_01
#XML parser done
tar -xf autoconf-2.69.tar.xz
cd autoconf-2.69
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Autoconf failed."
	exit
fi
cd ..
rm -r autoconf-2.69
#autoconf done
tar -xf automake-1.14.1.tar.xz
cd automake-1.14.1
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.14.1
make
make install
if [ "$?" -ne "0" ]
then
	echo "Automake failed."
	exit
fi
cd ..
rm -r automake-1.14.1
#automake done
tar -xf diffutils-3.3.tar.xz
cd diffutils-3.3
sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in
./configure --prefix=/usr
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
tar -xf gawk-4.1.1.tar.xz
cd gawk-4.1.1
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Gawk failed."
	exit
fi
mkdir -v /usr/share/doc/gawk-4.1.1
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.1.1
cd ..
rm -r gawk-4.1.1
#gawk done
tar -xf findutils-4.4.2.tar.gz
cd findutils-4.4.2
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
make install
if [ "$?" -ne "0" ]
then
	echo "Findutils done."
	exit
fi
mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
cd ..
rm -r findutils-4.4.2
#findutils done
tar -xf gettext-0.19.2.tar.xz
cd gettext-0.19.2
./configure --prefix=/usr --docdir=/usr/share/doc/gettext-0.19.2
make
make install
if [ "$?" -ne "0" ]
then
	echo "Gettext failed."
	exit
fi
cd ..
rm -r gettext-0.19.2
#gettext done
tar -xf intltool-0.50.2.tar.gz
cd intltool-0.50.2
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Intltool failed."
	exit
fi
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.50.2/I18N-HOWTO
cd ..
rm -r intltool-0.50.2
#intltool done
tar -xf gperf-3.0.4.tar.gz
cd gperf-3.0.4
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.0.4
make
make install
if [ "$?" -ne "0" ]
then
	echo "Gperf failed."
	exit
fi
cd ..
rm -r gperf-3.0.4
#gperf done
tar -xf groff-1.22.2.tar.gz
cd groff-1.22.2
PAGE=letter ./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Groff failed."
	exit
fi
cd ..
rm -r groff-1.22.2
#groff done
tar -xf xz-5.0.5.tar.xz
cd xz-5.0.5
./configure --prefix=/usr --docdir=/usr/share/doc/xz-5.0.5
make
make install
if [ "$?" -ne "0" ] 
then
	echo "Xz failed."
	exit
fi
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
cd ..
rm -r xz-5.0.5
#xz done
tar -xf grub-2.00.tar.xz
cd grub-2.00
sed -i -e '/gets is a/d' grub-core/gnulib/stdio.in.h
./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-grub-emu-usb \
            --disable-efiemu       \
            --disable-werror
make
make install
if [ "$?" -ne "0" ]
then
	echo "Grub failed."
	exit
fi
cd ..
rm -r grub-2.00
#grub done
tar -xf less-458.tar.gz
cd less-458
./configure --prefix=/usr --sysconfdir=/etc
make
make install
if [ "$?" -ne "0" ]
then
	echo "Less failed."
	exit
fi
cd ..
rm -r less-458
#less done
tar -xf gzip-1.6.tar.xz
cd gzip-1.6
./configure --prefix=/usr --bindir=/bin
make
make install
mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin
mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin
cd ..
rm -r gzip-1.6
#gzip done
tar -xf iproute2-3.16.0.tar.xz
cd iproute2-3.16.0
sed -i '/^TARGETS/s@arpd@@g' misc/Makefile
sed -i /ARPD/d Makefile
sed -i 's/arpd.8//' man/man8/Makefile
make
make DOCDIR=/usr/share/doc/iproute2-3.16.0 install
if [ "$?" -ne "0" ]
then
	echo "Iproute2 failed."
	exit
fi
cd ..
rm -r iproute2-3.16.0
#iproute2-3.16.0 done
tar -xf kbd-2.0.2.tar.gz
cd kbd-2.0.2
patch -Np1 -i ../kbd-2.0.2-backspace-1.patch
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
make
make install
if [ "$?" -ne "0" ]
then
	echo "Kbd failed."
	exit
fi
mkdir -v       /usr/share/doc/kbd-2.0.2
cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.2
cd ..
rm -r kbd-2.0.2
#kbd done
tar -xf kmod-18.tar.xz
cd kmod-18
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib
make
make install
if [ "$?" -ne "0" ]
then
	echo "Kmod failed."
	exit
fi
for target in depmod insmod modinfo modprobe rmmod; do
  ln -sv ../bin/kmod /sbin/$target
done
ln -sv kmod /bin/lsmod
cd ..
rm -r kmod-18
#kmod done
tar -xf libpipeline-1.3.0.tar.gz
cd libpipeline-1.3.0
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Libpipeline failed."
	exit
fi
cd ..
rm -r libpipeline-1.3.0
#libpipeline done
tar -xf make-4.0.tar.bz2
cd make-4.0
./configure --prefix=/usr
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
./configure --prefix=/usr
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
tar -xf sysklogd-1.5.tar.gz
cd sysklogd-1.5
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
make
make BINDIR=/sbin install
if [ "$?" -ne "0" ]
then
	echo "Sysklogd failed."
	exit
fi
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
cd ..
rm -r sysklogd-1.5
#sysklogd done
tar -xf sysvinit-2.88dsf.tar.bz2
cd sysvinit-2.88dsf
patch -Np1 -i ../sysvinit-2.88dsf-consolidated-1.patch
make -C src
make -C src install
if [ "$?" -ne "0" ]
then
	echo "Sysvinit failed."
	exit
fi
cd ..
rm -r sysvinit-2.88dsf
#sysvinit done
tar -xf tar-1.28.tar.xz
cd tar-1.28
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make
make install
if [ "$?" -ne "0" ]
then
	echo "Tar failed."
	exit
fi
make -C doc install-html docdir=/usr/share/doc/tar-1.28
cd ..
rm -r tar-1.28
#tar done
tar -xf texinfo-5.2.tar.xz
cd texinfo-5.2
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Texinfo failed."
	exit
fi
make TEXMF=/usr/share/texmf install-tex
pushd /usr/share/info
rm -v dir
for f in *
  do install-info $f dir 2>/dev/null
done
popd
cd ..
rm -r texinfo-5.2
#texinfo done
tar -xf eudev-1.10.tar.gz
cd eudev-1.10
sed -r -i 's|/usr(/bin/test)|\1|' test/udev-test.pl
BLKID_CFLAGS=-I/tools/include       \
BLKID_LIBS='-L/tools/lib -lblkid'   \
./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-split-usr      \
            --enable-libkmod        \
            --enable-rule_generator \
            --enable-keymap         \
            --disable-introspection \
            --disable-gudev         \
            --disable-gtk-doc-html  \
            --with-firmware-path=/lib/firmware 
make
mkdir -pv /lib/{firmware,udev}
mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d
make install
if [ "$?" -ne "0" ]
then
	echo "Eudev failed."
	exit
fi
tar -xvf ../eudev-1.10-manpages.tar.bz2 -C /usr/share
tar -xvf ../udev-lfs-20140408.tar.bz2
make -f udev-lfs-20140408/Makefile.lfs install
cd ..
rm -r eudev-1.10
#eudev done
tar -xf util-linux-2.25.1.tar.xz
cd util-linux-2.25.1
mkdir -pv /var/lib/hwclock
sed -e 's/2^64/(2^64/' -e 's/E </E) <=/' -e 's/ne /eq /' \
    -i tests/ts/ipcs/limits2
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linx-2.25.1
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
tar -xf man-db-2.6.7.1.tar.xz
cd man-db-2.6.7.1
./configure --prefix=/usr                          \
            --docdir=/usr/share/doc/man-db-2.6.7.1 \
            --sysconfdir=/etc                      \
            --disable-setuid                       \
            --with-browser=/usr/bin/lynx           \
            --with-vgrind=/usr/bin/vgrind          \
            --with-grap=/usr/bin/grap
make
make install
if [ "$?" -ne "0" ]
then
	echo "Man-db failed."
	exit
fi
cd ..
rm -r man-db-2.6.7.1
#man-db done
tar -xf vim-7.4.tar.bz2
cd vim74
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make
make install
if [ "$?" -ne "0" ]
then
	echo "Vim failed."
	exit
fi
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim74/doc /usr/share/doc/vim-7.4
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
syntax on
if (&term == "iterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
rm -rf /tmp/*
rm -rf /tools
cd ..
rm -r vim74
#vim done
tar -xf lfs-bootscripts-20140815.tar.bz2
cd lfs-bootscripts-20140815
make install
if [ "$?" -ne "0" ]
then
	echo "Lfs bootscripts failed."
	exit
fi
cd ..
rm -r lfs-bootscripts-20140815
#lfs bootscripts done
bash /lib/udev/init-net-rules.sh
cd /etc/sysconfig/
cat > ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=192.168.1.2
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
# End /etc/resolv.conf
EOF
echo "FlatLinux" > /etc/hostname
cat > /etc/hosts << "EOF"
# Begin /etc/hosts (network card version)

127.0.0.1 localhost
192.168.5.132 FlatLinux [alias1] [alias2 ...]

# End /etc/hosts (network card version)
EOF
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S016:once:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF
cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF
cat > /etc/sysconfig/console << "EOF"
LOGLEVEL=8
EOF
cat > /etc/profile << "EOF"
# Begin /etc/profile

export LANG=en_US.utf8

# End /etc/profile
EOF
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF
fstype="$(df -T $1 | tail -1 | awk '{print $2}')"
echo -e "# Begin /etc/fstab\n\n# file system mount-point type options dump fsck\n${1} / ${fstype} defaults 1 1\nproc /proc proc nosuid,noexec,nodev 0 0\nsysfs /sys sysfs nosuid,noexec,nodev 0 0\ndevpts /dev/pts devpts gid=5,mode=620 0 0\ntmpfs /run tmpfs defaults 0 0\ndevtmpfs /dev devtmpfs mode=0755,nosuid 0 0" > /etc/fstab
cd /sources
tar -xf openssl-1.0.1i.tar.gz
cd openssl-1.0.1i
patch -Np1 -i ../openssl-1.0.1i-fix_parallel_build-1.patch &&
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic &&
make
make MANDIR=/usr/share/man MANSUFFIX=ssl install
if [ "$?" -ne "0" ]
then
	echo "Openssl failed."
	exit
fi
install -dv -m755 /usr/share/doc/openssl-1.0.1i
cp -vfr doc/*     /usr/share/doc/openssl-1.0.1i
cd ..
rm -r openssl-1.0.1i
#kernel and done!
tar -xf linux-3.17.4.tar.xz
cd linux-3.17.4
make mrproper
make defconfig
make
if [ "$?" -ne "0" ]
then
	echo "Kernel failed."
	exit
fi
make modules_install
arch=$(uname -m)
cp -v arch/${arch}/boot/bzImage /boot/vmlinuz-3.17.4-lfs-7.6
cp -v System.map /boot/System.map-3.17.4
cp -v .config /boot/config-3.17.4
install -d /usr/share/doc/linux-3.17.4
cp -r Documentation/* /usr/share/doc/linux-3.17.4
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
