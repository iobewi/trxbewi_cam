# Makefile — setup host + env pour Compose non-root (avec remove udev)

.PHONY: build up down status bash logs

## Monte/arrête la stack
build:
	docker build -t iobewi:trxbewi_cam .
up:
	docker compose -f compose.local.yaml up -d
status:
	docker compose -f compose.local.yaml ps
down:
	docker compose -f compose.local.yaml down
bash:
	docker compose -f compose.local.yaml exec trxbewi_cam bash
logs:
	docker compose -f compose.local.yaml logs