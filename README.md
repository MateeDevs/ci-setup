# Utilities for Matee CI server 
This repository contains utilities for managing [GitHub Actions runners](https://docs.github.com/en/free-pro-team@latest/actions/hosting-your-own-runners/about-self-hosted-runners) on Matee CI server.

## Expected folder structure
```
~  
+-- Develop
|   +-- actions 
|   |   +-- _work
|   |   +-- matee-ios-build - runner for builds and tests
|   |   |   +-- _work - symlink to ../_work
|   |   +-- matee-ios-alpha` - runner for alpha distribution   
|   |   |   +-- _work - symlink to ../_work
|   |   +-- matee-ios-beta - runner for beta distribution
|   |   |   +-- _work - symlink to ../_work
|   |   +-- matee-ios-prod - runner for production distribution   
|   |   |   +-- _work - symlink to ../_work
|   |   +-- matee-ios-internal - runner for internal distribution
|   |       +-- _work - symlink to ../_work
```

## Launchd tasks

### How to use
- Copy tasks into `~/Library/LaunchAgents` and restart CI server.
- Tasks will start runners automatically after log in and also check them every hour and rerun when needed.
- You can also load/unload them manually via `launchctl load`/`launchctl unload`.
- More info about Launchd [here](https://stackoverflow.com/questions/132955/how-do-i-set-a-task-to-run-every-so-often) and [here](https://serverfault.com/questions/183589/how-do-i-activate-launchd-logging-on-os-x)
- Still buggy ATM, because of GitHub runners auto update - [related issue](https://github.com/actions/runner/issues/485)
- Cron can't be used because it can't access keychains that are created by fastlane.

### Provided tasks
| Task                                       | Description                  |
|--------------------------------------------|------------------------------|
| cz.matee.github-actions.ios-build.plist    | Task for ios-build runner    |
| cz.matee.github-actions.ios-alpha.plist    | Task for ios-alpha runner    |
| cz.matee.github-actions.ios-beta.plist     | Task for ios-beta runner     |
| cz.matee.github-actions.ios-prod.plist     | Task for ios-prod runner     |
| cz.matee.github-actions.ios-internal.plist | Task for ios-internal runner |

## Scripts

### How to use
- Copy scripts to `~/Develop/actions` and run them manually when needed.

### Provided scripts
| Script  | Description      |
|---------|------------------|
| run.sh  | Run all runners  |
| stop.sh | Stop all runners |
