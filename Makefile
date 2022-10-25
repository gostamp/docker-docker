# Lazily create and "source" the .env file
# See: https://unix.stackexchange.com/a/235254
ifeq (,$(wildcard .env))
$(shell cp .env.example .env)
endif
include .env
export $(shell sed 's/=.*//' .env)

# Always use buildkit
export COMPOSE_DOCKER_CLI_BUILD := 1
export DOCKER_BUILDKIT := 1

.DEFAULT_GOAL := help
SHELL := /bin/bash


##@ App

.PHONY: build
build: ## Build the app
	docker compose build app

.PHONY: inspect
inspect:
	docker inspect $$(docker compose config --images app)

.PHONY: run
run: ## Run the app
	docker compose run --rm app ./bin/command.sh

.PHONY: scan
scan: ## Scan the app for security issues
	docker compose run --rm app ./bin/scan.sh

.PHONY: test
test: APP_ENV := test
test: ## Test the app
	docker compose run --rm app ./bin/test.sh

.PHONY: lint
lint: ## Lint the app
	docker compose run --rm app ./bin/lint.sh

.PHONY: clean
clean: ## Clean the app
	docker compose down -v
	rm -f .env

.PHONY: release
release: ## Create a new GitHub release
	git fetch --all --tags
	@if [[ "$$(svu next)" == "$$(svu current)" ]]; then echo "Nothing to release!" && exit 1; fi
	gh release create "$$(svu next)" --generate-notes


##@ Other

.PHONY: setup
setup: ## Setup everything needed for local development
	@if command -v docker >/dev/null 2>&1; then echo "Found docker"; else echo "Unable to find docker!"; exit 1; fi
	@if command -v gh >/dev/null 2>&1; then echo "Found gh"; else echo "Unable to find gh!"; exit 1; fi
	@if command -v git >/dev/null 2>&1; then echo "Found git"; else echo "Unable to find git!"; exit 1; fi
	@if command -v svu >/dev/null 2>&1; then echo "Found svu"; else echo "Unable to find svu!"; exit 1; fi
	@echo "" && echo "Building..." && echo "" && $(MAKE) build

.PHONY: shell
shell: ## Shell into the container
	docker compose run --rm app bash

# Via https://www.thapaliya.com/en/writings/well-documented-makefiles/
# Note: The `##@` comments determine grouping
.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
