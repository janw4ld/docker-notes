# tonistiigi/xx

instead of using virtualisation to build for different target architectures,
we'll now use `tonistiigi/xx` which is a set of utils that can be used to easily
and conveniently cross-compile code for a different architecture, without having
to fiddle with configuring compiler toolchains, runtime libraries and such.

to make use of `xx`, we'll first add `--platform=$BUILDPLATFORM` to the `FROM`
directives in our build steps, this ensures that when we build for a different
target, the builder stages will run natively on the host architecture instead
of virtualised, this is made explicit by buildkit in the build logs where our
arm64 image's steps will be prefixed with `[linux/amd64->arm64]` instead of just
`[linux/amd64]` like in [3-multiplatform](../3-multiplatform/).

`$BUILDPLATFORM` and `$TARGETPLATFORM` are build arguments that buildkit injects
into the build context to help us determine the host and target architectures in
a multiplatform build.

```diff
--- ../3-multiplatform/Dockerfile	2024-05-10 14:15:29.234439651 +0300
+++ Dockerfile	2024-05-10 15:59:00.738242003 +0300
-FROM alpine:3.19 AS builder
+FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx
+
+
+FROM --platform=$BUILDPLATFORM alpine:3.19 AS builder
 
 RUN apk add --no-cache \
   make \
   cmake
```

