#!/bin/sh

# ----------------------------------------------------------------------------
# Copyright (c) 2011-2012, KOBAYASHI Daisuke
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# ----------------------------------------------------------------------------

gcc_version=4.7.0
binutils_version=2.22
mingww64_version=2.0.2
gmp_version=5.0.4
mpfr_version=3.1.0
mpc_version=0.9

work=$PWD
build=$(cc -dumpmachine)
target=
prefix=

param_count=$#
param=$1

show_help()
{
  echo "Usage: $0 [target]"
  echo "  --32bit: i686-w64-mingw32."
  echo "  --64bit: x86_64-w64-mingw32."
  echo "  --multi: x86_64-w64-mingw32 and i686-w64-mingw32."
}

select_target()
{
  if [ $param_count -eq 1 ]; then
    case $param in
    --32bit) target=i686-w64-mingw32 ;;
    --64bit) target=x86_64-w64-mingw32 ;;
    --multi) target=x86_64-w64-mingw32 ;;
    *) show_help
      exit 1 ;;
    esac
    prefix=/usr/local/$target/$gcc_version
    PATH=$PATH:$prefix/bin
  else
    show_help
    exit 0
  fi
}

download_gcc()
{
  [ -f gcc-$gcc_version.tar.bz2 ] && return
  #curl -O ftp://gcc.gnu.org/pub/gcc/releases/gcc-$gcc_version/gcc-$gcc_version.tar.bz2
  curl -L -O http://ftpmirror.gnu.org/gcc/gcc-$gcc_version/gcc-$gcc_version.tar.bz2
}
download_binutils()
{
  [ -f binutils-$binutils_version.tar.bz2 ] && return
  #curl -O ftp://ftp.gnu.org/gnu/binutils/binutils-$binutils_version.tar.bz2
  curl -L -O http://ftpmirror.gnu.org/binutils/binutils-$binutils_version.tar.bz2
}
download_mingww64()
{
  [ -f mingw-w64-v$mingww64_version.tar.gz ] && return
  curl -L -J -O http://sourceforge.net/projects/mingw-w64/files/\
mingw-w64/mingw-w64-release/mingw-w64-v$mingww64_version.tar.gz/download
}
download_gmp()
{
  [ -f gmp-$gmp_version.tar.bz2 ] && return
  #curl -O ftp://ftp.gmplib.org/pub/gmp-$gmp_version/gmp-$gmp_version.tar.bz2
  curl -L -O http://ftpmirror.gnu.org/gmp/gmp-$gmp_version.tar.bz2
}
download_mpfr()
{
  [ -f mpfr-$mpfr_version.tar.bz2 ] && return
  curl -O http://www.mpfr.org/mpfr-current/mpfr-$mpfr_version.tar.bz2
}
download_mpc()
{
  [ -f mpc-$mpc_version.tar.gz ] && return
  curl -O http://www.multiprecision.org/mpc/download/mpc-$mpc_version.tar.gz
}

extract_gcc()
{
  [ -d gcc-$gcc_version ] && return
  download_gcc
  tar jxf gcc-$gcc_version.tar.bz2
}
extract_binutils()
{
  [ -d binutils-$binutils_version ] && return
  download_binutils
  tar jxf binutils-$binutils_version.tar.bz2
}
extract_mingww64()
{
  [ -d mingw-w64-v$mingww64_version ] && return
  download_mingww64
  tar zxf mingw-w64-v$mingww64_version.tar.gz
}
extract_gmp()
{
  [ -d gmp-$gmp_version ] && return
  download_gmp
  tar jxf gmp-$gmp_version.tar.bz2
}
extract_mpfr()
{
  [ -d mpfr-$mpfr_version ] && return
  download_mpfr
  tar jxf mpfr-$mpfr_version.tar.bz2
}
extract_mpc()
{
  [ -d mpc-$mpc_version ] && return
  download_mpc
  tar zxf mpc-$mpc_version.tar.gz
}

build_gmp()
{
  mkdir -p $work/gmp-$gmp_version/_build
  cd $work/gmp-$gmp_version/_build
  ../configure --prefix=$work --disable-shared
  make && make install
}
build_mpfr()
{
  mkdir -p $work/mpfr-$mpfr_version/_build
  cd $work/mpfr-$mpfr_version/_build
  ../configure --prefix=$work --with-gmp=$work --disable-shared
  make && make install
}
build_mpc()
{
  mkdir -p $work/mpc-$mpc_version/_build
  cd $work/mpc-$mpc_version/_build
  ../configure --prefix=$work --with-gmp=$work --with-mpfr=$work \
	--disable-shared
  make && make install
}
build_binutils()
{
  mkdir -p $work/binutils-$binutils_version/_build
  cd $work/binutils-$binutils_version/_build
  local opt="--prefix=$prefix --with-sysroot=$prefix \
	--target=$target --disable-shared --disable-debug"
  if [ $param = '--multi' ]; then
    opt="$opt --enable-targets=x86_64-w64-mingw32,i686-w64-mingw32"
  else
    opt="$opt --disable-multilib"
  fi
  ../configure $opt
  make && make install
}
install_mingww64_headers()
{
  mkdir -p $work/mingw-w64-v$mingww64_version/_build-headers
  cd $work/mingw-w64-v$mingww64_version/_build-headers
  ../mingw-w64-headers/configure --prefix=$prefix \
	--build=$build --host=$target
  make install
}
create_symlink()
{
  cd $prefix
  ln -s $target mingw
  if [ $param = '--multi' ]; then
    cd mingw
    ln -s lib lib64
  fi
}
build_gcc_core()
{
  mkdir -p $work/gcc-$gcc_version/_build
  cd $work/gcc-$gcc_version/_build
  local opt="--prefix=$prefix --with-sysroot=$prefix --target=$target \
	--with-gmp=$work --with-mpfr=$work --with-mpc=$work \
	--enable-languages=c,c++ --enable-threads \
	--disable-shared --disable-debug"
  if [ $param = '--multi' ]; then
    opt="$opt --enable-targets=all"
  else
    opt="$opt --disable-multilib"
  fi
  ../configure $opt
  make all-gcc && make install-gcc
}
build_mingww64_crt()
{
  mkdir -p $work/mingw-w64-v$mingww64_version/_build-crt
  cd $work/mingw-w64-v$mingww64_version/_build-crt
  local opt="--prefix=$prefix --with-sysroot=$prefix \
	--build=$target --host=$target"
  if [ $param = '--multi' ]; then
    opt="$opt --enable-lib32"
  fi
  CC= CXX= CPP= LD= ../mingw-w64-crt/configure $opt
  make && make install
}
build_gcc()
{
  cd $work/gcc-$gcc_version/_build
  make && make install
}


select_target

echo "--> downloading & extracting ------------------------"
extract_gcc
extract_binutils
extract_mingww64
extract_gmp
extract_mpfr
extract_mpc

echo "--> building gmp ------------------------------------"
build_gmp

echo "--> building mpfr -----------------------------------"
build_mpfr

echo "--> building mpc ------------------------------------"
build_mpc

echo "--> building binutils -------------------------------"
build_binutils

echo "--> installing mingw-w64 headers --------------------"
install_mingww64_headers

echo "--> creating symlink --------------------------------"
create_symlink

echo "--> building gcc core -------------------------------"
build_gcc_core

echo "--> building mingw-w64 crt --------------------------"
build_mingww64_crt

echo "--> building gcc ------------------------------------"
build_gcc

echo "--> done --------------------------------------------"

