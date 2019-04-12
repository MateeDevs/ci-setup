#!/bin/bash
bundle install --path vendor/bundle
bundle exec pod install --repo-update
bundle exec fastlane $1 git_branch:$2 build_number:$3
bundle clean
