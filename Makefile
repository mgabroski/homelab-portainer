# homelab-portainer
# Single-command management interface
# Usage: make <command>

.PHONY: help up down restart logs ps pull update \
        backup restore-test clean validate

# Default target — show available commands
help:
	@echo ""
	@echo "homelab-portainer — available commands"
	@echo ""
	@echo "  make up            start portainer in background"
	@echo "  make down          stop and remove container"
	@echo "  make restart       restart container"
	@echo "  make logs          follow live logs"
	@echo "  make ps            show container status"
	@echo "  make pull          pull latest pinned image"
	@echo "  make update        pull and restart"
	@echo "  make backup        export data volume to backups/"
	@echo "  make restore-test  restore backup into test volume and verify"
	@echo "  make clean         stop container and remove all resources"
	@echo "  make validate      run all linters"
	@echo ""

# Start the service
up:
	@echo "→ creating volume and network if not present..."
	docker volume create homelab-portainer-data 2>/dev/null || true
	docker network create homelab-internal 2>/dev/null || true
	@echo "→ starting portainer..."
	docker compose up -d
	@echo "→ portainer is running at http://localhost:9000"

# Stop and remove container only — volume and network preserved
down:
	docker compose down

# Restart container
restart:
	docker compose restart
	docker compose ps

# Follow live logs
logs:
	docker compose logs -f portainer

# Show container status
ps:
	docker compose ps

# Pull the pinned image
pull:
	docker compose pull

# Pull new image and restart — for version updates
update: pull
	docker compose down
	docker compose up -d
	docker compose ps

# Export data volume to backups/
backup:
	@mkdir -p backups
	@echo "→ exporting homelab-portainer-data to backups/..."
	docker run --rm \
		-v homelab-portainer-data:/source \
		-v "$$(pwd)/backups:/backup" \
		alpine \
		sh -c 'cd /source && tar czf /backup/portainer-data-backup-$$(date +%Y%m%d-%H%M%S).tar.gz .'
	@echo "→ backup complete"
	@ls -lh backups/

# Restore latest backup into a test volume and verify contents
restore-test:
	@echo "→ creating restore test volume..."
	docker volume create homelab-portainer-restore-test
	@echo "→ restoring latest backup..."
	docker run --rm \
		-v homelab-portainer-restore-test:/target \
		-v "$$(pwd)/backups:/backup" \
		alpine \
		sh -c 'cd /target && tar xzf $$(ls /backup/*.tar.gz | tail -1)'
	@echo "→ verifying restored contents..."
	docker run --rm \
		-v homelab-portainer-restore-test:/data \
		alpine \
		sh -c 'ls -la /data'
	@echo "→ cleaning up test volume..."
	docker volume rm homelab-portainer-restore-test
	@echo "→ restore test complete"

# Full teardown — removes container, volume, and network
# WARNING: this destroys all Portainer data
clean:
	@echo "→ WARNING: this will destroy all Portainer data"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	docker compose down
	docker volume rm homelab-portainer-data 2>/dev/null || true
	docker network rm homelab-internal 2>/dev/null || true
	@echo "→ clean complete"

# Run all linters
validate:
	yarn validate