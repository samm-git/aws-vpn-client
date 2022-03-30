#!/usr/bin/env bash

# Delete saml-response.txt after connect
/usr/bin/env rm saml-response.txt

# Close any tab(s) opened to get saml-response.txt
darwin_close_tabs() {
    # Firefox does not support AppleScript
    # See https://stackoverflow.com/questions/12358270/closing-specific-tab-in-firefox-using-applescript
    for browser in "Google Chrome" "Safari"; do
        osascript <<EOF
        tell application "System Events"
            if (get name of every application process) contains "${browser}" then
                tell application "${browser}"
                    set windowList to every tab of every window whose URL starts with "http://127.0.0.1:35001"
                    repeat with tabList in windowList
                        set tabList to tabList as any
                        repeat with tabItr in tabList
                            set tabItr to tabItr as any
                            delete tabItr
                        end repeat
                    end repeat
                end tell
            end if
        end tell
EOF
    done
}

# TODO: Linux support
unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)    darwin_close_tabs;;
    *)          echo "Could not determine close tabs command for this OS";;
esac