then we'll follow `xx`'s instructions for building
[c & cpp code](https://github.com/tonistiigi/xx?tab=readme-ov-file#cc) on alpine

> The recommended method for C-based build is to use **`clang` via xx-clang**
> wrapper. Clang is natively a cross-compiler, but in order to use it, you also
> need a linker, `compiler-rt` or `libgcc`, and a C library(`musl` or `glibc`).
> All these are available as packages in Alpine and Debian based distros.
> **Clang and linker are binaries and should be installed for your build
> architecture while libgcc and C library should be installed for your target
> architecture.**
>
> On Alpine, there is no special package for `libgcc` so you need to install
> `gcc` package with `xx-apk` even though the build happens through `clang`.
> Default libc used in Alpine is Musl that can be installed with `musl-dev`
> package.


```diff
--- ../3-multiplatform/Dockerfile	2024-05-10 14:15:29.234439651 +0300
+++ Dockerfile	2024-05-10 15:59:00.738242003 +0300
 RUN apk add --no-cache \
+  clang \
+  lld
+
+# "install" the xx tools
+COPY --from=xx / /
+
+# magic argument injected by buildkit, and used by xx
+ARG TARGETPLATFORM
+# install the target platform's `libgcc` and `libc` headers
+RUN xx-apk add --no-cache \
   g++
 
 WORKDIR /src
 COPY --link CMakeLists.txt .
 COPY --link main.cpp .
 
-RUN CXX=g++ cmake .
-RUN make
+RUN cmake $(xx-clang++ --print-cmake-defines) .
+RUN make && xx-verify ./HelloKittyexe
 
 
 FROM scratch
```

we'll also modify our `main.cpp` to print the architecture it's running on:

```diff
--- ../3-multiplatform/main.cpp	2024-05-10 14:15:29.234439651 +0300
+++ main.cpp	2024-05-10 17:21:38.428598758 +0300
@@ -1,5 +1,14 @@
 #include <iostream>
-int main(int argc, char const *argv[]){
-    std::cout << "missed u"<<std::endl;
+#include <sys/utsname.h>
+#include <cerrno>
+
+int main() {
+    struct utsname buf;
+    if (uname(&buf) != EXIT_SUCCESS) {
+        std::cerr << "Error calling uname\n";
+        return 1;
+    }
+
+    std::cout << "CPU architecture: " << buf.machine << '\n';
     return 0;
 }
```

now let's build and push this:

```console
$ docker buildx build --platform=amd64,arm64 -t janw4ld/hellokitty:xx . --push
[+] Building 71.6s (34/34) FINISHED                                                               docker-container:priceless_ardinghelli
 => [internal] load build definition from Dockerfile                                                                                0.0s
 => => transferring dockerfile: 696B                                                                                                0.0s
 => [linux/amd64 internal] load metadata for docker.io/library/alpine:3.19                                                          2.2s
 => [linux/amd64 internal] load metadata for docker.io/tonistiigi/xx:latest                                                         2.2s
 => [auth] tonistiigi/xx:pull token for registry-1.docker.io                                                                        0.0s
 => [auth] library/alpine:pull token for registry-1.docker.io                                                                       0.0s
 => [internal] load .dockerignore                                                                                                   0.0s
 => => transferring context: 2B                                                                                                     0.0s
 => [linux/amd64 builder  1/10] FROM docker.io/library/alpine:3.19@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b  0.1s
 => => resolve docker.io/library/alpine:3.19@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b                0.1s
 => [internal] load build context                                                                                                   0.0s
 => => transferring context: 63B                                                                                                    0.0s
 => [linux/amd64 xx 1/1] FROM docker.io/tonistiigi/xx:latest@sha256:0cd3f05c72d6c9b038eb135f91376ee1169ef3a330d34e418e65e2a5c2e9c0d4  0.1s
 => => resolve docker.io/tonistiigi/xx:latest@sha256:0cd3f05c72d6c9b038eb135f91376ee1169ef3a330d34e418e65e2a5c2e9c0d4               0.1s
 => CACHED [linux/amd64 builder  4/10] COPY --from=xx / /                                                                           0.0s
 => CACHED [linux/amd64 builder  2/10] RUN apk add --no-cache   make   cmake                                                        0.0s
 => CACHED [linux/amd64 builder  3/10] RUN apk add --no-cache   clang   lld                                                         0.0s
 => CACHED [linux/amd64 builder  5/10] RUN xx-apk add --no-cache   g++                                                              0.0s
 => CACHED [linux/amd64 builder  6/10] WORKDIR /src                                                                                 0.0s
 => CACHED [linux/amd64 builder  8/10] COPY --link main.cpp .                                                                       0.0s
 => CACHED [linux/amd64 builder  7/10] COPY --link CMakeLists.txt .                                                                 0.0s
 => [linux/amd64->arm64 builder  5/10] RUN xx-apk add --no-cache   g++                                                             47.8s
 => [linux/amd64 builder  9/10] RUN cmake $(xx-clang++ --print-cmake-defines) .                                                     0.8s
 => [linux/amd64 builder 10/10] RUN make && xx-verify ./HelloKittyexe                                                               2.7s
 => [linux/amd64 stage-2 1/1] COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe                                             0.0s
 => [linux/amd64->arm64 builder  6/10] WORKDIR /src                                                                                 0.2s
 => [linux/amd64->arm64 builder  7/10] COPY --link CMakeLists.txt .                                                                 0.1s
 => [linux/amd64->arm64 builder  8/10] COPY --link main.cpp .                                                                       0.1s
 => => merging                                                                                                                      0.1s
 => [linux/amd64->arm64 builder  9/10] RUN cmake $(xx-clang++ --print-cmake-defines) .                                              0.9s
 => [linux/amd64->arm64 builder 10/10] RUN make && xx-verify ./HelloKittyexe                                                        3.6s
 => [linux/arm64 stage-2 1/1] COPY --from=builder /src/HelloKittyexe /app/HelloKittyexe                                             0.1s
 => exporting to image                                                                                                             15.5s
 => => exporting layers                                                                                                             0.4s
 => => exporting manifest sha256:99255b0447a47087cb6aa89dfc9c0746067718a628fc6c8ef7d05010b600c9d3                                   0.0s
 => => exporting config sha256:30c8db6a6816e4eba37d67b330d448e926b7b7609390e86cd611c843126b5d4a                                     0.0s
 => => exporting attestation manifest sha256:0826d611dae604fb252d0c1b933432947693d17ffe9410920bb960035e2b62f8                       0.1s
 => => exporting manifest sha256:fefe114fc599880425c2be950a7e9724a92873e28ef0d5b5141b5a41c46a6e79                                   0.0s
 => => exporting config sha256:670d6731e096f86ebf3d45c60b19a14cc3af0dc44f8af92c28976841d58d7d40                                     0.0s
 => => exporting attestation manifest sha256:5af249acd115e8c9419e634eb6cb589bb9def40ebc9a0bf8abd5e329d6a9fc67                       0.0s
 => => exporting manifest list sha256:0a339a1fa50296f04112bc00d25a2649db65f292edd6a53181c519b7b35f2508                              0.0s
 => => pushing layers                                                                                                               9.6s
 => => pushing manifest for docker.io/janw4ld/hellokitty:xx@sha256:0a339a1fa50296f04112bc00d25a2649db65f292edd6a53181c519b7b35f2508 5.2s
 => [auth] janw4ld/hellokitty:pull,push token for registry-1.docker.io                                                              0.0s
```

and to test it, we'll run the `arm64` image on our machine, `tonistiigi/binfmt`
allows virtualisation of foreign architectures both in `buildx` builds and
inside containers. this makes docker a very convenient virtualisation runtime.

```console
$ docker run --platform=arm64 janw4ld/hellokitty:xx
Unable to find image 'janw4ld/hellokitty:xx' locally
xx: Pulling from janw4ld/hellokitty
Digest: sha256:48d84f2c40dbfa30be22efa2360be6d1388f2bec66a0549ec83a5a4ba1baaf20
Status: Downloaded newer image for janw4ld/hellokitty:xx
CPU architecture: aarch64
```

we can also copy the binary out of the image and check its architecture with `file`:

```console
$ image=$(docker create --platform=arm64 janw4ld/hellokitty:xx) && docker cp $image:/app/HelloKittyexe .
Successfully copied 2.31MB to /home/misc/work/ana/docker-notes/by-example/1-distributing-builds/4-cross-compiled/.
$ file HelloKittyexe
HelloKittyexe: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, BuildID[xxHash]=31b35d2880a02b92, with debug_info, not stripped
```

## further reading

- [Faster multiplatform builds - Tonis Tiigi - Docker blog](https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/)
- [Using CMake toolchain files for cross-compilation - Mastering CMake](https://cmake.org/cmake/help/book/mastering-cmake/chapter/Cross%20Compiling%20With%20CMake.html)
