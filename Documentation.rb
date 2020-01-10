#!/usr/bin/env ruby

begin
  require 'fileutils'
  require 'jazzy'
rescue LoadError => e
  puts
  puts e
  puts
  puts 'Loading some gems failed. Check your system for the following gems:'
  puts "\033[1m  fileutils jazzy\033[0m"
  puts "Use the command \033[1mgem list\033[0m to list gems currently available."
  puts
  exit 1
end

begin
  throw :TKJazzyUnsupportedVersion if
    Gem.loaded_specs["jazzy"].version < Gem::Version.create('0.13') ||
    Gem.loaded_specs["jazzy"].version > Gem::Version.create('0.13.100')
end

FileUtils.cd(File.dirname(File.expand_path(__FILE__)))

$moduleVersion = `cat TravelKit/Config.xcconfig | grep TK_BUNDLE_VERSION | uniq`.strip.split(" = ")[-1] || 'staging'

# HOWTO: https://github.com/realm/jazzy

`jazzy --objc --clean \
 --framework-root . \
 --sdk macosx \
 --module TravelKit \
 --module-version '#{$moduleVersion}' \
 --umbrella-header TravelKit/TravelKit.h \
 --author 'Tripomatic' \
 --author_url 'https://travel.sygic.com/en' \
 --github_url 'https://github.com/sygic-travel/apple-sdk' \
 --documentation 'Documentation/content_pages/*.md' \
 --theme Documentation/theme \
 --min-acl public \
 --skip-undocumented \
 --output Documentation/html`

throw :TKJazzyDocumentationBuildFailure if $? != 0

# Update titles
`find Documentation/html -name *.html -exec \
 perl -pi -e 's/BRANDLESS_DOCSET_TITLE/SDK $1/, s/TravelKit\\s+(Docs|Reference)/Sygic Travel SDK $1/' {} \\;`

# Update module version
`find Documentation/html -name *.html -exec \
 perl -pi -e 's/TK_MODULE_VERSION/#{$moduleVersion}/' {} \\;`

# Additional examples:
#  jazzy \
#  --sdk iphoneos \
#  --github-file-prefix https://github.com/realm/realm-cocoa/tree/v2.2.0 \
#  --xcodebuild-arguments --objc,Realm/Realm.h,--,-x,objective-c,-isysroot,$(xcrun --show-sdk-path),-I,$(pwd) \
#  --root-url https://realm.io/docs/objc/2.2.0/api/ \
#  --head "$(cat docs/custom_head.html)"

# Open Safari with the generated content
`open Documentation/html/index.html`
