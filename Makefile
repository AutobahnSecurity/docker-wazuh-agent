VERSION ?= v4.10.0
.PHONY: help
help: ## Help for usage
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
all: docker

build-minideb: ## Build Wazuh Agent minideb based
	docker build -t autobahnsecurity/wazuh-agent:latest .  && \
	docker tag autobahnsecurity/wazuh-agent:latest autobahnsecurity/wazuh-agent:$(VERSION)

build-amazon-linux: ## Build Wazuh Agent amazon linux based
	docker build -f ./images/Dockerfile.amazonlinux -t autobahnsecurity/wazuh-agent-amazonlinux:latest .  && \
	docker tag autobahnsecurity/wazuh-agent-amazonlinux:latest autobahnsecurity/wazuh-agent-amazonlinux:$(VERSION)

build-ubuntu: ## Build Wazuh Agent ubuntu linux based
	docker build -f ./images/Dockerfile.ubuntu -t autobahnsecurity/wazuh-agent-ubuntu:latest .  && \
	docker tag autobahnsecurity/wazuh-agent-ubuntu:latest autobahnsecurity/wazuh-agent-ubuntu:$(VERSION)

docker-run: ## Run Wazuh Agent docker image  minideb based
	docker run autobahnsecurity/wazuh-agent:$(VERSION)

docker-push-minideb: ## Push Wazuh Agent docker image  minideb based
	docker push autobahnsecurity/wazuh-agent:latest && \
	docker push autobahnsecurity/wazuh-agent:$(VERSION)

docker-push-amazon-linux: ## Push Wazuh Agent docker image amazon linux based
	docker push autobahnsecurity/wazuh-agent-amazonlinux:latest && \
	docker push autobahnsecurity/wazuh-agent-amazonlinux:$(VERSION)

docker-push-ubuntu: ## Push Wazuh Agent docker image ubuntu linux based
	docker push autobahnsecurity/wazuh-agent-ubuntu:latest && \
	docker push autobahnsecurity/wazuh-agent-ubuntu:$(VERSION)

docker-buildx:
	docker buildx build --push -t autobahnsecurity/wazuh-agent:$(VERSION) --cache-to type=local,dest=./tmp/ --cache-from type=local,src=./tmp/ .

run-local: ## Run docker compose stack with all agents on board
	docker compose -f tests/single-node/generate-indexer-certs.yml run --rm generator
	docker compose -f docker-compose.yml up -d --build

run-local-minideb: ## Run docker compose stack with only minideb agent.
	docker compose -f tests/single-node/generate-indexer-certs.yml run --rm generator
	AGENT_REPLICAS=0 docker compose -f docker-compose.yml up -d --build

run-local-dev: ## Run Wazuh cluster without agents.
	docker compose -f tests/single-node/generate-indexer-certs.yml run --rm generator
	AGENT_REPLICAS=0 LOCAL_DEV=0 docker compose -f docker-compose.yml up -d --build

destroy: ## Destroy docker compose stack and cleanup
	docker compose down --remove-orphans --rmi local -v
	rm -rf tests/single-node/config/wazuh_indexer_ssl_certs/*
test: ## Run unit tests
	pytest  -v  --cov=. --cov-report xml --cov-report html -n auto --capture=sys -x --tb=long

gh-actions:  ## Run github action locally
	DOCKER_DEFAULT_PLATFORM= act --artifact-server-path=/tmp/wazuh
