# Butterfree

Butterfree creates versioned Docker images for Android CI. It gets current tool
versions. It builds missing images and pushes new tags. It also updates the
Docker Hub description.

Butterfree does not remove local images or BuildKit caches.

## Images

Butterfree publishes all images to `mateedevs/butterfree`.

| Tag prefix | Bake target | Contents |
| --- | --- | --- |
| `build-` | `butterfree` | Java, Gradle, Kotlin/Native, Android command-line tools, and the three newest stable Android platforms and build-tools |
| `emulator-` | `emulator` | The build image, API 34 Play Store x86_64 emulator, Maestro, Python, fonts, and VNC tools |

The emulator application programming interface (API) stays at 34 unless you
set a different value. Each emulator image contains Maestro.

Each tag contains the primary tool versions and a 12-character fingerprint.
The fingerprint represents all effective versions and archive checksums.
Butterfree does not create a `latest` tag.

Current checked-in examples:

```text
mateedevs/butterfree:build-jdk21-gradle9.7.1-kotlin2.4.10-sdk37.1-647f9c8f10f3
mateedevs/butterfree:emulator-jdk21-sdk37.1-api34-maestro2.9.0-80b2146f404f
```

## Requirements

Install these components:

- Docker
- Docker Buildx
- Python 3

Use a persistent Buildx builder. This builder keeps the build cache between
runs.

## Create and publish current images

### 1. Authenticate

Authenticate with Docker Hub:

```bash
docker login
cd /home/matee/Matee/ci-setup/unix/butterfree
```

Butterfree reads credentials from the Docker configuration. It supports inline
credentials. It also supports credential helpers, credential stores, and
`DOCKER_CONFIG`. Butterfree does not print the username or secret.

For CI, you can use environment variables instead:

```bash
export DOCKERHUB_USERNAME=mateedevs
read -rsp "Docker Hub token: " DOCKERHUB_TOKEN
export DOCKERHUB_TOKEN
```

Set both variables together. For a personal access token, use the Docker Hub
username. For an organization access token, use the organization name. The
environment variables have priority over credentials from `docker login`.

Public tag checks do not require credentials. Private tag checks, image pushes,
and description updates require credentials.

### 2. Run Butterfree

Start the interactive workflow:

```bash
./butterfree
```

Butterfree completes these stages:

1. Get current stable versions from official release services.
2. Check the two tags on Docker Hub.
3. Build and load each missing image.
4. Check each tag again and push each missing image.
5. Show and publish the Docker Hub description and the version tables.

The tag checks run automatically. Butterfree asks for approval before the
version fetch. It also asks before each applicable operation that changes data.
A prompt uses `[Y/n]`. Press Enter to approve the operation. Enter `n` to
decline it.

If a tag check does not give a clear result, Butterfree stops. Butterfree does
not push a tag that exists. It does not change the tag settings on Docker Hub.

If both tags exist, Butterfree skips the build and push stages. The built
images stay on the host. Butterfree removes only its temporary files. These
files contain version data or tag-status data.

For a non-interactive trusted run, use:

```bash
./butterfree --yes
```

To publish to a different Docker Hub user or organization, use:

```bash
./butterfree --namespace NAMESPACE
```

The repository name stays `butterfree`.

## Set specific versions

Use one `--set NAME=VALUE` argument for each override. Butterfree applies the
overrides before it creates the fingerprints. Then, it checks Docker Hub.

Example:

```bash
./butterfree \
  --set JAVA_VERSION=21 \
  --set ANDROID_BUILD_TOOLS_VERSIONS=37.0.0,36.1.0,36.0.0 \
  --set ANDROID_PLATFORM_VERSIONS=37.1,37.0,36.1
```

Some tools use archive files. If you set the version of an archive file, also
set its checksum.

| Version variable | Checksum variable |
| --- | --- |
| `GRADLE_VERSION` | `GRADLE_SHA256` |
| `KOTLIN_VERSION` | `KOTLIN_NATIVE_SHA256` |
| `ANDROID_CMDLINE_TOOLS_VERSION` | `ANDROID_CMDLINE_TOOLS_SHA256` |
| `MAESTRO_VERSION` | `MAESTRO_SHA256` |

Example:

```bash
./butterfree \
  --set GRADLE_VERSION=9.7.1 \
  --set GRADLE_SHA256=acd53f1edaf02f1a8ff99879f8a34b302661a057d9b063ae9e35b552f804d20a
```

