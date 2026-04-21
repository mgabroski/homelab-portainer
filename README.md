# homelab-portainer

Portainer CE — Visual Docker management dashboard for the homelab program.

Stage 1, Project 1 — Core Lab Control Layer.

---

## What This Is

Imagine you have a dozen programs running silently in the background on your
computer — things that handle your files, your passwords, your photos. Normally,
the only way to manage them is by typing cryptic commands into a black terminal
window. Portainer is a visual dashboard that replaces all of that with a
point-and-click interface, like a control panel for everything running behind
the scenes.

Without it, you would need to memorize and type commands every time you wanted
to start, stop, or inspect anything — a real barrier if you are managing more
than two or three services. With Portainer, you open a browser, see everything
laid out clearly, and manage it the same way you would manage files in Finder.
It makes the invisible visible.

Think of it like the difference between adjusting your home's heating by
rewiring the thermostat versus just tapping a button on your phone. The
underlying system is identical — Portainer just gives you the friendly interface
on top.

---

## Why This Matters

Every project in this homelab program runs inside a Docker container. Without a
management layer, operating more than a handful of containers means memorizing
commands, reading raw JSON output, and losing visibility the moment anything
goes wrong.

Portainer solves this from day one. It provides a single browser-based interface
to see every running container, inspect logs, manage volumes and networks, and
take action without ever touching a terminal. This is the foundation that makes
the rest of the program operationally sustainable.

In a real engineering context, this maps directly to how teams operate internal
platforms — you need visibility and control before you can operate anything
reliably at scale.

---

## Stack

| Component     | Technology              | Version       |
| ------------- | ----------------------- | ------------- |
| Runtime       | Docker + Docker Compose | Latest stable |
| Application   | Portainer CE            | 2.21.4        |
| Architecture  | ARM64 (Apple M2)        | Native        |
| Reverse proxy | Caddy                   | Project 4     |

---

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/homelab-portainer.git
cd homelab-portainer
docker volume create homelab-portainer-data
docker network create homelab-internal
make up
```

Open <http://localhost:9000> and complete first-login setup.

---

## Available Commands

```bash
make up            # start portainer in background
make down          # stop and remove container
make restart       # restart container
make logs          # follow live logs
make ps            # show container status
make pull          # pull latest pinned image
make update        # pull and restart with new image
make backup        # export data volume to backups/
make restore-test  # restore backup into test volume and verify
make clean         # stop container and remove all resources
make validate      # run all linters
make help          # show all commands
```

---

## Architecture

Single-container deployment. One service, one named volume, one explicit
network.

```plaintext
MacBook M2 (Host)
│
├── Docker Daemon
│   │
│   └── Network: homelab-internal
│       └── homelab-portainer (container)
│           ├── Image: portainer/portainer-ce:2.21.4
│           ├── Port 127.0.0.1:9000 → 9000 (HTTP UI)
│           ├── Volume: homelab-portainer-data → /data
│           └── Bind: /var/run/docker.sock → /var/run/docker.sock:ro
│
└── Browser → http://localhost:9000 → Portainer UI
```

Full architecture detail: [docs/architecture.md](docs/architecture.md)

---

## Security Posture

- Port bound to 127.0.0.1 — localhost only, no LAN exposure
- Docker socket mounted read-only — validated with all five operations
- No secrets in any committed file
- Strong password on admin account
- Pinned image version — no silent updates
- HTTP-only is a temporary exception — TLS arrives when Caddy is deployed in
  Project 4

Full security detail: [docs/security.md](docs/security.md)

---

## Backup and Restore

```bash
make backup        # exports volume to backups/portainer-data-backup-TIMESTAMP.tar.gz
make restore-test  # proves restore works without touching production data
```

Full restore procedure: [docs/runbook.md](docs/runbook.md)

---

## What I Learned

**Naming conventions require explicit enforcement.** Docker Compose
automatically prefixes volume and network names with the project name. Without
declaring them as external and creating them manually, you lose the ability to
enforce clean consistent names across projects. This is a subtle but important
infrastructure detail that only surfaces when you actually try to follow strict
naming standards.

**Distroless images are a security positive, not a problem.** The Portainer CE
image has no shell utilities — whoami does not exist. The first instinct is to
treat this as an obstacle. The correct reading is that a minimal image with less
tooling is a smaller attack surface. Adapting the verification approach (using
docker inspect instead) is the right response.

**A Makefile is not optional for infrastructure repos.** Long Docker Compose
commands are error-prone and create operational drift when different people run
slightly different variants. A Makefile with named targets is the right
abstraction — it documents intent, enforces consistency, and makes the repo
self-explaining.

**Commit hooks pay off immediately.** Having Prettier, yamllint, markdownlint,
and commitlint wired into every commit meant formatting issues were caught and
fixed automatically rather than accumulating as technical debt. The upfront cost
of setting this up is low compared to the cost of inconsistent commits across a
20-project program.

---

## How This Scales

In a real production environment, Portainer itself is not the management layer
for large-scale infrastructure — Kubernetes and purpose-built orchestration
platforms take over at that point. But the patterns established here scale
directly.

Named volumes and external resource declaration translate directly to
infrastructure-as-code patterns where resources are created explicitly and
referenced by name rather than auto-generated.

Explicit network segmentation with separate named networks per service group
scales to full network policy management in Kubernetes.

The backup approach — volume snapshot to a tar archive — is the same pattern
used in production database backup pipelines, just at a different scale.

The Makefile interface scales to CI/CD pipeline targets where the same make up,
make backup, and make validate commands are called by automated systems rather
than humans.

---

## Demo Flow

A clear walkthrough for demonstrating this project to any technical audience.

1. Open a terminal in the project root
1. Run `make ps` — show the container is running cleanly
1. Open <http://localhost:9000> — show the Portainer UI loading
1. Navigate to Containers — show all running containers visible including
   homelab-portainer itself
1. Navigate to Volumes — show homelab-portainer-data named correctly
1. Navigate to Networks — show homelab-internal named correctly
1. Run `make logs` in the terminal — show clean startup logs with no errors
1. Run `make backup` — show the backup archive being created with a real size
1. Run `make restore-test` — show the restore proving data recovery works
1. Open docs/decisions.md — walk through two or three decisions explaining why
   non-obvious choices were made
1. Run `git log --oneline` — show the clean conventional commit history

The entire demo should take under five minutes and requires no preparation
beyond `make up`.

---

## Documentation

| Document                                     | Contents                                   |
| -------------------------------------------- | ------------------------------------------ |
| [docs/architecture.md](docs/architecture.md) | Components, storage, networking            |
| [docs/runbook.md](docs/runbook.md)           | Start, stop, backup, restore, troubleshoot |
| [docs/security.md](docs/security.md)         | Security posture and decisions             |
| [docs/decisions.md](docs/decisions.md)       | Every meaningful decision and why          |

---

## Program Context

This project is Stage 1, Project 1 of a 20-project homelab program across two
sessions on a MacBook M2.

Session 1 narrative: I can self-host real, useful applications responsibly.

Next project: Uptime Kuma — self-hosted monitoring dashboard. Uptime Kuma will
monitor Portainer once deployed.
