#########################################################################
# File Name: build-ios.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 二 11/ 3 16:18:55 2020
#########################################################################
#!/bin/bash

CWD=`pwd`

BUILD_MODE=$1
if [ -n "$BUILD_MODE" ]
then
    BUILD_MODE=Debug
else
    BUILD_MODE=Release
fi

SOURCE_PATH=$CWD

# 编译中间文件夹
OBJECT_DIR="$CWD/out/ios"
INSTALL_DIR="$CWD/out/ios/install/$BUILD_MODE"
THIN="$INSTALL_DIR"
FAT="$INSTALL_DIR/all"
rm -rf $INSTALL_DIR

if [ -n "$1" -a "$1" == "clean" ]; then
    rm -rf $OBJECT_DIR
    exit 0
fi

# PLATFORM_CONFIG="-DCMAKE_TOOLCHAIN_FILE=$CWD/cmake/ios.toolchain.cmake \
#                -DCMAKE_BUILD_TYPE=$BUILD_MODE \
#                -DENABLE_BITCODE=0 \
#                -DENABLE_ARC=0 \
#                -DDEPLOYMENT_TARGET=9.0"

PLATFORM_CONFIG="-DCMAKE_BUILD_TYPE=$BUILD_MODE \
                -DCMAKE_SYSTEM_NAME=iOS"

CARES_CONFIG="-DCARES_STATIC=True \
            -DCARES_STATIC_PIC=True \
            -DCARES_SHARED=False \
            -DCARES_BUILD_TOOLS=False \
            -DCARES_BUILD_TESTS=False"

PLATFORMS=(
    "OS"
    "SIMULATOR"
    "SIMULATOR64"
)

ARCHS=(
    "armv7;armv7s;arm64"
    "i386"
    "x86_64"
)

IOSFLAGS="-miphoneos-version-min=9.0"

build_cares() {
    # CFLAGS="-DCARES_USE_LIBRESOLV $IOSFLAGS"
    CFLAGS="$IOSFLAGS"

    num=${#PLATFORMS[@]}
    for((i=0; i<num; i++))
    do
        echo "************** building for ${PLATFORMS[i]} *************"
        if [ ! -d "$OBJECT_DIR/${PLATFORMS[i]}" ]
        then
            mkdir -p "$OBJECT_DIR/${PLATFORMS[i]}"
        fi
        cd "$OBJECT_DIR/${PLATFORMS[i]}"

        if [ "${PLATFORMS[i]}" = "SIMULATOR" -o "${PLATFORMS[i]}" = "SIMULATOR64" ]
        then
            PLATFORM="iPhoneSimulator"
        else
            PLATFORM="iPhoneOS"
        fi

        SYSROOT="$(xcode-select -print-path)/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM.sdk/"
        CC=`xcrun -sdk ${SYSROOT} -find clang`
        CXX=`xcrun -sdk ${SYSROOT} -find clang++`

        CMAKE_CONFIG="$CARES_CONFIG \
                    $PLATFORM_CONFIG \
                    -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/${PLATFORMS[i]} \
                    -DCMAKE_OSX_ARCHITECTURES=${ARCHS[i]} \
                    -DCMAKE_OSX_SYSROOT=$SYSROOT \
                    -DCMAKE_C_COMPILER=$CC \
                    -DCMAKE_CXX_COMPILER=$CXX \
                    -DCMAKE_C_FLAGS=$CFLAGS"

        cmake -G"Ninja" $CMAKE_CONFIG -DPLATFORM=${PLATFORMS[i]} $SOURCE_PATH || exit 1
        ninja -j8 install || exit 1
        # cmake --build . --config $BUILD_MODE --target install || exit 1
    done
    cd $CWD
}

combine_lib() {
    # create fat library
    echo "combine libs ...."

    if [ -d $FAT ]
    then
        rm -rf $FAT
    fi
    mkdir -p $FAT/lib

    cd $THIN
    lipo -create `find . -name *.a` -output $FAT/lib/libcares.a || exit 1
    echo "************************************************************"
    lipo -i $FAT/lib/*.a
    cp -rvf $THIN/${PLATFORMS[0]}/include $FAT/
}

copy_lib() {
    LIB_DIR=$CWD/lib/ios/$BUILD_MODE
    if [ ! -d $LIB_DIR ]
    then
        mkdir -p $LIB_DIR
    fi

    cp -Rfv $FAT/lib/*.a $LIB_DIR/
}

build_cares || exit 1
combine_lib || exit 1
copy_lib
