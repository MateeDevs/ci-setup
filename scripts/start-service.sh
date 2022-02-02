#!/bin/zsh

cd "$(dirname "$0")"

cd ./matee-ios-build
./svc.sh start
cd ..

cd ./matee-ios-alpha
./svc.sh start
cd ..

cd ./matee-ios-beta
./svc.sh start
cd ..

cd ./matee-ios-prod
./svc.sh start
cd ..

cd ./matee-ios-internal
./svc.sh start
cd ..
