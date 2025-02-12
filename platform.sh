#!/usr/bin/env bash
set -e

# NOTE: `uname -m` is more accurate and universal than `arch`
# See https://en.wikipedia.org/wiki/Uname

arch() {
    unamem="$(uname -m)"
    case $unamem in
    *aarch64*|arm64)
        architecture="arm64";;
    *64*)
        architecture="x86_64";;
    *86*)
        architecture="386";;
    *armv5*)
        architecture="armv5";;
    *armv6*)
        architecture="armv6";;
    *armv7*)
        architecture="armv7";;
    *)
        echo "::error title=Architecture::Aborted, unsupported or unknown architecture: $unamem"
        exit 1
        ;;
    esac
    export architecture="$architecture"
}

os_specific_binary() {
    arch
    binary="${bin_name}"
    extension="tar.gz"
    unameu="$(tr '[:lower:]' '[:upper:]' <<<$(uname))"
    if [[ $unameu == *DARWIN* ]]; then
        os_name="darwin"
    elif [[ $unameu == *LINUX* ]]; then
        os_name="linux"
    elif [[ $unameu == *FREEBSD* ]]; then
        os_name="freebsd"
    elif [[ $unameu == *NETBSD* ]]; then
        os_name="netbsd"
    elif [[ $unameu == *OPENBSD* ]]; then
        os_name="openbsd"
    elif [[ $unameu == *WIN* || $unameu == MSYS* ]]; then
        # Should catch cygwin
        os_name="windows"
        binary+=".exe"
        extension=".zip"
    else
        echo "::error title=Operating System::Aborted, unsupported or unknown OS: $(uname)"
        exit 1
    fi
    export executable="${binary}"
    export archive="${bin_name}-${os_name}-${architecture}.${extension}"
}
