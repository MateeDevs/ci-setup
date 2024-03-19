# Matee CI – unix

Matee Unix CI in combination with [Docker](https://www.docker.com/) is currenty used for Android projects and it's running on dedicated machine with Ubuntu.

Supported projects:
- [Straveny](https://github.com/MateeDevs/muj-up)
- [Repeato](https://gitlab.com/repeato/kmm)
- [Skyseat](https://github.com/MateeDevs/SkySeat)

# Overview

| Tool                | Version                    |
|-----------------------|--------------------------------|
| Docker Engine | 25.0.4 |
| Docker Compose | 2.24.7  |

```
+-- matee@matee-ci
|   +-- Matee/ 
|   |   +-- docker/
|   |   |   +-- base/
|   |   |   +-- images/
|   |   |   |  +-- android/
|   |   |   |   |  +-- emulator/
|   |   |   |  +-- java/
|   |   |   |  +-- repeato/
|   |   |   |  +-- stravenky/
|   |   |   |  +-- skyseat/
...
```
Every directory should contain a `Dockerfile` which specifies an environment used for image built and commented example of build commands.  e.g. `~/Matee/docker/java`:
```bash
docker build -t java-17 .
```

# Runners
Configured runners:
- Github
- Gitlab
- Jetbrains Space

Runners for Github and Gitlab are configured as services and will automatically run after the system reboot. ⚠️ **Runner for Space does not support this functionality at the moment and needs to be launched manually**. 

`~/Matee/space-runner`
```bash;
sudo ./worker.sh start --serverUrl https://matee.jetbrains.space --token {RUNNER_TOKEN}
```
or
```bash;
sudo ./space_run.sh
```
