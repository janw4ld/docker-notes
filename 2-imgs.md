# Imgs

- an image is a lightweight, standalone, executable package that includes everything needed to run a piece of software, including the code, libraries, environment variables, and config files.

- A Docker image is built up from a series of read-only layers, each of which represents a Dockerfile instruction. These layers are stacked and each one is a delta of the changes from the previous layer.

You can think of a Docker image as a snapshot of a Docker container. Images are created with the `docker build` command, either by using a Dockerfile or through a previously committed container. Once an image is created, it can be used to create new containers with the `docker run` command.

- Docker images should ideally be as small as possible. They serve as templates for creating containers. A smaller image size can lead to faster deployment and less storage usage, making it a more efficient starting point for container creation.

## Img Pull

- imgs is pulled from a registry `hup.docker.com`, which is a collection of repositories.
- A repository is a collection of related images (and their tags) - often different versions of the same application.
- image name is in the format `repository:tag`. If the tag is omitted, Docker will pull the image tagged as `latest` by default.
- to pull an image, use the `docker image pull <image-name>:<tag>` command.
- to pull an image from a different registry, use the `docker image pull <registry>/<image-name>:<tag>` command.

## manifest file snd multi-arch imgs

- A manifest file is a JSON file that contains information about the different architectures that an image is available for.
- A multi-arch image is an image that contains the same application, but built for different architectures.
- When you pull a multi-arch image, Docker will automatically pull the image that is compatible with your system's architecture.
- If you try to pull an image that is incompatible with the Docker host, Docker will return an error message. This could happen, for example, if you're trying to pull an image built for a different CPU architecture. Docker images are often built specifically for certain platforms (like AMD64, ARM, etc.), and if you try to run an image on a platform it wasn't built for, it won't work.
**The error message might look something like this:**
`no matching manifest for linux/amd64 in the manifest list entries`

--------------------------------------------------

Docker images are a crucial part of the Docker ecosystem. They are the basis of containers. When you create a Docker container, you're actually creating it from a Docker image. Here are some additional points to consider:

- **Image Layers**: Docker images are made up of layers. These layers are stacked on top of each other to form the final image. When you change something in a Docker image, only the layer that was changed is updated. This is part of what makes Docker images so lightweight.

- **Image Registries**: Docker images are typically stored in a registry. Docker Hub is a popular public registry, but you can also use private registries. You can pull images from a registry to your local system, or push your own images to a registry.

- **Image Tags**: Docker images can have tags, which are useful for versioning. For example, you might have a `v1.0` tag for the first stable release of your application, a `v2.0` tag for the second release, and so on. You can also use the `latest` tag to represent the most recent version.

- **Building Images**: You can build your own Docker images using a Dockerfile. This is a text file that contains instructions for how to build the image, such as what base image to use, what code to copy into the image, what commands to run, and so on.

Remember, the smaller the Docker image, the less disk space it uses, and the faster it can be transferred and launched. So, it's a good practice to try to minimize the size of your Docker images as much as possible.
