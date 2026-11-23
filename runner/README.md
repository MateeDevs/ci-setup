# CI runners

Android jobs run on Linux with Docker. iOS jobs run on macOS with Xcode.

## Choose a runner

List the labels in `runs-on`. Omit `group`. The runner must have all the labels.

| Job | `runs-on` |
| --- | --- |
| Android lint, tests, and non-urgent releases | `[self-hosted, matee-android, check]` |
| Android store or client releases | `[self-hosted, matee-android, release]` |
| iOS lint, tests, and non-urgent releases | `[self-hosted, matee-ios, check]` |
| iOS store or client releases | `[self-hosted, matee-ios, release]` |
| macOS jobs that require Intel (x86-64) | `[self-hosted, matee-ios-x64]` |

Use `check` for non-urgent internal builds. The separate `release` queue keeps
store and client releases from waiting behind lint and tests.

## Android images

Set `container.image` to a Butterfree image with the exact tool versions the
job needs. Use a `build-` tag for regular jobs and an `emulator-` tag for
emulator tests. Copy the full tag.

If no image matches, send the required versions to the CI maintainer so they
can build one.

See the [Linux runner setup](../unix/README.md), the
[Butterfree guide](../unix/butterfree/README.md), and the
[macOS VM setup](../mac/tart/README.md) for setup details.
