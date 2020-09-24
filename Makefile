# Helm
# kube_context: Which K8s cluster/context to deploy to
# kube_namespace: Which namespace you want the app to live in
# kube_environment: `development` or `production`
kube_context=
kube_namespace=abalone
environment=development

helm_bin=/usr/bin/env helm
helm_args=--kube-context $(kube_context) -n $(kube_namespace)
helm_release=abalone

# Docker
# docker_name: What name to give the image
# docker_tag: The version tag you want to deploy
# docker_repo: Where the image should be pulled from if not Docker Hub
docker_name=abalone
docker_tag=1.0.2
docker_repo=

dev_env:
	docker-compose up --detach web delayed_job
	@echo -
	@echo - Services started! Watch development logs with 'make watch'.
	@echo -

minty_fresh: nuke schema_migrate dev_env

watch:
	docker-compose logs --follow web delayed_job

console:
	docker-compose run --rm console

test: spec lint

spec: schema_migrate
	@echo -
	@echo - Running specs!
	@echo -
	docker-compose run -e RAILS_HOST=www.example.com --rm rspec

lint:
	@echo -
	@echo - Running Rubocop!
	@echo -
	docker-compose run --rm rubocop

database_started:
	@echo - Starting up database.
	docker-compose up --detach db

schema_migrate: database_started
	@echo -
	@echo - Applying any pending migrations.
	@echo -
	docker-compose run --rm schema_migrate

schema_status:
	docker-compose run --rm pending_migrations

database_seeds:
	docker-compose run --rm seeds

build:
	docker-compose build app

nuke:
	@echo -
	@echo - Stopping and destroying development services and database.
	@echo -
	docker-compose down --volumes

_helm_dependencies:
	$(helm_bin) \
	dependency update helm/

helm_diff: _helm_dependencies
	$(helm_bin) \
	$(helm_args) \
	diff upgrade --allow-unreleased \
	-f helm/config/$(environment).yaml \
	$(helm_release) helm/

helm_upgrade: _helm_dependencies
	$(helm_bin) \
	$(helm_args) \
	upgrade -i --create-namespace \
	-f helm/config/$(environment).yaml \
	$(helm_release) helm/

helm_uninstall: _helm_dependencies
	$(helm_bin) \
	$(helm_args) \
	uninstall \
	$(helm_release)

# Build and push images for deploying into Kube with Helm

helm_docker_build:
	/usr/bin/env docker build -t $(docker_name) .

helm_docker_push:
	/usr/bin/env docker tag ${docker_name} quay.io/powerhome/${docker_name}:${docker_tag}
	/usr/bin/env docker push ${docker_repo}${docker_name}:${docker_tag}
