# Kubernetes Deployment
This repository contains the code necessary to deploy into a Kubernetes cluster, with the following assumptions:

 - You have a working Kubernetes cluster with Helm deployed
 - You have a local copy of the `helm` binary for interacting with Helm server-side
 - You have a local Kubernetes configuration file that defines your contexts
 - You have a Docker repository you can push images to

### Helm Chart
The `helm` directory contains a chart that can be used for deploying `abalone` to a Kubernetes cluster. Values should be stored in `helm/config`, and should be created using the `environment.yaml.template` file. For example:

```sh
$ cp helm/config/environment.yaml.template helm/config/development.yaml
$ cp helm/config/environment.yaml.template helm/config/production.yaml
```

Once you have created the environment values (which will be ignored by Git), you can use the `Makefile` to build and push your Docker images, and then deploy to Kubernetes.

### Building and Pushing Docker Images
In order for a Kubernetes deployment to work, you need to buil and push a Docker image to a Docker repository. When building a new Docker image, you should update `docker_tag` in the `Makefile` to the next reasonable version, then update `image:tag` in `helm/config/<environment>.yaml` to use the most recent image you have pushed. By default, this will attempt to push an image named `abalone:<tag>` to Docker hub, unless you specifiy a repo via the `docker_repo` variable.

```sh
$ make helm_docker_build
# Will by default push to Docker hub
$ make helm_docker_push
# Push to a different repository
$ make helm_docker_push docker_repo=quay.io/myorganization/
```

Once the image is pushed you can then use it in your deployment.

### Deploying to Kubernetes via Helm
If all the Prerequisites stated in the beginning of this document have been met, you can begin deploying to Kubernetes. You will need to first create the respective `<environment>.yaml` file in `helm/config/`.

##### Runtime Variables

 - `environment`: This should map to either `production` or `development`. This will reference the YAML file in `helm/config/{development,production}.yaml`. This defaults to `development`.
 - `kube_context`: The context defined in your local Kubernetes configuration that referenences the cluster you want to deploy to. This has no default value and must be set when invoking the Make command.
 - `kube_namespace`: Which namespace you want to deploy to. This namespace will be created automatically. This defaults to `abalone.`
 - `helm_release`: What to name the release internally to Helm. By default this is `abalone`.

```sh
# Run a diff to see what would change
$ make helm_diff kube_context=My-Context
$ make helm_diff kube_context=My-Context environment=production
# Actually upgrade/install the release
$ make helm_upgrade kube_context=My-Context environment=production
# Completely remove the release
$ make helm_uninstall kube_context=My-Context environment=development
```
