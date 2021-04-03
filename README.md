# Autobuild on Docker Hub

**Example for advanced options (hooks) and buildx for Autobuild on Docker Hub to build Multiarch Images (x86_64 and ARM)**

## Information

With buildx you can build multiarch Images on Docker Hub from a GitHub/Bitbucket Repository.

More Details:  
* [Advanced options for Autobuild](https://docs.docker.com/docker-hub/builds/advanced/)
* [buildx](https://docs.docker.com/buildx/working-with-buildx/)
* [Building Multi-Architecture Docker Images With Buildx](https://medium.com/@artur.klauser/building-multi-architecture-docker-images-with-buildx-27d80f7e2408)
* [Custom Registry Cert for local build](https://github.com/docker/buildx/issues/80)
* [qemu-user-static by multiarch](https://github.com/multiarch/qemu-user-static) 

## Project tree

```
.
├── hooks
    ├── pre_build
    ├── build
    └── push
├── Dockerfile
└── ... more Dockerfiles
```

## Example Images

* [tobi312/minio](https://github.com/Tob1asDocker/minio)
