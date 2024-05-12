# Docker use cases

containerisation mainly revolves around eliminating the "it works on my machine"
problem by declaring the environment used for building and developing software
in plaintext files that can be committed to git and shared with a team, it has
a bunch of use cases that help the software development process, here are some
of them:

1. packaging and distributing applications with all their dependencies
   - [simple c++ example with multi-stage dockerfile](./1-distributing-builds/1-basic-build/)
   - [a `FROM scratch` final image with static linking](./1-distributing-builds/2-from-scratch/)
   - [a multiplatform image (amd64 & arm64 support) with qemu virtualisation](./1-distributing-builds/3-multiplatform/)
   - [a multiplatform image with cross-compilation](./1-distributing-builds/4-cross-compiled/)
1. creating controlled reproducible environments for development and testing
1. isolating applications and their dependencies during runtime

these use cases will be demonstrated by examples in this directory.

> [!TIP]
> VSCode has a dev containers extension that allows you to easily open a project
> inside a container, it's a great way to get started with using containers for
> development. it also has a docker extension to help with writing dockerfiles.
