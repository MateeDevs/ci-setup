#!/bin/bash
bundle install --path vendor/bundle
bundle exec pod install --repo-update
bundle exec fastlane $1 build_number:$2
bundle clean
