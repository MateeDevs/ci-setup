#!/bin/zsh

cd "$(dirname "$0")"

cd ./matee-ios-build
./svc.sh stop
cd ..

cd ./matee-ios-alpha
./svc.sh stop
cd ..

cd ./matee-ios-beta
./svc.sh stop
cd ..

cd ./matee-ios-prod
./svc.sh stop
cd ..

cd ./matee-ios-internal
./svc.sh stop
cd ..
