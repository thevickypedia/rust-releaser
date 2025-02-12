#!/usr/bin/env bash
set -e

if [ -z "$release_id" ]; then
    echo "Relase ID propagation failed!!"
    exit 1
else
    echo "Release ID: $release_id"
fi

cargo_build_and_test() {
    cargo build --release
    cargo test --no-run
}

build_and_upload_artifact() {
    # https://github.com/sfackler/rust-openssl/issues/1086
    if [ "$os_name" == "windows" ]; then
        if [ ! -d "/Tools" ]; then
            mkdir /Tools
        fi
        cd /Tools
        if [ ! -d "./vcpkg" ]; then
            git clone https://github.com/Microsoft/vcpkg.git
        fi
        cd vcpkg
        export vcpkg_dir="$(pwd)"
        if [ ! -f "./vcpkg.exe" ]; then
            ./bootstrap-vcpkg.bat
        fi
        ./vcpkg.exe install openssl:x64-windows-static
        echo "Setting vcpkg env vars for OpenSSL in Windows"
        export OPENSSL_DIR="${vcpkg_dir}\installed\x64-windows-static"
        export OPENSSL_STATIC="Yes"
        export VCPKG_ROOT="${vcpkg_dir}\installed\x64-windows-static"
        cargo_build_and_test
        mkdir -p "${pkg_name}"
        cp "target/release/${executable}" "${pkg_name}/${executable}"
        tar -czf "${archive}.tar.gz" -C "${pkg_name}" .
    else
        cargo_build_and_test
        mkdir -p ${pkg_name}
        cp target/release/${executable} ${pkg_name}/${executable}
        tar -zcvf ${archive} ${pkg_name}/
    fi

    curl -X POST -H "Authorization: token ${GIT_TOKEN}" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"${archive}" \
    "https://uploads.github.com/repos/${repository}/releases/${release_id}/assets?name=${archive}"
}
