# Dockerfile

Dockerfiles are recipes for building the configuration and environment needed
to package and run a containerised application. They consist of instructions
that run inside a base image and interact with the build context (usually the
directory our `Dockerfile` is in)

We're gonna build our
[CMake project 1](https://github.com/hlarda/cmake/tree/main/1/cmake) inside
Docker as an example. It's a good practice to keep your docker images and
containers lightweight so we'll pick `alpine` linux as our base distro, default
alpine images are ~6MiB in size. Alpine is different to mainstream distros in
some aspects but we don't need to worry about them now.

Our build environment consists of CMake & GNU Make as well as the `g++`
compiler, so a Dockerfile to build it can look like this:


```dockerfile
FROM alpine:3.19 AS builder

RUN apk add --no-cache \
  make \
  cmake

RUN apk add --no-cache \
  g++

WORKDIR /src # this creates directory `/src` then cds into it

# using --link when copying external files helps with caching, but doesn't work
# well with symlinks, so be careful when using it to avoid unexpected issues
COPY --link CMakeLists.txt .
COPY --link main.cpp .

RUN CXX=g++ cmake . && make

# this is bad practice, don't distribute your source code

CMD ["./HelloKittyexe"]
```

we'll save this file as `naive.Dockerfile` then use `docker build` to create an
image from it. the used command options are

- `-t hellokitty:naive` adds the a "tag" or human readable name to the image
- `-f naive.Dockerfile` specifies which dockerfile to use
- `.` specifies the build context, which is the directory our dockerfile
  instructions will interact with, so for example `COPY main.cpp` in the
  dockerfile only knows which `main.cpp` to copy because we're inside the
  `1-basic-build` directory and passed the build context `.` (which means here)

```console
$ docker build \
    -t hellokitty:naive \
    -f naive.Dockerfile \
    .

[+] Building 1.2s (12/12) FINISHED                                                                                       docker:default
 => [internal] load .dockerignore                                                                                                  0.0s
 => => transferring context: 2B                                                                                                    0.0s
 => [internal] load build definition from naive.Dockerfile                                                                         0.0s
 => => transferring dockerfile: 341B                                                                                               0.0s
 => [internal] load metadata for docker.io/library/alpine:3.19                                                                     1.1s
 => [1/7] FROM docker.io/library/alpine:3.19@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b               0.0s
 => [internal] load build context                                                                                                  0.0s
 => => transferring context: 62B                                                                                                   0.0s
 => CACHED [2/7] RUN apk add --no-cache   make   cmake                                                                             0.0s
 => CACHED [3/7] RUN apk add --no-cache   g++   musl-dev                                                                           0.0s
 => CACHED [4/7] WORKDIR /src                                                                                                      0.0s
 => CACHED [5/7] COPY --link CMakeLists.txt .                                                                                      0.0s
 => CACHED [6/7] COPY --link main.cpp .                                                                                            0.0s
 => CACHED [7/7] RUN CXX=g++ cmake . && make                                                                                       0.0s
 => exporting to image                                                                                                             0.0s
 => => exporting layers                                                                                                            0.0s
 => => writing image sha256:9883f974623c15e8014f228dfce99d73870f4b8d6304007b19ed19762f250a6c                                       0.0s
 => => naming to docker.io/library/hellokitty:naive                                                                                0.0s

$ docker run hellokitty:naive
missed u

$ docker run -it --rm \
    hellokitty:naive \
    cat /src/main.cpp
#include <iostream>
int main(int argc, char const *argv[]){
    std::cout << "missed u"<<std::endl;
    return 0;
}
```

> [!TIP]
> to easily reproduce the above, you can run this:
>
> ```bash
> docker build \
>   -t hellokitty:naive \
>   -f naive.Dockerfile \
>   . \
> && docker run hellokitty:naive \
> && docker run -it --rm \
>   hellokitty:naive \
>   cat /src/main.cpp
> ```

This is not good, we shipped a huge package with all our dev dependencies and
the source code, to avoid this Docker introduced multi-stage builds, where we
can build the code in one image and copy pre-compiled binaries to another clean
image.

```diff
--- naive.Dockerfile	2024-05-10 09:21:48.697008366 +0300
+++ two-stage.Dockerfile	2024-05-10 09:22:21.637676608 +0300
@@ -11,9 +11,17 @@
 COPY --link CMakeLists.txt .
 COPY --link main.cpp .
 
-RUN CXX=g++ cmake . && make
+RUN CXX=g++ cmake .
+RUN make
 
-# this is bad practice, don't distribute your source code
 
-CMD ["./HelloKittyexe"]
+# we're adding a second FROM directive, to continue building in a new clean env
+FROM alpine:3.19
+
+RUN apk add --no-cache \
+  libstdc++
+
+COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe
+
+CMD ["/app/HelloKittyexe"]
```

notice we had to install `libstdc++` in the final image because we dynamically
link our project to the stdlib, otherwise running the binary fails with
`/app/HelloKittyexe: file not found`. i also split the build command into two
layers to cache CMake's generated build scripts.

now, let's build this

```console
$ docker build \
    -t hellokitty:two-stage \
    -f two-stage.Dockerfile \
    .

[+] Building 0.9s (14/14) FINISHED                                                                                       docker:default
 => [internal] load .dockerignore                                                                                                  0.0s
 => => transferring context: 2B                                                                                                    0.0s
 => [internal] load build definition from two-stage.Dockerfile                                                                     0.0s
 => => transferring dockerfile: 405B                                                                                               0.0s
 => [internal] load metadata for docker.io/library/alpine:3.19                                                                     0.8s
 => [builder 1/7] FROM docker.io/library/alpine:3.19@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b       0.0s
 => [internal] load build context                                                                                                  0.0s
 => => transferring context: 62B                                                                                                   0.0s
 => CACHED [stage-1 2/3] RUN apk add --no-cache   libstdc++                                                                        0.0s
 => CACHED [builder 2/8] RUN apk add --no-cache   make   cmake                                                                     0.0s
 => CACHED [builder 3/8] RUN apk add --no-cache   g++   musl-dev                                                                   0.0s
 => CACHED [builder 4/8] WORKDIR /src                                                                                              0.0s
 => CACHED [builder 5/8] COPY --link CMakeLists.txt .                                                                              0.0s
 => CACHED [builder 6/8] COPY --link main.cpp .                                                                                    0.0s
 => CACHED [builder 7/8] RUN CXX=g++ cmake .                                                                                       0.0s
 => CACHED [bulider 8/8] RUN make                                                                                                  0.0s
 => CACHED [stage-1 3/3] COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe                                                 0.0s
 => exporting to image                                                                                                             0.0s
 => => exporting layers                                                                                                            0.0s
 => => writing image sha256:3f4aa916656e739db94ad49a2fa741608d92cb19b0a2c52708d3b1957743378e                                       0.0s
 => => naming to docker.io/library/hellokitty:two-stage                                                                            0.0s

$ docker run hellokitty:two-stage
missed u

$ docker run -it --rm \
    hellokitty:two-stage \
    ls -a /src
ls: /src: No such file or directory
```
> [!TIP]
> to repro:
> 
> ```bash
> docker buildx build \
>   -t hellokitty:two-stage \
>   -f two-stage.Dockerfile \
>   . \
> && docker run hellokitty:two-stage \
> && docker run -it --rm \
>   hellokitty:two-stage \
>   ls -a /src
> ```

the two-stage image doesn't have our source code & is a lot more lightweight,
resulting in better experience for everyone using it :)

```console
$ docker image ls hellokitty
REPOSITORY   TAG         IMAGE ID       CREATED          SIZE
hellokitty   two-stage   3f4aa916656e   35 minutes ago   10.3MB
hellokitty   naive       9883f974623c   37 minutes ago   271MB
```

