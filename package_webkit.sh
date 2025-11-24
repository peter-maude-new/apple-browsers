#!/bin/bash

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

dependencies=(
    "/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/JavaScriptCore"
    "/System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/WebCore"
    "/System/Library/PrivateFrameworks/WebGPU.framework/Versions/A/WebGPU"
    "/System/Library/PrivateFrameworks/WebInspectorUI.framework/Versions/A/WebInspectorUI"
    "/System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebKitLegacy.framework/Versions/A/WebKitLegacy"
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

    printf "%s" "    Adjusting install names ... "
    install_name_tool -id "@rpath/${framework}/Versions/A/${framework//.framework}" \
        "${output_path}/${framework}/Versions/A/${framework//.framework}"
    otool_output="$(otool -L "${output_path}/${framework}/Versions/A/${framework//.framework}")"
    for dependency in "${dependencies[@]}"; do
        if [[ "${otool_output}" != *"${dependency}"* ]]; then
            continue
        fi
        install_name_tool -change "$dependency" \
            "@loader_path/../../../${dependency##*/}.framework/Versions/A/${dependency##*/}" \
            "${output_path}/${framework}/Versions/A/${framework//.framework}"
    done
    echo "✅"
done

for dylib in "${dylibs[@]}"; do
    echo "Processing ${dylib}"
    printf "%s" "    Copying ... "
    cp -R "${build_dir}/Release/${dylib}" "$output_path"
    echo "✅"
done

xpc_dir="${output_path}/WebKit.framework/Versions/A/XPCServices"
for xpc_path in "${xpc_dir}"/*; do
    echo "Processing ${xpc_path}"
    xpc_name="${xpc_path##*/}"
    xpc_file_name="$(ls "${xpc_path}"/Contents/MacOS/*)"
    xpc_file_name="${xpc_file_name##*/}"
    xpc_file_path="${xpc_dir}/${xpc_name}/Contents/MacOS/${xpc_file_name}"
    otool_output="$(otool -L "$xpc_file_path")"

    install_name_tool -change "/System/Library/Frameworks/WebKit.framework/Versions/A/WebKit" \
        "@loader_path/../../../../../../../WebKit.framework/Versions/A/WebKit" \
        "$xpc_file_path"
done
