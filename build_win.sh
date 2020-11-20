#########################################################################
# File Name: build_ios.sh
# Author: liuwch
# mail: liuwenchang1234@163.com
# Created Time: 2/23 09:36:12 2020
#########################################################################
#!/bin/bash

CWD=`pwd`

BUILD_MODE=$1
if [ -n "$BUILD_MODE" ]
then
    BUILD_MODE=Debug
else
    #BUILD_MODE=MinSizeRel
    BUILD_MODE=Release
fi

# CMakeList.txt root dir
SOURCE_PATH=$CWD
# build dir
OBJECT_DIR="$CWD/out/win/build/$BUILD_MODE"
# install dir
INSTALL_DIR="$CWD/out/win/install/$BUILD_MODE"

rm -rf $OBJECT_DIR
if [ -d $INSTALL_DIR ]
then
    rm -rf $INSTALL_DIR
fi

build_cares() {
    mkdir -p $OBJECT_DIR
    cd $OBJECT_DIR

    # Command line: D:\PROGRAM FILES (X86)\MICROSOFT VISUAL STUDIO\2017\COMMUNITY\COMMON7\IDE\COMMONEXTENSIONS\MICROSOFT\CMAKE\CMake\bin\cmake.exe  -G "Ninja" -DCMAKE_INSTALL_PREFIX:PATH="E:\Vinton\Git\github\c-ares-1.16.1\out\install\x86-Release"  -DCMAKE_CXX_COMPILER="D:/Program Files (x86)/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.16.27023/bin/HostX86/x86/cl.exe"  -DCMAKE_C_COMPILER="D:/Program Files (x86)/Microsoft Visual Studio/2017/Community/VC/Tools/MSVC/14.16.27023/bin/HostX86/x86/cl.exe" -DCARES_STATIC=True -DCARES_SHARED=False -DCARES_BUILD_TOOLS=False -DCARES_BUILD_TESTS=False -DCARES_MSVC_STATIC_RUNTIME=False -DCMAKE_BUILD_TYPE="Release" -DCMAKE_MAKE_PROGRAM="D:\PROGRAM FILES (X86)\MICROSOFT VISUAL STUDIO\2017\COMMUNITY\COMMON7\IDE\COMMONEXTENSIONS\MICROSOFT\CMAKE\Ninja\ninja.exe" "E:\Vinton\Git\github\c-ares-1.16.1"

    cmake -G "Visual Studio 14 2015" -A Win32 -DCMAKE_CONFIGURATION_TYPES=${BUILD_MODE} -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -DCARES_STATIC=True -DCARES_SHARED=False -DCARES_BUILD_TOOLS=False -DCARES_BUILD_TESTS=False -DCARES_MSVC_STATIC_RUNTIME=False $SOURCE_PATH
    cmake --build . --config ${BUILD_MODE} --target install

    cd $CWD
}

copy_lib() {
    LIB_DIR=$CWD/lib/win/$BUILD_MODE/
    if [ ! -d $LIB_DIR ]
    then
        mkdir -p $LIB_DIR
    fi

    cp -Rfv $INSTALL_DIR/lib/*.lib $LIB_DIR
}

build_cares || exit 1
copy_lib
echo Done