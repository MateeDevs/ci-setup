#!/bin/bash

BL='\033[0;34m'
G='\033[0;32m'
RED='\033[0;31m'
YE='\033[1;33m'
NC='\033[0m' # No Color


emulator_name=${EMULATOR_NAME}

function launch_emulator() {
  adb devices | grep emulator | cut -f1 | xargs -I {} adb -s "{}" emu kill
  options="@${emulator_name} -no-boot-anim"
  
  if [[ "$OSTYPE" == *linux* ]]; then
    echo "${OSTYPE}: emulator ${options} -gpu off"
    nohup usr/local/android-sdk/emulator/emulator $options -gpu off &
  fi
  if [[ "$OSTYPE" == *darwin* ]] || [[ "$OSTYPE" == *macos* ]]; then
    echo "${OSTYPE}: emulator ${options} -gpu swiftshader_indirect"
    nohup usr/local/android-sdk/emulator/emulator $options -gpu swiftshader_indirect &
  fi

  if [ $? -ne 0 ]; then
    echo "Error launching emulator"
    return 1
  fi
}

function check_emulator_status () {
  printf "${G}==> ${BL}Checking emulator booting up status 🧐${NC}\n"
  start_time=$(date +%s)
  spinner=( "⠹" "⠺" "⠼" "⠶" "⠦" "⠧" "⠇" "⠏" )
  i=0
  # Get the timeout value from the environment variable or use the default value of 300 seconds (5 minutes)
  timeout=${EMULATOR_TIMEOUT:-300}

  while true; do
    result=$(adb shell getprop sys.boot_completed 2>&1)

    if [ "$result" == "1" ]; then
      printf "${G}==>  ${BL}Emulator has ${YE}${EMULATOR_NAME} ${BL}started in headed mode! ${G}<==${NC}""\n"
      adb devices -l
      adb shell input keyevent 82
      break
    elif [ "$result" == "" ]; then
      printf "${YE}==> Emulator is partially Booted! 😕 ${spinner[$i]} ${NC}\r"
    else
      printf "${RED}==> $result, please wait ${spinner[$i]} ${NC}\r"
      i=$(( (i+1) % 8 ))
    fi

    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [ $elapsed_time -gt $timeout ]; then
      printf "${RED}==> Timeout after ${timeout} seconds elapsed 🕛.. ${NC}\n"
      break
    fi
    sleep 4
  done
};

function disable_animation() {
  adb shell "settings put global window_animation_scale 0.0"
  adb shell "settings put global transition_animation_scale 0.0"
  adb shell "settings put global animator_duration_scale 0.0"
}

launch_emulator
sleep 2
check_emulator_status
sleep 1
disable_animation
