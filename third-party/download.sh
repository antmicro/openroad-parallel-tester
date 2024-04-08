#!/bin/bash

set -e

_urlToFolder() {
  basename $1 .git
}

_cloneRepository() {
    echo "Cloning ${1}, ${2}"
    git clone $4 $1 $3
    pushd ${3:-$(_urlToFolder $1)}
        git checkout $2
        echo "Repository ${1} with HASH: $(git rev-parse HEAD)"
    popd
}

_cloneSubmodule() {
    revision=${2:-`git submodule status ${3:-$(_urlToFolder $1)} | cut -c2- | cut -d\  -f1`}
    _cloneRepository $1 $revision $3 $4
}

_cloneRepositories() {

    _cloneRepository $openroad_flow_scripts_url $openroad_flow_scripts_revision OpenROAD-flow-scripts

    if [[ $synthesis_results -ge 1 ]]; then
        if [[ ! -z $synthesis_results_url ]]; then
            _cloneRepository $synthesis_results_url $synthesis_results_revision synthesis_results
        else
            echo "--with-synthesis-results used but synthesis results url not defined" >2
            exit 2
        fi
    fi

    if [[ $depth -le 0 ]]; then
        return
    fi

    pushd OpenROAD-flow-scripts/tools
        _cloneSubmodule $openroad_url "$openroad_revision" OpenROAD
        pushd OpenROAD/src
            _cloneSubmodule $opensta_url "$opensta_revision" sta "--recurse-submodules" 
            sed -i 's/\.\.\/\.\./https:\/\/github.com/g' ../.gitmodules
            for submodule in $(git submodule status | cut -c2- | cut -d\  -f2); do
                if [[ $submodule == "sta" ]]; then
                    continue
                fi
                git submodule update --init $submodule
            done
        popd
        if [[ $depth -le 1 ]]; then
            return
        fi
        _cloneSubmodule $lsoracle_url "$lsoracle_revision" LSOracle "--recurse-submodules" 
        _cloneSubmodule $yosys_url "$yosys_revision" yosys "--recurse-submodules" 
    popd
}


_help() {
  cat <<EOF
Usage: $0
  Script downloading repositories required to run OpenROAD project.
  Parameters can be set through environmental variables or with arguments.

Options:
    -h, --help
        Print this message

    --shallow
        Clone only OpenROAD-flow-scripts repository

    --openroad-only
        Clone OpenROAD-flow-scripts and OpenROAD with submodules

    --full
        Clone OpenROAD-flow-scripts with submodules (default)

    --with-synthesis-results
        Additionally clone repository with synthesis results

    --openroad-flow-scripts-url
        URL of OpenROAD-flow-scripts repository
        Default: https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git

    --openroad-flow-scripts-revision
        Revision of OpenROAD-flow-scripts repository
        Default: master branch

    --openroad-url
        URL of OpenROAD repository
        Default: https://github.com/The-OpenROAD-Project/OpenROAD.git

    --openroad-revision
        Revision of OpenROAD repository
        Default: defined by submodule

    --opensta-url
        URL of OpenSTA repository
        Default: https://github.com/The-OpenROAD-Project/OpenSTA.git

    --opensta-revision
        Revision of OpenSTA repository
        Default: defined by submodule

    --lsoracle-url
        URL of LSOracle repository
        Default: https://github.com/The-OpenROAD-Project/LSOracle.git

    --lsoracle-revision
        Revision of LSOracle repository
        Default: defined by submodule
  
    --yosys-url
        URL of yosys repository
        Default: https://github.com/The-OpenROAD-Project/yosys.git

    --yosys-revision
        Revision of yosys repository
        Default: defined by submodule

    --synthesis-results-url
        URL of repository with synthesis results
        Default: https://github.com/The-OpenROAD-Project/yosys.git

    --synthesis-results-revision
        Revision of repository with synthesis results
        Default: defined by submodule

EOF
}

openroad_flow_scripts_url=${OPENROAD_FLOW_SCRIPTS_URL:-"https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git"}
openroad_flow_scripts_revision=${OPENROAD_FLOW_SCRIPTS_REVISION:-"master"}
openroad_url=${OPENROAD_URL:-"https://github.com/The-OpenROAD-Project/OpenROAD.git"}
openroad_revision=$OPENROAD_REVISION
opensta_url=${OPENSTA_URL:-"https://github.com/The-OpenROAD-Project/OpenSTA.git"}
opensta_revision=$OPENSTA_REVISION
lsoracle_url=${LSORACLE_URL:-"https://github.com/The-OpenROAD-Project/LSOracle.git"}
lsoracle_revision=$LSORACLE_REVISION
yosys_url=${YOSYS_URL:-"https://github.com/The-OpenROAD-Project/yosys.git"}
yosys_revision=$YOSYS_REVISION
synthesis_results_url=${SYNTHESIS_RESULTS_URL}
synthesis_results_revision=${SYNTHESIS_RESULTS_REVISION:-"main"}
synthesis_results=0
depth=2

while [ "$#" -gt 0 ]; do
    case "${1}" in
    -h|--help)
        _help
        exit
        ;;
    --openroad-flow-scripts-url)
        openroad_flow_scripts_url=$2
        shift
        ;;
    --openroad-flow-scripts-revision)
        openroad_flow_scripts_revision=$2
        shift
        ;;
    --openroad-url)
        openroad_url=$2
        shift
        ;;
    --openroad-revision)
        openroad_revision=$2
        shift
        ;;
    --opensta-url)
        opensta_url=$2
        shift
        ;;
    --opensta-revision)
        opensta_revision=$2
        shift
        ;;
    --lsoracle-url)
        lsoracle_url=$2
        shift
        ;;
    --lsoracle-revision)
        lsoracle_revision=$2
        shift
        ;;
    --yosys-url)
        yosys_url=$2
        shift
        ;;
    --yosys-revision)
        yosys_revision=$2
        shift
        ;;
    --synthesis-results-url)
        synthesis_results_url=$2
        shift
        ;;
    --synthesis-results-revision)
        synthesis_results_revision=$2
        shift
        ;;
    --shallow)
        depth=0
        ;;
    --openroad-only)
        depth=1
        ;;
    --full)
        depth=2
        ;;
    --with-synthesis-results)
        synthesis_results=1
        ;;
    *)
        echo "Unknown argument: ${1}" >&2
        exit 1
        ;;
    esac
    shift
done

_cloneRepositories


