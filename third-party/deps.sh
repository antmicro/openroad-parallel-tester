#!/bin/bash

# Downloads and compiles OpenROAD dependencies

set -e

PREFIX=dependencies/
OPEN_ROAD_PATH=OpenROAD-flow-scripts/tools/OpenROAD
baseDir=$(mktemp -d)

_installCommonDev() {
    lastDir="$(pwd)"
    # tools versions
    osName="linux"
    cmakeChecksum=${CMAKE_CHECKSUM:-"b8d86f8c5ee990ae03c486c3631cee05"}
    cmakeVersionBig=${CMAKE_VER_BIG:-3.24}
    cmakeVersionSmall=${CMAKE_VER_SMAL:-${cmakeVersionBig}.2}
    pcreVersion=${PCRE_VER:-10.42}
    pcreChecksum=${PCRE_CHECKSUM:-"37d2f77cfd411a3ddf1c64e1d72e43f7"}
    swigVersion=${SWIG_VER:-4.1.0}
    swigChecksum=${SWIG_CHECKSUM:-"794433378154eb61270a3ac127d9c5f3"}
    boostVersionBig=${BOOST_VER_BIG:-1.80}
    boostVersionSmall=${BOOST_VER_SMALL:-${boostVersionBig}.0}
    boostChecksum=${BOOST_CHECKSUM:-"077f074743ea7b0cb49c6ed43953ae95"}
    eigenVersion=${EIGEN_VER:-3.4}
    lemonVersion=${LEMON_VERSION:-1.3.1}
    spdlogVersion=${SPDLOG_VER:-1.8.1}

    rm -rf "${baseDir}"
    mkdir -p "${baseDir}"
    if [[ ! -z "${PREFIX}" ]]; then
        mkdir -p "${PREFIX}"
    fi

    # CMake
    cmakePrefix=${PREFIX:-"/usr/local"}
    cmakeBin=${cmakePrefix}/bin/cmake
    if [[ ! -f ${cmakeBin} || -z $(${cmakeBin} --version | grep ${cmakeVersionBig}) ]]; then
        cd "${baseDir}"
        wget https://cmake.org/files/v${cmakeVersionBig}/cmake-${cmakeVersionSmall}-${osName}-x86_64.sh
        md5sum -c <(echo "${cmakeChecksum} cmake-${cmakeVersionSmall}-${osName}-x86_64.sh") || exit 1
        chmod +x cmake-${cmakeVersionSmall}-${osName}-x86_64.sh
        ./cmake-${cmakeVersionSmall}-${osName}-x86_64.sh --skip-license --prefix=${cmakePrefix}
    else
        echo "CMake already installed."
    fi

    # SWIG
    swigPrefix=${PREFIX:-"/usr/local"}
    swigBin=${swigPrefix}/bin/swig
    if [[ ! -f ${swigBin} || -z $(${swigBin} -version | grep ${swigVersion}) ]]; then
        cd "${baseDir}"
        tarName="v${swigVersion}.tar.gz"
        wget https://github.com/swig/swig/archive/${tarName}
        md5sum -c <(echo "${swigChecksum} ${tarName}") || exit 1
        tar xfz ${tarName}
        cd swig-${tarName%%.tar*} || cd swig-${swigVersion}

        # Check if pcre2 is installed
        if [[ -z $(pcre2-config --version) ]]; then
          tarName="pcre2-${pcreVersion}.tar.gz"
          wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${pcreVersion}/${tarName}
          md5sum -c <(echo "${pcreChecksum} ${tarName}") || exit 1
          ./Tools/pcre-build.sh
        fi
        ./autogen.sh
        ./configure --prefix=${swigPrefix}
        make -j $(nproc)
        make -j $(nproc) install
    else
        echo "Swig already installed."
    fi

    # boost
    boostPrefix=${PREFIX:-"/usr/local"}
    if [[ -z $(grep "BOOST_LIB_VERSION \"${boostVersionBig//./_}\"" ${boostPrefix}/include/boost/version.hpp) ]]; then
        cd "${baseDir}"
        boostVersionUnderscore=${boostVersionSmall//./_}
        # wget https://sourceforge.net/projects/boost/files/boost/${boostVersionSmall}/boost_${boostVersionUnderscore}.tar.gz
        wget https://boostorg.jfrog.io/artifactory/main/release/${boostVersionSmall}/source/boost_${boostVersionUnderscore}.tar.gz
        md5sum -c <(echo "${boostChecksum}  boost_${boostVersionUnderscore}.tar.gz") || exit 1
        tar -xf boost_${boostVersionUnderscore}.tar.gz
        cd boost_${boostVersionUnderscore}
        ./bootstrap.sh --prefix="${boostPrefix}"
        ./b2 install --with-iostreams --with-test --with-serialization --with-system --with-thread -j $(nproc)
    else
        echo "Boost already installed."
    fi

    # eigen
    eigenPrefix=${PREFIX:-"/usr/local"}
    if [[ ! -d ${eigenPrefix}/include/eigen3 ]]; then
        cd "${baseDir}"
        git clone --depth=1 -b ${eigenVersion} https://gitlab.com/libeigen/eigen.git
        cd eigen
        ${cmakePrefix}/bin/cmake -DCMAKE_INSTALL_PREFIX="${eigenPrefix}" -B build .
        ${cmakePrefix}/bin/cmake --build build -j $(nproc) --target install
    else
        echo "Eigen already installed."
    fi

    # CUSP
    cuspPrefix=${PREFIX:-"/usr/local/include"}
    if [[ -z ${SKIP_CUSP+x} ]] && [[ ! -d ${cuspPrefix}/cusp/ ]]; then
        cd "${baseDir}"
        git clone --depth=1 -b cuda9 https://github.com/cusplibrary/cusplibrary.git
        cd cusplibrary
        cp -r ./cusp ${cuspPrefix}
    else
        echo "CUSP already installed."
    fi

    # lemon
    lemonPrefix=${PREFIX:-"/usr/local"}
    if [[ -z $(grep "LEMON_VERSION \"${lemonVersion}\"" ${lemonPrefix}/include/lemon/config.h) ]]; then
        cd "${baseDir}"
        git clone --depth=1 -b ${lemonVersion} https://github.com/The-OpenROAD-Project/lemon-graph.git
        cd lemon-graph
        ${cmakePrefix}/bin/cmake -DCMAKE_INSTALL_PREFIX="${lemonPrefix}" -B build .
        ${cmakePrefix}/bin/cmake --build build -j $(nproc) --target install
    else
        echo "Lemon already installed."
    fi

    # spdlog
    spdlogPrefix=${PREFIX:-"/usr/local"}
    if [[ ! -d ${spdlogPrefix}/include/spdlog ]]; then
        cd "${baseDir}"
        git clone --depth=1 -b "v${spdlogVersion}" https://github.com/gabime/spdlog.git
        cd spdlog
        ${cmakePrefix}/bin/cmake -DCMAKE_INSTALL_PREFIX="${spdlogPrefix}" -DSPDLOG_BUILD_EXAMPLE=OFF -B build .
        ${cmakePrefix}/bin/cmake --build build -j $(nproc) --target install
    else
        echo "spdlog already installed."
    fi

    if [[ ${equivalenceDeps} == "yes" ]]; then
        _equivalenceDeps
    fi

    cd "${lastDir}"
    rm -rf "${baseDir}"
}


_installOrTools() {
    os=$OR_TOOLS_OS
    version=$OR_TOOLS_OS_VER
    arch=$OR_TOOLS_ARCH
    orToolsVersionBig=9.5
    orToolsVersionSmall=${orToolsVersionBig}.2237

    rm -rf "${baseDir}"
    mkdir -p "${baseDir}"
    if [[ ! -z "${PREFIX}" ]]; then mkdir -p "${PREFIX}"; fi
    cd "${baseDir}"

    orToolsFile=or-tools_${arch}_${os}-${version}_cpp_v${orToolsVersionSmall}.tar.gz
    wget https://github.com/google/or-tools/releases/download/v${orToolsVersionBig}/${orToolsFile}
    orToolsPath=${PREFIX:-"/opt/or-tools"}
    if command -v brew &> /dev/null; then
        orToolsPath="$(brew --prefix or-tools)"
    fi
    mkdir -p ${orToolsPath}
    tar --strip 1 --dir ${orToolsPath} -xf ${orToolsFile}
    rm -rf ${baseDir}
}

_installValgrind() {
    valgrindVersion=${VALGRIND_VER:-3.22.0}
    valgrindChecksum=${VALGRIND_MD5:-38ea14f567efa09687a822b33b4d9d60}

    rm -rf "${baseDir}"
    mkdir -p "${baseDir}"
    pushd $baseDir

    wget https://sourceware.org/pub/valgrind/valgrind-${valgrindVersion}.tar.bz2 -O valgrind.tar.bz2
    md5sum -c <(echo "${valgrindChecksum} valgrind.tar.bz2") || exit 1
    tar xvf valgrind.tar.bz2
    mkdir -p OpenROAD-flow-scripts/tools/install/valgrind
    pushd valgrind-${valgrindVersion}
    ./configure --prefix=$PREFIX
    make -j $(nproc)
    make install    

    popd
    popd
}

_generateEnvFile() {
    
      cat > ${PREFIX}/env.sh <<EOF
depRoot="\$(dirname \$(readlink -f "\${BASH_SOURCE[0]}"))"
PATH=\${depRoot}/bin:\${PATH}
LD_LIBRARY_PATH=\${depRoot}/lib64:\${depRoot}/lib:\${LD_LIBRARY_PATH}
EOF
    if [[ -z ${SKIP_VALGRIND+x} ]]; then
        echo 'VALGRIND_LIB=${depRoot}/libexec/valgrind' >> ${PREFIX}/env.sh
    fi
}

_installDependencies() {
    _installCommonDev
    if [[ -z ${SKIP_OR_TOOLS+x} ]]; then
        if [[ -z ${OR_TOOLS_OS+x} ]] || [[ -z ${OR_TOOLS_OS_VER+x} ]] || [[ -z ${OR_TOOLS_ARCH+x} ]]; then
            echo "Missing OS, OS version or ARCH for OR-Tools installation" >&2
            exit 1
        fi
        _installOrTools
    fi
    if [[ -z ${SKIP_VALGRIND+x} ]]; then
        _installValgrind
    fi
    _generateEnvFile
}

_help() {
  cat <<EOF
Usage: $0
    Script installing common dependencies for OpenROAD (it's based on OpenROAD DependencyInstaller).

Options:
    -h, --help
        Print this message

    --open-road-path
        Path to folder with OpenROAD repository

    --prefix
        Folder where dependencies will be installed

    --skip-cusp
        Skip CUSP library installation

    --skip-or-tools
        Skip OR-Tools installation

    --or-tools-os
    --or-tools-os-version
    --or-tools-arch
        Specifies OS, OS version and ARCH for OR-Tools installation
        Available values can be found here: https://github.com/google/or-tools/releases

    --skip-valgrind
        Skip Valgrind installation
EOF
}

while [ "$#" -gt 0 ]; do
    case "${1}" in
    -h|--help)
        _help
        exit
        ;;
    --skip-cusp)
        SKIP_CUSP=1
        ;;
    --open-road-path)
        OPEN_ROAD_PATH="$2"
        shift
        ;;
    --prefix)
        PREFIX="$2"
        shift
        ;;
    --skip-or-tools)
        SKIP_OR_TOOLS=1
        ;;
    --or-tools-os)
        OR_TOOLS_OS="$2"
        shift
        ;;
    --or-tools-os-version)
        OR_TOOLS_OS_VER="$2"
        shift
        ;;
    --or-tools-arch)
        OR_TOOLS_ARCH="$2"
        shift
        ;;
    --skip-valgrind)
        SKIP_VALGRIND=1
        ;;
    *)
        echo "Unknown argument: ${1}" >&2
        exit 1
        ;;
    esac
    shift
done

PREFIX=$(realpath $PREFIX)
_installDependencies


