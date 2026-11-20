# CI runners

GitHub Actions runs Android jobs on a self-hosted Linux machine with Docker.
iOS jobs run on self-hosted macOS runners with Xcode. Use the Intel macOS runner
for jobs that require x86-64.

## Choose a runner

Use a list of labels in each job’s `runs-on` and omit `group`. The runner must
have every label in the list.

| Job | `runs-on` |
| --- | --- |
| Android lint, tests, and non-urgent releases such as internal builds | `[self-hosted, matee-android, check]` |
| Android store or client releases | `[self-hosted, matee-android, release]` |
| iOS lint, tests, and non-urgent releases such as internal builds | `[self-hosted, matee-ios, check]` |
| iOS store or client releases | `[self-hosted, matee-ios, release]` |
| Intel-only macOS jobs | `[self-hosted, matee-ios-x64]` |

The `release` pool keeps store and client releases from waiting behind routine
lint and test jobs.

## Android images

In each Android job, set `container.image` to a Butterfree image with the exact
tool versions the build needs. Use a `build-` image for regular jobs and an
`emulator-` image for emulator tests. Copy the full published tag, including its
fingerprint.

If no image matches, send the required versions to the CI maintainer so they
can build one.

See the [Linux runner setup](../unix/README.md), the
[Butterfree guide](../unix/butterfree/README.md), and the
[macOS VM setup](../mac/tart/README.md) for setup details.
