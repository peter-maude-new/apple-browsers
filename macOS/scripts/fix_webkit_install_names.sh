#!/bin/bash

if [[ "${CONFIGURATION}" != "Debug" ]]; then
    exit 0
fi

FRAMEWORKS_PATH="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

install_name_tool -id \
  @rpath/WebCore.framework/Versions/A/WebCore \
  "${FRAMEWORKS_PATH}/WebCore.framework/Versions/A/WebCore"

install_name_tool -change \
  /System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/WebCore \
  @rpath/WebCore.framework/Versions/A/WebCore \
  "${FRAMEWORKS_PATH}/WebKit.framework/Versions/A/WebKit"

install_name_tool -change \
  /System/Library/Frameworks/WebKit.framework/Versions/A/Frameworks/WebCore.framework/Versions/A/WebCore \
  @rpath/WebCore.framework/Versions/A/WebCore \
  "${FRAMEWORKS_PATH}/WebKitLegacy.framework/Versions/A/WebKitLegacy"
