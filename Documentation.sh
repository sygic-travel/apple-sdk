#!/bin/sh

# HOWTO: https://github.com/realm/jazzy

jazzy --objc --clean \
 --framework-root . \
 --module TravelKit \
 --module-version 0.1 \
 --umbrella-header TravelKit/TravelKit.h \
 --author "Tripomatic" \
 --author_url "https://travel.sygic.com" \
 --github_url "https://github.com/sygic-travel/apple-sdk" \
 --documentation=Documentation/content_pages/*.md \
 --theme Documentation/theme \
 --min-acl public \
 --skip-undocumented \
 --output Documentation/html

#  jazzy \
#  --github-file-prefix https://github.com/realm/realm-cocoa/tree/v2.2.0 \
#  --xcodebuild-arguments --objc,Realm/Realm.h,--,-x,objective-c,-isysroot,$(xcrun --show-sdk-path),-I,$(pwd) \
#  --root-url https://realm.io/docs/objc/2.2.0/api/ \
#  --head "$(cat docs/custom_head.html)"
