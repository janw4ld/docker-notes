# Dockerfile 2, leaner and meaner?

in [1-basic-build](../1-basic-build/readme.md) we built a minimal `alpine` image 
that contained `libstdc++` and our `HelloKitty` executable. For security and
hardening purposes, it's better to not distribute any distro or base image at
all. We can do so by creating our final-stage image `FROM scratch`, which is an
empty image. But `FROM scratch` requires manually copying each and every runtime
dependency into the image. This is a tedious process that can be avoided by
statically linking our executable so that it contains all its dependencies. So
working towards our goal of using a `FROM scratch` image we'll modify the
`CMakeLists.txt` file to statically link our project as follows:

```diff
--- ../1-basic-build/CMakeLists.txt	2024-05-10 08:09:10.223873779 +0300
+++ CMakeLists.txt	2024-05-10 08:40:09.069293689 +0300
@@ -1,3 +1,8 @@
 project(HelloKitty)
 cmake_minimum_required(VERSION 3.22.1)
-add_executable(HelloKittyexe main.cpp)
+
+set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
+set(BUILD_SHARED_LIBS OFF)
+set(CMAKE_EXE_LINKER_FLAGS "-static")
+
+add_executable(HelloKittyexe main.cpp)
```

after updating `CMakeLists.txt` we can drop `RUN apk add --no-cache libstdc++`
from our dockerfile steps:

```diff
--- ../1-basic-build/two-stage.Dockerfile	2024-05-10 09:22:21.637676608 +0300
+++ static.Dockerfile	2024-05-10 09:58:32.459272805 +0300
@@ -15,13 +15,8 @@
 RUN make
 
 
-# we're adding a second FROM directive, to continue building in a new clean env
 FROM alpine:3.19
 
-RUN apk add --no-cache \
-  libstdc++
-
 COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe
 
 CMD ["/app/HelloKittyexe"]
```

then build and run the image:

```console
$ docker buildx build \
    -t hellokitty:static \
    -f static.Dockerfile \
    .

[+] Building 38.0s (14/14) FINISHED                                                                                       docker:default
 => [internal] load .dockerignore                                                                                                   0.1s
 => => transferring context: 2B                                                                                                     0.0s
 => [internal] load build definition from static.Dockerfile                                                                         0.1s
 => => transferring dockerfile: 351B                                                                                                0.0s
 => [internal] load metadata for docker.io/library/alpine:3.19                                                                      2.0s
 => [stage-1 1/2] FROM docker.io/library/alpine:3.19@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b        0.1s
 => => resolve docker.io/library/alpine:3.19@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b                0.0s
 => [internal] load build context                                                                                                   0.1s
 => => transferring context: 399B                                                                                                   0.0s
 => [builder 2/8] RUN apk add --no-cache   make   cmake                                                                             9.4s
 => [builder 3/8] RUN apk add --no-cache   g++                                                                                     24.1s
 => [builder 4/8] WORKDIR /src                                                                                                      0.3s
 => [builder 5/8] COPY --link CMakeLists.txt .                                                                                      0.1s
 => [builder 6/8] COPY --link main.cpp .                                                                                            0.1s
 => [builder 7/8] RUN CXX=g++ cmake .                                                                                               0.7s
 => [builder 8/8] RUN make                                                                                                          0.9s
 => [stage-1 2/2] COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe                                                         0.1s
 => exporting to image                                                                                                              0.1s
 => => exporting layers                                                                                                             0.0s
 => => writing image sha256:234d2e960423a3f5273e692e3cd91f8046111f2a6a429cfb630a0e0430bba867                                        0.0s
 => => naming to docker.io/library/hellokitty:static                                                                                0.0s

$ docker run hellokitty:static
missed u
```

> [!TIP]
> to repro:
>
> ```bash
> docker buildx build \
>   -t hellokitty:static \
>   -f static.Dockerfile \
>   . \
> && docker run hellokitty:static
> ```

and we can even drop `alpine` from the final image completely:

```diff
--- static.Dockerfile	2024-05-10 09:58:32.459272805 +0300
+++ from-scratch.Dockerfile	2024-05-10 10:12:38.358674901 +0300
@@ -15,7 +15,7 @@
 RUN make
 
 
-FROM alpine:3.19
+FROM scratch
 
 COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe
``` 

```console
$ docker buildx build \
    -t hellokitty:from-scratch \
    -f from-scratch.Dockerfile \
    . \
  && docker run hellokitty:from-scratch

[+] Building 1.9s (14/14) FINISHED                                                                                         docker:default
... snip ...
 => => writing image sha256:48b25cf7924cc709ad0a23301b78b9d1135e6ee6bb55cfb30b6af8f7cab7deb3                                         0.0s
 => => naming to docker.io/library/hellokitty:from-scratch                                                                           0.0s
missed u
```

our `from-scratch` image now contains only our `HelloKittyexe` app

```console
$ docker image ls hellokitty
REPOSITORY   TAG            IMAGE ID       CREATED              SIZE
hellokitty   from-scratch   48b25cf7924c   About a minute ago   2.1MB
hellokitty   static         234d2e960423   8 minutes ago        9.47MB
hellokitty   two-stage      3f4aa916656e   2 hours ago          10.3MB
hellokitty   naive          9883f974623c   2 hours ago          271MB

$ docker run -it --rm hellokitty:from-scratch ls / # no ls inside the image
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: exec: "ls": executable file not found in $PATH: unknown.
```

## But why?

security; the less programs you package, the less attack surface you have,
especially when you don't distribute any shell or package manager in your image
