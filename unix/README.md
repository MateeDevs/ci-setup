# Matee CI on Unix

`matee-ci` is the self-hosted Linux machine for Android CI. It runs Android
builds and emulator tests. [Butterfree](./butterfree/README.md) builds the
versioned Docker images for these jobs.

## Host

| Component | Version |
| --- | --- |
| Operating system | Ubuntu 22.04 |
| Kernel | `6.8.0-106-generic` |
| Architecture | `x86_64` |
| Docker client | `29.7.2` |
| Docker Compose | `5.5.0` |
| Host Java | `17.0.20` |

The host JDK runs the runner services. Butterfree containers use Java 21 by
default for Android builds.

Check the host configuration:

```bash
uname -a
docker version
docker compose version
java -version
```

## Images

Butterfree publishes two variants to
[`mateedevs/butterfree`](https://hub.docker.com/r/mateedevs/butterfree):

| Tag prefix | Purpose |
| --- | --- |
| `build-` | Android builds with Java, Gradle, Kotlin/Native, and the Android SDK |
| `emulator-` | UI tests with the build toolchain, API 34 emulator, Maestro, Python, and VNC |

Each tag records its main tool versions. A fingerprint comes after these
versions. The fingerprint represents all tool versions and archive checksums.
Butterfree does not publish a `latest` tag. Always copy the full tag that
Butterfree prints.

Current checked-in examples:

```text
mateedevs/butterfree:build-jdk21-gradle9.7.1-kotlin2.4.10-sdk37.1-647f9c8f10f3
mateedevs/butterfree:emulator-jdk21-sdk37.1-api34-maestro2.9.0-80b2146f404f
```

## Publish current versions

From the root of this repository:

```bash
docker login
cd unix/butterfree
./butterfree
```

The Butterfree workflow has five stages:

1. Get the latest stable tool versions from official sources.
2. Check Docker Hub and skip each tag that exists.
3. Build and load missing images.
4. Check each tag again, and then push each missing tag.
5. Show and publish the Docker Hub version table.

Interactive prompts use `[Y/n]`. Press Enter to continue. Enter `n` to decline
an operation. The built images and BuildKit caches stay on the host.

For an unattended trusted run:

```bash
./butterfree --yes
```

Use `--set NAME=VALUE` to set a different resolved value:

```bash
./butterfree \
  --set JAVA_VERSION=21 \
  --set EMULATOR_API_LEVEL=34
```

If you set the version of an archive file, also set its SHA-256 value. The
[Butterfree tutorial](./butterfree/README.md) contains all variables, manual
Bake commands, and authentication instructions.

## Use an image in CI

After Butterfree publishes a newer tag, replace the example tag.

### GitHub Actions: build

```yaml
jobs:
  check:
    runs-on: [self-hosted, pikachu]
    container:
      image: mateedevs/butterfree:build-jdk21-gradle9.7.1-kotlin2.4.10-sdk37.1-647f9c8f10f3
    steps:
      - uses: actions/checkout@v4
      - run: ./gradlew ktlintCheck build
```

### GitHub Actions: emulator

```yaml
jobs:
  ui-test:
    runs-on: [self-hosted, pikachu]
    container:
      image: mateedevs/butterfree:emulator-jdk21-sdk37.1-api34-maestro2.9.0-80b2146f404f
      options: --device /dev/kvm
    steps:
      - uses: actions/checkout@v4
      - run: start_emu_headless.sh
      - run: ./gradlew connectedCheck
```

Each emulator image contains Maestro. Use `--privileged` only if a job needs
more host access than `/dev/kvm`.

### GitLab CI

```yaml
.android:
  image: mateedevs/butterfree:build-jdk21-gradle9.7.1-kotlin2.4.10-sdk37.1-647f9c8f10f3
```

## Run the emulator manually

Start a container with KVM acceleration:

```bash
docker run --interactive --tty --detach \
  --device /dev/kvm \
  --publish 5900:5900 \
  --name butterfree-emulator \
  mateedevs/butterfree:emulator-jdk21-sdk37.1-api34-maestro2.9.0-80b2146f404f

docker exec butterfree-emulator start_emu_headless.sh
```

If `/dev/kvm` is unavailable, the launcher uses slower software emulation.

For a windowed emulator, start VNC before the emulator:

```bash
docker exec --detach \
  --env VNC_PASSWORD=change-me \
  butterfree-emulator start_vnc.sh

docker exec butterfree-emulator start_emu.sh
```

## Runner operations

GitHub runner:

```bash
cd ~/Matee/actions-runner
sudo ./svc.sh status
sudo ./svc.sh start
```

Run it directly for troubleshooting:

```bash
cd ~/Matee/actions-runner
./run.sh
```

GitLab Runner:

```bash
sudo gitlab-runner status
sudo gitlab-runner start
```
