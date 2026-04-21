# homelab-portainer — Architecture

## Overview

Single-container deployment of Portainer CE on a MacBook M2. Portainer provides
a web-based visual management interface for all local Docker containers, images,
volumes, and networks.

This is Stage 1, Project 1 of the homelab program. It is the first service
deployed and forms the visual control layer for all future projects.

---

## Components

| Component    | Image                  | Version |
| ------------ | ---------------------- | ------- |
| Portainer CE | portainer/portainer-ce | 2.21.4  |

The image is multi-arch and runs natively on ARM64 (M2) without emulation.
Version is pinned deliberately — see docs/decisions.md Decision 001.

---

## Storage

| Type         | Name                   | Mount Path           | Purpose                                             |
| ------------ | ---------------------- | -------------------- | --------------------------------------------------- |
| Named volume | homelab-portainer-data | /data                | All Portainer state — credentials, config, settings |
| Bind mount   | /var/run/docker.sock   | /var/run/docker.sock | Docker API access                                   |

The volume is declared as external and created manually before starting the
container. This enforces exact naming per NAMING-CONVENTIONS.md without Docker
Compose project name prefixing. See docs/decisions.md Decision 017.

The Docker socket is mounted read-only (:ro). Validated during Step 6 hardening
— all five operations (view, stop, start, remove, create) confirmed working with
:ro applied. See docs/decisions.md Decision 005.

---

## Networking

| Port | Protocol | Bound To  | Purpose          |
| ---- | -------- | --------- | ---------------- |
| 9000 | HTTP     | 127.0.0.1 | Portainer web UI |

Port 9000 is bound to localhost only. No LAN exposure before Caddy. Port 8000
(Edge agent tunnel) is not exposed — agent mode is out of scope. Port 9443
(built-in HTTPS) is not used — Caddy owns TLS in Project 4.

| Network          | Type   | Purpose                                                |
| ---------------- | ------ | ------------------------------------------------------ |
| homelab-internal | bridge | Explicit internal network — no default bridge reliance |

The network is declared as external and created manually. homelab-proxy will be
added when Caddy arrives in Project 4.

---

## Secrets

No secrets are required at deployment time. The admin password is set
interactively via the web UI on first launch and is never stored in any file. No
.env file is required for this service.

---

## Persistence

| Scenario                           | Outcome                                                    |
| ---------------------------------- | ---------------------------------------------------------- |
| Container stops and restarts       | All data survives — stored in named volume                 |
| Container is deleted and recreated | All data survives — volume persists independently          |
| Docker daemon restarts             | Container recovers automatically — restart: unless-stopped |
| Volume is deleted                  | All data is lost — backup required before deletion         |

---

## Reverse Proxy

Caddy is not available at this stage. This is a documented exception against
DEFINITION-OF-DONE criterion 1.6.

| Item           | Status                                                    |
| -------------- | --------------------------------------------------------- |
| Caddy routing  | Not available — Stage 1 Project 4                         |
| Local domain   | portainer.local — reserved, not yet active                |
| Current access | <http://localhost:9000> — temporary, documented exception |

When Caddy arrives in Project 4, homelab-portainer joins the homelab-proxy
network and Caddy routes portainer.local to port 9000. No structural changes to
this container are needed.

---

## Backup

| Item        | Detail                                                                  |
| ----------- | ----------------------------------------------------------------------- |
| Approach    | make backup — tar archive of named volume                               |
| Location    | backups/ directory — gitignored, local only                             |
| Filename    | portainer-data-backup-YYYYMMDD-HHMMSS.tar.gz                            |
| Restore     | make restore-test — proven end to end during Step 6 hardening           |
| Criticality | Medium — losing this means reconfiguring the UI, not irreplaceable data |

---

## Current State

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

---

## Future State — Project 4

```plaintext
MacBook M2 (Host)
│
├── Docker Daemon
│   │
│   ├── Network: homelab-proxy (shared with Caddy)
│   └── Network: homelab-internal
│       └── homelab-portainer (container)
│           ├── Image: portainer/portainer-ce:2.21.4
│           ├── Volume: homelab-portainer-data → /data
│           └── Bind: /var/run/docker.sock → /var/run/docker.sock:ro
│
└── Caddy → portainer.local → homelab-portainer:9000
```