You can also set these values:

- `UBUNTU_VERSION`
- `JAVA_VERSION`
- `ANDROID_BUILD_TOOLS_VERSIONS`
- `ANDROID_PLATFORM_VERSIONS`
- `ANDROID_PLATFORM_TOOLS_VERSION`
- `ANDROID_EMULATOR_VERSION`
- `EMULATOR_API_LEVEL`
- `EMULATOR_ARCH`
- `EMULATOR_TARGET`
- `EMULATOR_NAME`
- `EMULATOR_DEVICE`

Ubuntu 22.04, Java 21, and emulator API 34 are policy defaults. Butterfree does
not update these major versions automatically. Set a different value when the
policy changes.

## Get version variables only

The version resolver uses the Python standard library. It reads official
metadata from Gradle, JetBrains, Google, and Maestro.

Print shell export statements:

```bash
./fetch-latest-versions.py
```

Save and use the output:

```bash
./fetch-latest-versions.py > /tmp/butterfree-versions.env
. /tmp/butterfree-versions.env
docker buildx bake --print
docker buildx bake --load
```

Print dotenv output without `export`:

```bash
./fetch-latest-versions.py --format env
```

Use the same `--set NAME=VALUE` arguments with the resolver. If GitHub applies
its anonymous request limit, set `GITHUB_TOKEN`. Butterfree sends the token
only in request headers. It does not print the token.

The resolver gets these current values automatically:

- Gradle
- Kotlin/Native
- Android command-line tools
- Three newest stable Android build-tools versions
- Three newest stable Android platform versions
- Android platform-tools
- Android emulator
- Maestro
- Required SHA-256 checksums

## Docker Hub description and image labels

Butterfree shows one Markdown description for the repository. The description
contains the current tags and component versions. Butterfree first makes sure
that all resolved tags are on Docker Hub. Then, the user must approve the
description update.

Each image also contains OCI labels and `io.matee.butterfree.*` labels. These
labels keep the version information with each historical tag.

Butterfree adds the source URL to each OCI image label. It also adds the URL to
the Docker Hub description: [Matee CI setup](https://github.com/MateeDevs/ci-setup/tree/master).

## Build manually

Run Bake commands from the `butterfree` directory.

Build and load both images with the checked-in defaults:

```bash
docker buildx bake --load
```

Build one image:

```bash
docker buildx bake --load butterfree
docker buildx bake --load emulator
```

> **CAUTION:** Before a manual push, make sure that the tags do not exist.
> A manual push does not use the Butterfree tag checks. A manual push can
> overwrite an existing tag.

After you make sure that the tags do not exist, push the images:

```bash
docker buildx bake --push
```

The Dockerfile uses BuildKit cache mounts for apt data, downloaded archives,
and Android SDK downloads. Keep the Buildx builder between CI jobs. Also keep
`/root/.gradle` for Gradle dependencies and `/root/.konan` for Kotlin/Native
dependencies.

## Run the emulator

Use a complete `emulator-` tag. Give the container access to `/dev/kvm` for
hardware acceleration.

```bash
docker run --interactive --tty --detach \
  --device /dev/kvm \
  --publish 5900:5900 \
  --name butterfree-emulator \
  mateedevs/butterfree:emulator-jdk21-sdk37.1-api34-maestro2.9.0-80b2146f404f

docker exec butterfree-emulator start_emu_headless.sh
```

If `/dev/kvm` is not available, the launcher uses slower software emulation.

To use a windowed emulator, start VNC and then start the emulator:

```bash
docker exec --detach \
  --env VNC_PASSWORD=change-me \
  butterfree-emulator start_vnc.sh

docker exec butterfree-emulator start_emu.sh
```

You can set these launch variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `EMULATOR_TIMEOUT` | `300` | Startup timeout in seconds |
| `EMULATOR_PORT` | `5554` | Emulator console port |
| `EMULATOR_GPU` | `software` | GPU mode. Use `host` when the container can use a host GPU |
| `EMULATOR_ACCEL` | detected | Acceleration mode: `on`, `off`, or `auto` |
| `EMULATOR_LOG_FILE` | `/tmp/android-emulator.log` | Emulator log file |
| `XVFB_RESOLUTION` | `1280x1024x24` | Virtual display resolution |
