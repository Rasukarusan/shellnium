SHELL := /usr/bin/env bash

.PHONY: help bootstrap syntax lint test smoke docker-build docker-test docker-smoke ci ci-local

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make bootstrap    Install optional local runtime dependencies' \
		'  make syntax       Run bash syntax checks' \
		'  make lint         Run ShellCheck on tracked shell scripts' \
		'  make test         Run Bats test suite' \
		'  make smoke        Run the CI smoke example in headless mode' \
		'  make docker-build Build the local Docker image' \
		'  make docker-test  Run lint and tests in Docker' \
		'  make docker-smoke Run smoke test in Docker' \
		'  make ci           Run the standard Docker-first verification pipeline' \
		'  make ci-local     Run the local verification pipeline'

bootstrap:
	./scripts/bootstrap.sh

syntax:
	bash -n lib/*.sh demo.sh demo2.sh demo3.sh examples/*.sh docker-entrypoint.sh scripts/*.sh

lint:
	shellcheck -s bash -e SC1091 lib/*.sh scripts/*.sh demo.sh demo2.sh demo3.sh examples/*.sh docker-entrypoint.sh

test:
	bats --recursive tests/

smoke:
	SHELLNIUM_HEADLESS=true bash examples/ci_smoke_test.sh

docker-build:
	docker build -t shellnium:local .

docker-test: docker-build
	docker run --rm shellnium:local shellcheck
	docker run --rm shellnium:local test

docker-smoke: docker-build
	docker run --rm --shm-size=2g shellnium:local examples/ci_smoke_test.sh

ci: syntax docker-test

ci-local: syntax lint test
