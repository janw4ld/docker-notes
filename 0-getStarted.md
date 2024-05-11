# Docker

## Installation

```bash
 curl -fsSL https://get.docker.com -o get-docker.sh
 sudo sh get-docker.sh
```

## First Docker Command

when u try run `docker info` u will get the following output:

```bash
$ docker info
Client: Docker Engine - Community
 Version:    26.1.2
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.14.0
    Path:     /usr/libexec/docker/cli-plugins/docker-buildx
  compose: Docker Compose (Docker Inc.)
    Version:  v2.27.0
    Path:     /usr/libexec/docker/cli-plugins/docker-compose

Server:
ERROR: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.45/info": dial unix /var/run/docker.sock: connect: permission denied
errors pretty printing info
```

to resolve the permission error you must add `sudo` or be in the `docker` group.

```bash
$ sudo usermod -aG docker $USER

$ sudo  getent group | grep docker
docker:x:999:hala
```

## 1. fedora Image

1. pull the image from the docker hub

    ```bash
    $ docker image pull fedora

    $ docker image ls
    REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
    fedora       latest    5e22da79803c   2 weeks ago   222MB

    ```

2. make a container from the image

    ```bash
    $ docker container create -it fedora bash
    02b22e999591ae28aaeb43845504c4ed9ecc0d79373d147c80f7cf797819c231
    $ docker container ls -a
    CONTAINER ID   IMAGE     COMMAND   CREATED              STATUS    PORTS     NAMES
    02b22e999591   fedora    "bash"    About a minute ago   Created             wizardly_ramanujan
    ```

3. start the container

    ```bash
    $ docker container start -ai wizardly_ramanujan

    $$ cat /etc/*release
    Fedora release 40 (Forty)
    NAME="Fedora Linux"
    VERSION="40 (Container Image)"
    ID=fedora
    VERSION_ID=40
    VERSION_CODENAME=""
    PLATFORM_ID="platform:f40"
    PRETTY_NAME="Fedora Linux 40 (Container Image)"
    ANSI_COLOR="0;38;2;60;110;180"
    LOGO=fedora-logo-icon
    CPE_NAME="cpe:/o:fedoraproject:fedora:40"
    DEFAULT_HOSTNAME="fedora"
    HOME_URL="https://fedoraproject.org/"
    DOCUMENTATION_URL="https://docs.fedoraproject.org/en-US/fedora/f40/system-administrators-guide/"
    SUPPORT_URL="https://ask.fedoraproject.org/"
    BUG_REPORT_URL="https://bugzilla.redhat.com/"
    REDHAT_BUGZILLA_PRODUCT="Fedora"
    REDHAT_BUGZILLA_PRODUCT_VERSION=40
    REDHAT_SUPPORT_PRODUCT="Fedora"
    REDHAT_SUPPORT_PRODUCT_VERSION=40
    SUPPORT_END=2025-05-13
    VARIANT="Container Image"
    VARIANT_ID=container
    Fedora release 40 (Forty)
    Fedora release 40 (Forty)
    $$ exit 
    exit
    $ docker container ls -a
    CONTAINER ID   IMAGE     COMMAND   CREATED          STATUS                      PORTS     NAMES
    02b22e999591   fedora    "bash"    15 minutes ago   Exited (0) 24 seconds ago             wizardly_ramanujan
    ```

    the container is exited because the command `bash` is finished.
    the container only runs one process, if the process is finished the container will be exited.

## 2. python Image

  ```bash
  $ docker image pull python
  $ docker image ls
  REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
  fedora       latest    5e22da79803c   2 weeks ago   222MB
  python       latest    6825e5e3d255   4 weeks ago   1.02GB
  $ docker container run -it python
  Python 3.12.3 (main, Apr 24 2024, 11:17:35) [GCC 12.2.0] on linux
  Type "help", "copyright", "credits" or "license" for more information.
  >>> print("hrlp")
  hrlp
  >>> exit
  >>> exit()
  ```

note that it runs `python3` command by default.

```bash
$ docker container ls -a
CONTAINER ID   IMAGE     COMMAND     CREATED          STATUS                       PORTS     NAMES
8ed4d37661a2   python    "python3"   5 minutes ago    Exited (0) 4 minutes ago               eager_yonath
02b22e999591   fedora    "bash"      32 minutes ago   Exited (0) 17 minutes ago              wizardly_ramanujan
```

but you can run any command by specifying it.

```bash
$ docker container run -it python /bin/bash

$$ ps
    PID TTY          TIME CMD
      1 pts/0    00:00:00 bash
      8 pts/0    00:00:00 ps
$$ python3
Python 3.12.3 (main, Apr 24 2024, 11:17:35) [GCC 12.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> 0+0
0
>>> exit()
$$ exit
exit
$ docker container ls -a
CONTAINER ID   IMAGE     COMMAND       CREATED          STATUS                        PORTS     NAMES
157ca859533b   python    "/bin/bash"   5 minutes ago    Exited (0) 2 minutes ago                gracious_jepsen
```

## Delete Containers and Images

```bash
docker container rm {{$CONTAINER_ID or $CONTAINER_NAME}} 
docker image rm {{$IMAGE_ID or $IMAGE_NAME}}
```

**Why shouldn't i merge all layers into one?**

- because the layers are cached, so if you change one layer, the other layers will not be rebuilt.
- the layers are shared between images, so if you have two images that share the same layers, the layers will be downloaded only once.
