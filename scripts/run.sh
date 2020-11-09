#!/bin/zsh

cd "$(dirname "$0")"

./matee-ios-build/run.sh > /dev/null 2>&1 &
./matee-ios-alpha/run.sh > /dev/null 2>&1 &
./matee-ios-beta/run.sh > /dev/null 2>&1 &
./matee-ios-prod/run.sh > /dev/null 2>&1 &
