# Matee CI – unix

Matee Unix CI in combination with [Docker](https://www.docker.com/) is currently used for Android projects and it's running on dedicated machine with Ubuntu.

Supported projects:
- [Stravenky](https://github.com/MateeDevs/muj-up)
- [Repeato](https://gitlab.com/repeato/kmm)
- [Skyseat](https://github.com/MateeDevs/SkySeat)

# Machine overview

Current OS is Ubuntu 22.04 and there is not much applications/tools besides Docker and Java.

| Tool                | Version                    |
|-----------------------|--------------------------------|
| Docker Engine | 25.0.4 |
| Docker Compose | 2.24.7  |
| Java | 17 |

Dir structure:

```
+-- matee@matee-ci
|   +-- Matee/ 
|   |   +-- docker/
|   |   |   +-- base/
|   |   |   +-- images/
|   |   |   |  +-- android/
|   |   |   |   |  +-- emulator/
|   |   |   |  +-- java/
|   |   |   |  +-- gradle+kotlin/
|   |   |   |   |  +-- gradle/
|   |   |   |  +-- twine/
...
```
Every directory should contain a `Dockerfile` which specifies an image build environment and an example of build commands.  e.g. `~/Matee/docker/java`:
```bash
docker build -t java-17 .
```

# Runners
Configured runners:
- Github
- Gitlab
- Jetbrains Space

Github and Gitlab runners are running as services and will automatically start after the system reboot.

### Github runner troubleshooting 
Runner directory path `~/Matee/actions-runner/` 

```bash;
# Check service status
sudo ./svc.sh status
```
```bash;
# Start runner service
sudo ./svc.sh start 
```
```bash;
# Single runner start, won´t survive system reboot
./run.sh
```
### Gitlab runner troubleshooting 
Gitlab runner is **gitlab-runner** binary

```bash;
# Check service status
sudo gitlab-runner status
```
```bash;
# Start runner service
sudo gitlab-runner start
```

### Jetbrains Space runner troubleshooting 
⚠️ **Runner for Space does not yet support service functionality and needs to be launched manually**. 

Runner directory path `~/Matee/space-runner`
```bash;
sudo ./worker.sh start --serverUrl https://matee.jetbrains.space --token {RUNNER_TOKEN}
```
or
```bash;
sudo ./space_run.sh
```

# Docker images
Available docker images can be shown by:
```bash;
docker images
```
![Snímek obrazovky z 2024-03-22 13-05-18](https://github.com/MateeDevs/ci-setup/assets/31855599/b8087310-e061-4aa6-801b-21c530c202cd)

Images with `mateedevs/` preffix are published on [Dockerhub](https://hub.docker.com/). Every image shoud have some description of inlcuded tools.
| `mateedevs/charmander-emulator image` |
|:--:| 
| ![Snímek obrazovky z 2024-03-22 13-31-10](https://github.com/MateeDevs/ci-setup/assets/31855599/2649fd68-95e4-44c7-9f28-6b13ed2795a4) | 

## Image build
`Dockerfile` is needed to build a docker image. Base files can be found inside `~/Matee/docker` directory. This directory contains docker files to build images for Java, AndroidSDK, gradle+kotlin, Twine or Android emulator. 

To build an image, navigate to a desired directory and run:
```bash;
docker build -t {IMAGE_NAME} .
```
`-t` image tag name (e.g. java-17)

`.`  current directory (`Dockerfile` location)

Most of the base docker files are generic and image builds can be parametrized or default parametrs are used.

### Example Java image build
To build a Java 17 image we can use default parameters of the docker file or we can use build arguments.

```bash;
docker build -t java-17 .
```
```bash;
docker build --build-arg VERSION=17 -t java-17 .
```

or for Java 11:
```bash;
docker build --build-arg VERSION=11 -t java-11 .
```

### Example Android image build
Java and AndroidSDK is needed to run android build commands. We can use previously created image as base to build an android image with specific Java version.

```bash;
docker build --build-arg JAVA_IMAGE=java-17 -t j17-android .
```


