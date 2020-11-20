#########################################################################
# File Name: build-mac.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 二 11/ 3 17:28:16 2020
#########################################################################
#!/bin/bash

BUILD_MODE=$1
if [ -n "$BUILD_MODE" ]
then
    BUILD_MODE=Debug
else
    BUILD_MODE=Release
fi

CWD=`pwd`

# CMakeList.txt 所在文件夹
SOURCE_PATH=$CWD
OBJECT_DIR="$CWD/out/mac"
INSTALL_DIR="$CWD/out/mac/install/$BUILD_MODE"
# THIN="$INSTALL_DIR"
# FAT="$CWD/install/mac/$BUILD_MODE"
rm -rf $INSTALL_DIR
# rm -rf $FAT

if [ -n "$1" -a "$1" == "clean" ]; then
rm -rf $OBJECT_DIR
exit 0
fi

CMAKE_BUILD_CONFIG="-DCMAKE_VERBOSE_MAKEFILE=OFF \
                    -DCMAKE_BUILD_TYPE=$BUILD_MODE \
                    -DCARES_STATIC=True \
                    -DCARES_STATIC_PIC=True \
                    -DCARES_SHARED=False \
                    -DCARES_BUILD_TOOLS=False \
                    -DCARES_BUILD_TESTS=False"

build_cares() {
    if [ ! -d $OBJECT_DIR ]
    then
        mkdir -p $OBJECT_DIR
    fi
    cd $OBJECT_DIR

    CMAKE_BUILD_CONFIG="$CMAKE_BUILD_CONFIG \
                        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
                        -DCMAKE_OSX_DEPLOYMENT_TARGET=10.10"

    cmake -G"Ninja" $CMAKE_BUILD_CONFIG $SOURCE_PATH
    ninja -j8 install || exit 1
    # cmake --build . --config $BUILD_MODE --target install || exit 1
    echo "************************ build done ************************"

    cd $CWD
}

copy_lib() {
    LIB_DIR=$CWD/lib/mac/$BUILD_MODE
    if [ ! -d $LIB_DIR ]
    then
        mkdir -p $LIB_DIR
    fi

    cp -Rfv $INSTALL_DIR/lib/*.a $LIB_DIR/
}

build_cares
copy_lib

echo Done