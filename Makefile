DOCKER_STACK_CONFIG := docker stack config
DOCKER_STACK_CONFIG_ARGS := --skip-interpolation

make: docker-stack.yml
	@echo "Usage: make [deploy|remove|clean]"
	@echo "  deploy: Deploy the stack"
	@echo "  remove: Remove the stack"
	@echo "  clean: Clean up temporary files"

docker-stack.yml:
	@mkdir -p _tmp
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) -c grafana-loki/docker-stack.yml > _tmp/grafana-loki.yml
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) -c promtail/docker-stack.yml > _tmp/promtail.yml
	$(DOCKER_STACK_CONFIG) $(DOCKER_STACK_CONFIG_ARGS) \
		-c _tmp/grafana-loki.yml \
		-c _tmp/promtail.yml \
	> docker-stack.yml
	# @rm -rf _tmp
	@sed "s|$(PWD)/||g" docker-stack.yml > docker-stack.yml.tmp
	@rm docker-stack.yml
	@mv docker-stack.yml.tmp docker-stack.yml

deploy: docker-stack.yml
# This ingress network is used by Blackbox exporter to perform network probes
  docker network create --scope=swarm --driver=overlay --attachable public

  # The `prometheus` network is used to perform service discovery for Prometheus scrape configs.
  docker network create --scope=swarm --driver=overlay --attachable prometheus

  # The `prometheus_gwnetwork` network is used for the internal communication between the Prometheus Server, exporters and other agents.
  docker network create --scope=swarm --driver=overlay --attachable prometheus_gwnetwork || true
	docker network create --scope=swarm --driver=overlay --attachable logstack_gwnetwork || true
	docker network create --scope=swarm --driver=overlay --attachable prometheus_gwnetwork || true
	docker stack deploy -c docker-stack.yml logstack

remove:
	docker stack rm logstack

clean:
	@rm -rf _tmp || true
	@rm -f docker-stack.yml || true


docker node update --label-add "io.promstack.prometheus=true" ebzby7ac7x04gcwfmojnl86hi
docker node update --label-add "io.promstack.grafana=true" ebzby7ac7x04gcwfmojnl86hi
