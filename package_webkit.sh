#!/bin/bash

# to build WebKit:
#   set -o pipefail && Tools/Scripts/build-webkit --release ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO | xcbeautify

# This script packages WebKit.framework by replacing all symlinks inside the framework with the actual files.
# This is useful for distributing WebKit.framework in a way that is easy to use in other projects.

# Usage:
# ./package_webkit.sh

set -e

build_dir=${1:-WebKitBuild}
output_path=${2:-out}

if [[ ! -d "$build_dir" ]]; then
    echo "Error: Build directory not found: $build_dir"
    exit 1
fi

rm -rf "$output_path"
mkdir -p "$output_path"

frameworks=(
    "JavaScriptCore.framework"
    "WebCore.framework"
    "WebGPU.framework"
    "WebInspectorUI.framework"
    "WebKit.framework"
    "WebKitLegacy.framework"
)

dylibs=(
    "libANGLE-shared.dylib"
    "libwebrtc.dylib"
)

for framework in "${frameworks[@]}"; do
    echo "Processing ${framework}"
    # Copy the WebKit.framework to the output directory
    printf "%s" "    Copying ... "
    cp -R "${build_dir}/Release/${framework}" "$output_path"
    echo "✅"

    # Replace all symlinks with the actual files
    printf "%s" "    Replacing symlinks ... "
    # shellcheck disable=SC2044
    for link in $(find "${output_path}/${framework}/Versions/A" -type l); do
        target="$(dirname "$link")/$(readlink "$link")"
        target="${target#"${output_path}"}"
        target="${build_dir}/Release${target}"
        rm -f "$link"
        cp -R "$target" "$link"
    done
    echo "✅"
done

for dylib in "${dylibs[@]}"; do
    echo "Processing ${dylib}"
    printf "%s" "    Copying ... "
    cp -R "${build_dir}/Release/${dylib}" "$output_path"
    echo "✅"
done

install_name_tool -id \
  @rpath/WebCore.framework/Versions/A/WebCore \
  "${output_path}/WebCore.framework/Versions/A/WebCore"

install_name_tool -change \
  /System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/WebCore \
  @rpath/WebCore.framework/Versions/A/WebCore \
  "${output_path}/WebKit.framework/Versions/A/WebKit"

install_name_tool -change \
  /System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/WebCore \
  @rpath/WebCore.framework/Versions/A/WebCore \
  "${output_path}/WebKitLegacy.framework/Versions/A/WebKitLegacy"
