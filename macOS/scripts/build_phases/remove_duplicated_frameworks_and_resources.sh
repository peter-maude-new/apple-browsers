#!/bin/bash
#
# The ${var:?} syntax is used to ensure that the variable is set and not empty.
# If the variable is not set, the script will exit with an error.
# This is to prevent the script from continuing with undefined variables and possibly attempting to remove /
# See https://www.shellcheck.net/wiki/SC2115
#

LOGIN_ITEMS_DIR="${TARGET_BUILD_DIR:?}/${CONTENTS_FOLDER_PATH:?}/Library/LoginItems"
VPN_DIR="${LOGIN_ITEMS_DIR}/${AGENT_PRODUCT_NAME:?}.app"
VPN_SYSEX_DIR="${VPN_DIR}/Contents/Library/SystemExtensions/${SYSEX_BUNDLE_ID:?}.systemextension"
PIR_DIR="${LOGIN_ITEMS_DIR}/${DBP_BACKGROUND_AGENT_PRODUCT_NAME:?}.app"

# Remove frameworks from Login Items
# Login Items are compiled with RPATH to the main bundle Frameworks directory, so we don't need duplicated frameworks.
rm -rf "${VPN_DIR}/Contents/Frameworks"
rm -rf "${PIR_DIR}/Contents/Frameworks"

# Remove unused C-S-S special pages and Autofill bundle from login items and extensions
# Special pages (NTP, onboarding, history, etc.) and Autofill are only used by the main app,
# and are not required in login items or extensions.
CSS_PAGES_PATH="Contents/Resources/BrowserServicesKit_ContentScopeScripts.bundle/Contents/Resources/pages"
AUTOFILL_BUNDLE_PATH="Contents/Resources/Autofill_AutofillResources.bundle"
rm -rf "${VPN_DIR:?}/${CSS_PAGES_PATH}"
rm -rf "${PIR_DIR:?}/${CSS_PAGES_PATH}"
rm -rf "${VPN_DIR:?}/${AUTOFILL_BUNDLE_PATH}"
rm -rf "${PIR_DIR:?}/${AUTOFILL_BUNDLE_PATH}"

rm -rf "${VPN_SYSEX_DIR:?}/${CSS_PAGES_PATH}"
rm -rf "${VPN_SYSEX_DIR:?}/${AUTOFILL_BUNDLE_PATH}"
