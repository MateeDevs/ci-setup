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
|   |   |   |  +-- repeato/
|   |   |   |  +-- stravenky/
|   |   |   |  +-- skyseat/
...
```
Every directory should contain a `Dockerfile` which specifies an environment used for image build and an example of build commands.  e.g. `~/Matee/docker/java`:
```bash
docker build -t java-17 .
```

# Runners
Configured runners:
- Github
- Gitlab
- Jetbrains Space

Github and Gitlab runners are running as services and will automatically start after the system reboot. ⚠️ **Runner for Space does not yet support this functionality and needs to be launched manually**. 

`~/Matee/space-runner`
```bash;
sudo ./worker.sh start --serverUrl https://matee.jetbrains.space --token {RUNNER_TOKEN}
```
or
```bash;
sudo ./space_run.sh
```
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
