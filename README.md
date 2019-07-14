# Autobuild on Docker Hub

Example for advanced options (hooks) for Autobuild on Docker Hub with ARM-Images!

* [Advanced options for Autobuild](https://docs.docker.com/docker-hub/builds/advanced/) inspired by [https://stackoverflow.com/a/54595564](https://stackoverflow.com/questions/54578066/how-to-build-a-docker-image-on-a-specific-architecture-with-docker-hub/54595564#54595564).
* additional software/tools used: [qemu-user-static from multiarch](https://github.com/multiarch/qemu-user-static) and [manifest-tool](https://github.com/estesp/manifest-tool). Thanks for the great things!

* Base-Images: [balena.io Base-Images](https://www.balena.io/docs/reference/base-images/base-images/) and [official Images](https://github.com/docker-library/official-images#architectures-other-than-amd64).
