.PHONY: check lint up down

check: lint
	docker compose config -q

lint:
	shellcheck scripts/*.sh

up:
	docker compose up -d

down:
	docker compose down
