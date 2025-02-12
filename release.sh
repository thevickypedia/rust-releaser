#!/usr/bin/env bash
# 'set -e' stops the execution of a script if a command or pipeline has an error.
# This is the opposite of the default shell behaviour, which is to ignore errors in scripts.
set -e

# Get package information
pkg_name=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].name')
echo "Package Name: $pkg_name"
export pkg_name="$pkg_name"

bin_name=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].targets[] | select(.kind[] == "bin" or .crate_types[] == "bin") | .name')
echo "Binary Name: $bin_name"
export bin_name="$bin_name"

current_version=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].version')
# latest_version=$(curl -s https://crates.io/api/v1/crates/${pkg_name} | jq -r '.versions[0].num')
versions=$(curl -s https://crates.io/api/v1/crates/${pkg_name} | jq -r '.versions | map(.num)')
latest_version=$(echo $versions | jq -r '.[0]')
echo "Current Package Version: ${current_version}"
echo "Latest Package Version: $latest_version"
version_exists=false
for version in $(echo "$versions" | jq -r '.[]'); do
    trimmed=$(echo "$version" | awk '{$1=$1};1')
    if [ "$trimmed" == "$current_version" ]; then
    version_exists=true
    break
    fi
done
if [ "$version_exists" = true ]; then
    echo "Version $current_version exists in crates.io, setting release flag to 'false'"
    export release="false"
else
    echo "Version $current_version does not exist in crates.io, setting release flag to 'true'"
    export release="true"
fi
export pkg_version="$current_version"

if [ "$release" = false ]; then
    exit 0
fi
echo "Proceeding with release!!"
exit

# Create Release
release_tag="v${pkg_version}"
echo "release_tag=${release_tag}" >> "$GITHUB_OUTPUT"
cargo_prerelease=("alpha" "beta" "rc")
prerelease=false
for cargo_pre in "${cargo_prerelease[@]}"; do
    if [[ $pkg_version == *"$cargo_pre"* ]]; then
    prerelease=true
    break
    fi
done

echo "Release Tag: $release_tag"
latest_tag=$(curl -s -L https://api.github.com/repos/${{ github.repository }}/releases/latest | jq -r .tag_name)
commit_msg="$(git log -1 --pretty=%B | sed ':a;N;$!ba;s/\n/\\n/g')"
commit_msg+="\n**Full Changelog**: ${{ github.server_url }}/${{ github.repository }}/compare/$latest_tag...$release_tag"
release_data="{\"tag_name\":\"$release_tag\",\"name\":\"$release_tag\",\"body\":\"$commit_msg\",\"draft\":false,\"prerelease\":$prerelease}"
response=$(curl -X POST -H "Authorization: token ${{ secrets.GIT_TOKEN }}" \
    -d "$release_data" \
    "https://api.github.com/repos/${{ github.repository }}/releases")

echo "Response: $response"
release_id=$(echo $response | jq -r .id)
if [ "$release_id" = "null" ] || [ -z "$release_id" ]; then
    echo "Error: release_id is null. Exiting with code 1."
    exit 1
fi
echo "Release ID: $release_id"
echo "release_id=$release_id" >> "$GITHUB_OUTPUT"
