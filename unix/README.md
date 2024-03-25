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
Once the android sdk image is ready we can add Gradle and Kotlin to speed up CI build time. This step is not necessary to build android projects as Kotlin and Gradle are downloaded by their plugins. 

`~/Matee/docker/images/gradle+kotlin` contains `gradle` directory, `gradlew` file and `Dockerfile`. This dir structure is default for `gradlew` to correctly fetch Gradle. Gradle version which will be installed is defined in `~/Matee/docker/images/gradle+kotlin/gradle/wrapper/gradle-wrapper-properties`. Currently is set to `8.2.1-all`. 

Kotlin version is defined in `Dockerfile` and is set to `1.9.21`.

We can use same steps to create gradle+kotlin image as for example above (use `j17-anroid` image as base):

```bash;
docker build --build-arg ANDROID_IMAGE=j17-android -t j17-android-gradle .
```

### Docker hub
Images must be stored in some Docker registry in order to be pulled in Github/Gitlab ... jobs. Matee images are published on [Dockerhub](https://hub.docker.com/repositories/mateedevs). We could also create a private docker registry which would be hosted on CI machine but it is more convinient to use Dockerhub.  

Login is needed to push images into Docker hub:

```bash;
# This step is redundant as Matee should already be logged in on CI machine.  
docker login
```
Push image: 

```bash;
docker push mateedevs/bulbasaur
```
Image should be ready to use after that.

# CI integration

## Github action

**Basic example:**

```
jobs:
  Check:
    name: Lint & Build
    runs-on: [self-hosted, pikachu]
    container: mateedevs/charmander
    steps:
      - name: Checkout repo
        uses: actions/checkout@v3

      - name: Run lint
        run: ./gradlew ktlintCheck
...
```
`container` - runner will create a docker container in which job will run 
`mateedevs/charmander` - container image

**Volume example:**

Some projects might depend on files which are not part of a repository (e.g. Stravenky version file). Docker volume can be used to solve this usecase. 

```
jobs:
  build:
    name: Create new build
    runs-on: [ self-hosted, pikachu ]
    container:
      image: mateedevs/charmander
      volumes:
        - version-stravenky:/__w/version-stravenky
...
```
`volumes` - creates a volume which will be shared between docker and local file system

⚠️ Beaware that local Github runner home file structure is different from container file structure (e.g. `/work` -> `/__w`). Update script files accordingly if needed (e.g. `/muj-up/scripts/version_code_generator.sh`).

## Gitlab CI

Docker executor is set for gitlab runner so there is no need to define anything else besides an image.  

```
.android:
  image: mateedevs/bulbasaur
  before_script:
...
```

## Jetbrains Space CI

Similar to Github actions.

```
job("[AN] Build Debug") {
...
    container(
        displayName = "Lint&Build",
        image = "mateedevs/charmander",
    ) {
        kotlinScript { api ->
            api.gradlew("ktlintCheck")
        }
    }
...
}
```

# Android emulator

Android emulator `Dockerfile` is located in `~/Matee/docker/images/android/emulator`.

Script files which can run the emulator are located in `~/Matee/docker/images/android/emulator/emu_scripts`.

Corresponding Dockerhub image is `mateedevs/charmander-emulator`. This image can be used to run android UI tests.

![Snímek obrazovky z 2024-03-25 16-40-33](https://github.com/MateeDevs/ci-setup/assets/31855599/cba40d9c-1972-415f-a59b-ae9abb532d07)

**Github actions example:**

```
    runs-on: [self-hosted, pikachu]
    container: 
       image: mateedevs/charmander-emulator
       options: --privileged
    steps:
      - name: UI tests
        run: |
          start_emu_headless.sh
          ./gradlew :android:customer-app:connectedCheck
...
```

`options: --privileged` - container will be created with privileged mode, needed for HW acceleration

`start_emu_headless.sh` - launches android emulator in headless mode (timeout is 300s)


`~/emu_scripts` contains several scripts to handle emulator:

- `start_emu_headless.sh` - launches emulator in headless mode
- `start_emu.sh` - launches emulator (headed mode)
- `start_vnc.sh` - creates vnc connection between docker container and CI machine, used to test headed emulator

⚠️ The `start_emu.sh` script will start the emulator in a visible mode, therefore it should not be used for integration with a pipeline such as GitHub Actions etc. Instead, use the `start_emu_headless.sh` script.

**Headed android emulator**

This could be useful to see what might gone wrong in your UI tests. 

 1. The following command must be used to initiate the Docker container:
 ```bash;
docker run -it -d -p 5900:5900 --name androidContainer -e VNC_PASSWORD=123 --privileged j17-android-emulator
```
 2. Instantiate the VNC service by running:
 ```bash;
docker exec --privileged -it androidContainer bash -c "start_vnc.sh"
```
 3. Connect to the VNC server via Remmina (installed on CI machine)
![Snímek obrazovky z 2024-03-25 16-39-35](https://github.com/MateeDevs/ci-setup/assets/31855599/6dbfd2ae-3550-4c76-aaf8-6d199c405aa4)

 4. Open dash terminal in vnc viewer and launch the emulator:
 ```bash;
./start_emu.sh
```

![emulator](https://github.com/MateeDevs/ci-setup/assets/31855599/d8a26e60-55ff-4da5-9b7d-e851193832c5)
