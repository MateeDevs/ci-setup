#!/bin/bash
bundle install --path vendor/bundle
bundle exec fastlane $1
bundle clean
