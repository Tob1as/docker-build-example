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

## Alternative

* for GitHub use the GitHub Actions (`.github/workflows/build_docker_images.yaml`):
  * [checkout](https://github.com/actions/checkout)
  * [setup-qemu-action](https://github.com/docker/setup-qemu-action)
  * [setup-buildx-action](https://github.com/docker/setup-buildx-action)
  * [login-action](https://github.com/docker/login-action)
  * [build-push-action](https://github.com/docker/build-push-action)
  * https://docs.github.com/en/actions/learn-github-actions/environment-variables
* for GitLab use the `.gitlab-ci.yml` as an example, then `hooks/` is not needed.

## Example Images

* [tobi312/minio](https://github.com/Tob1asDocker/minio)
* [tobi312/tools](https://github.com/Tob1asDocker/tools)
