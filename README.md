# Autobuild on Docker Hub

Example for advanced options (hooks) for Autobuild on Docker Hub with ARM-Images!  

A possible solution for:
* [Support automated ARM builds](https://github.com/docker/hub-feedback/issues/1261)
* [Automated multi-arch builds using manifest file](https://github.com/docker/hub-feedback/issues/1779)
* [No way to specify arch in docker {run,pull,build}](https://github.com/moby/moby/issues/36552)

## Information

You can use the [example here](https://github.com/Tob1asDocker/dockerhubhooksexample) from me or also [another possibility](https://github.com/rmoriz/multiarch-test).  

Details to build:  
* [Advanced options for Autobuild](https://docs.docker.com/docker-hub/builds/advanced/) inspired by [https://stackoverflow.com/a/54595564](https://stackoverflow.com/questions/54578066/how-to-build-a-docker-image-on-a-specific-architecture-with-docker-hub/54595564#54595564).
* additional software/tools used: [qemu-user-static from multiarch](https://github.com/multiarch/qemu-user-static) and [manifest-tool](https://github.com/estesp/manifest-tool). Thanks for the great things!
* Base-Images: [balena.io Base-Images](https://www.balena.io/docs/reference/base-images/base-images/) and/or [official Images](https://github.com/docker-library/official-images#architectures-other-than-amd64).


## Project tree

```
.
├── hooks
    ├── post_checkout
    ├── pre_build
    ├── build     # optional
    └── post_push
├── alpine.armhf.v1_11.Dockerfile
├── alpine.armhf.Dockerfile
├── alpine.x86_64.Dockerfile
├── debian.armhf.Dockerfile
└── debian.x86_64.Dockerfile
```


## Examples

* only ARM: [rpi-nginx](https://github.com/Tob1asDocker/rpi-nginx)
* ARM and x86_64: [alpine-nginx-php](https://github.com/Tob1asDocker/alpine-nginx-php)
