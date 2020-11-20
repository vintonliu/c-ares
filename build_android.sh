#########################################################################
# File Name: build-android.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 二 11/ 3 15:54:25 2020
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

echo "BUILD_MODE: $BUILD_MODE"


#配置交叉编译链
# linux, config ANDROID_NDK_R20_ROOT="path to ndkr20" in profile
ANDROID_NDK_TOOLCHAIN_HOME=$ANDROID_NDK_R20_ROOT
# windows平台，VSCode, git bash
# ANDROID_NDK_TOOLCHAIN_HOME=/d/Android/sdk/ndk-bundle
CMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_TOOLCHAIN_HOME/build/cmake/android.toolchain.cmake

# CMakeList.txt 所在文件夹
SOURCE_PATH=$CWD
# 编译中间文件夹
OBJECT_DIR="$CWD/out/android/build/$BUILD_MODE"
#安装文件夹
INSTALL_DIR="$CWD/out/android/install/$BUILD_MODE"

if [ -n "$1" -a "$1" == "clean" ]; then
	rm -rf "$CWD/out/android"
    exit 0
fi

if [ -d $INSTALL_DIR ]
then
    rm -rf $INSTALL_DIR
fi

# 五种类型cpu编译链
android_toolchains=(
    # armeabi is no longer support build
#   "armeabi"
    "armeabi-v7a"
    "arm64-v8a"
    # "x86"
    # "x86_64"
)

API=19

PLATFORM_CONFIG="-DANDROID=1 -DCMAKE_SYSTEM_NAME=Android \
                -DANDROID_NDK=$ANDROID_NDK_TOOLCHAIN_HOME \
                -DANDROID_TOOLCHAIN=clang \
                -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TOOLCHAIN_FILE \
                -DCMAKE_BUILD_TYPE=$BUILD_MODE"

BUILD_CONFIG="-DCMAKE_VERBOSE_MAKEFILE=ON"

build_cares() {
    num=${#android_toolchains[@]}
    for((i=0; i<num; i++))
    do
        if [ "${android_toolchains[i]}" = "arm64-v8a" ]
        then
            API=21
        fi
        echo "************* building API $API ***********"

        # create build temp dir
        mkdir -p $OBJECT_DIR/${android_toolchains[i]}
        cd $OBJECT_DIR/${android_toolchains[i]}

        CMAKE_CONFIG="$PLATFORM_CONFIG \
                    -DANDROID_ABI=${android_toolchains[i]} \
                    -DANDROID_NATIVE_API_LEVEL=$API \
                    -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/${android_toolchains[i]} \
                    -DCARES_STATIC=True \
                    -DCARES_STATIC_PIC=True \
                    -DCARES_SHARED=False \
                    -DCARES_BUILD_TOOLS=False \
                    -DCARES_BUILD_TESTS=False"

        cmake -G "Ninja" $CMAKE_CONFIG $BUILD_CONFIG $SOURCE_PATH || exit 1
        echo "******************** cmake generator done ****************"
        ninja -j8 || exit 1
        echo "******************** cmake build done ********************"
        #cmake --install .
        if [ "$BUILD_MODE" = "Debug" ]; then
            # ninja install
            ninja install
        else
            ninja install/strip
        fi

        echo "******************* cmake install done *******************"
    done

    cd $CWD
}

copy_lib() {
    num=${#android_toolchains[@]}
    for((i=0; i<num; i++))
    do
        LIB_DIR=$CWD/lib/android/$BUILD_MODE/${android_toolchains[i]}
        if [ ! -d $LIB_DIR ]
        then
            mkdir -p $LIB_DIR
        fi

        cp -Rfv $INSTALL_DIR/${android_toolchains[i]}/lib/*.a $LIB_DIR/
    done
}

build_cares
copy_lib

echo Done