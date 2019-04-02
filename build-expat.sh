#!/bin/sh

#  Automatic build script for expat 
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 19.02.12.
#  Copyright 2012 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Change values here													  #
#																		  #
VERSION="2.2.6"                                                           #
SDKVERSION="12.2"                                                          #
MIN_VERSION="8.0"                                                         #
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################


CURRENTPATH=`pwd`
ARCHS="i386 x86_64 armv7 armv7s arm64"
DEVELOPER=`xcode-select -print-path`
FN_VERSION=$(echo $VERSION | sed -e s/\\./_/g)

set -e
if [ ! -e expat-${VERSION}.tar.gz ]; then
    echo $FN_VERSION
	echo "Downloading https://codeload.github.com/libexpat/libexpat/tar.gz/libexpat-R_${FN_VERSION}"
    curl -L -o expat-${VERSION}.tar.gz https://github.com/libexpat/libexpat/archive/R_${FN_VERSION}.tar.gz
else
	echo "Using expat-${VERSION}.tar.gz"
fi

mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"

for ARCH in ${ARCHS}
do
	tar zxf expat-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
	cd "${CURRENTPATH}/src/libexpat-R_${FN_VERSION}/expat"

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi
	
	echo "Building expat-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."
	
	export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"

    export LD=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld
    export CC=${DEVELOPER}/usr/bin/gcc
    export CXX=${DEVELOPER}/usr/bin/g++

    export AR=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar
    export AS=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/as
    export NM=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm
    export RANLIB=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib

    export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -L${CURRENTPATH}/lib -miphoneos-version-min=${MIN_VERSION} -fheinous-gnu-extensions -fembed-bitcode"
    export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/include -miphoneos-version-min=${MIN_VERSION} -fheinous-gnu-extensions -fembed-bitcode"
    export CPPFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/include -miphoneos-version-min=${MIN_VERSION} -fheinous-gnu-extensions -fembed-bitcode"
    export CXXFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/include -miphoneos-version-min=${MIN_VERSION} -fheinous-gnu-extensions -fembed-bitcode"

    HOST="${ARCH}"
    if [ "${ARCH}" == "arm64" ];
    then
        HOST="aarch64"

        #Patch readfilemap.c to support aarch64
        echo perl -i -pe 's|#include <stdio.h>|#include <stdio.h>$/#include <unistd.h>|g' "${CURRENTPATH}/src/libexpat-R_${FN_VERSION}/expat/xmlwf/readfilemap.c"
        perl -i -pe 's|#include <stdio.h>|#include <stdio.h>$/#include <unistd.h>|g' "${CURRENTPATH}/src/libexpat-R_${FN_VERSION}/expat/xmlwf/readfilemap.c"
    fi

	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-expat-${VERSION}.log"

    echo "buildconf..."
    ./buildconf.sh
    echo "Configure..."
	./configure --host="${HOST}-apple-darwin" --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" --disable-shared --enable-static --with-docbook > "${LOG}" 2>&1
    echo "Make..."
    make -j4 >> "${LOG}" 2>&1
    echo "Make install..."
    make install >> "${LOG}" 2>&1
	cd "${CURRENTPATH}"
	rm -rf "${CURRENTPATH}/src/libexpat-R_${FN_VERSION}"
done

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libexpat.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/lib/libexpat.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libexpat.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/lib/libexpat.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/lib/libexpat.a -output ${CURRENTPATH}/lib/libexpat.a
lipo -info ${CURRENTPATH}/lib/libexpat.a
mkdir -p ${CURRENTPATH}/include/expat
cp  ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/expat* ${CURRENTPATH}/include/expat
echo "Building done."
echo "Done."
