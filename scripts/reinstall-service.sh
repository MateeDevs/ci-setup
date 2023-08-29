#!/bin/zsh

cd "$(dirname "$0")"

cd ./matee-ios-build
./svc.sh uninstall
./svc.sh install
cd ..

cd ./matee-ios-alpha
./svc.sh uninstall
./svc.sh install
cd ..

cd ./matee-ios-beta
./svc.sh uninstall
./svc.sh install
cd ..

cd ./matee-ios-prod
./svc.sh uninstall
./svc.sh install
cd ..

cd ./matee-ios-internal
./svc.sh uninstall
./svc.sh install
cd ..
