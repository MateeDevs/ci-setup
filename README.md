# Bash scripts for QEST CI server
This repository contains Bash scripts for running pipelines on QEST CI server.

## Scripts

### How to install
Copy scripts to CI server and run `chmod +x` on all of them.

### Provided scripts
| Script         | Description                                                    |
|----------------|----------------------------------------------------------------|
| twine_pull.sh  | Refresh all strings from twine repository                      |
| ios_build.sh   | Install gems + pods and run specified build lane from fastlane |
| ios_release.sh | Run specified release lane from fastlane                       |
