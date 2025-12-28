# Example of automatically building container images

There are several ways to automatically build container/docker images.  
Here are a few examples:

## GitHub Actions

> Note: **GitHub Actions** can also be used with [Gitea](https://about.gitea.com/) and [Forgejo](https://forgejo.org/). ;-)

Docs:
* https://github.com/features/actions
* https://docs.github.com/en/actions
  * https://docs.github.com/en/actions/learn-github-actions/environment-variables
  * https://docs.github.com/en/actions/tutorials/create-actions/create-a-composite-action

Actions:
* [checkout](https://github.com/actions/checkout)
* [setup-qemu-action](https://github.com/docker/setup-qemu-action)
* [setup-buildx-action](https://github.com/docker/setup-buildx-action)
* [login-action](https://github.com/docker/login-action)
* [build-push-action](https://github.com/docker/build-push-action)
* [dockerhub-description](https://github.com/peter-evans/dockerhub-description) or [multiple-registry-description](https://github.com/christian-korneck/update-container-description-action)

### Project tree

```
.
├── .github
    ├── actions
    |   ├── docker-setup
    |   |   └── action.yml
    |   └── ...
    └── workflows
        ├── build_docker_images.yaml
        ├── build_docker_images_withMatrixAndOwnAction.yml
        └── ... 
├── Dockerfile(s)
└── ...
```
### Description

* `.github/workflows/build_docker_images.yaml` Workflow-File example for build Docker Images (Multiarch)
* Workflow with Matrix and use own (composite) Action for building Multiarch Docker Images: 
  * `.github/actions/docker-setup/action.yml` is my docker-setup action, that can include in Workflows with  
    ```yaml
    uses: tob1as/docker-build-example/.github/actions/docker-setup@main
    ```
    or when you copy the action:
    ```yaml
    uses: ./.github/actions/docker-setup
    ```
  * `.github/workflows/build_docker_images_withMatrixAndOwnAction.yml` Workflow-File with Matrix and use own Action. 
  * It is used (in future / from 2026) in my GitHub Repository: [docker-php](https://github.com/Tob1as/docker-php)
  

## GitLab 

For GitLab use the `.gitlab-ci.yml` as an example.

## Docker Hub Hook

> Note: My examples are outdated, i recommend using GitHub Actions.

Docs:
* [Advanced options for Autobuild](https://docs.docker.com/docker-hub/builds/advanced/)

### Project tree

Example for advanced options (hooks) and buildx for Autobuild on Docker Hub to build Multiarch Images

```
.
├── hooks
    ├── pre_build
    ├── build
    └── push
├── Dockerfile
└── ... more Dockerfiles
```

## more Docs
* [Docker Build](https://docs.docker.com/build/)
* [Building Multi-Architecture Docker Images With Buildx](https://medium.com/@artur.klauser/building-multi-architecture-docker-images-with-buildx-27d80f7e2408)
* https://github.com/multiarch/qemu-user-static & https://github.com/tonistiigi/binfmt


## Example Repository

More examples can be found in my repositories. Here is a selection:

* [tobi312/tools](https://github.com/Tob1as/docker-tools)
* [tobi312/php](https://github.com/Tob1as/docker-php)
* [healthcheck](https://github.com/Tob1as/docker-healthcheck)
