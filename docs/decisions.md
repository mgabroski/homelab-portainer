# homelab-portainer — Decision Log

All meaningful decisions made during this project are recorded here in
chronological order with reasons. This log exists so any engineer can understand
not just what was built but why every non-obvious choice was made.

---

## Decision 001 — Image version pinned to 2.21.4

**Date:** 2026-04-10 **Decision:** Pin Portainer CE image to version 2.21.4
**Reason:** Pinning a specific version ensures reproducible deployments and
prevents silent breakage if the upstream image changes. 2.21.4 was selected as a
known-good stable release at program start. The Portainer CE changelog was
reviewed before selection. **Review trigger:** Check for new stable releases
when a security fix is announced or quarterly at minimum.

---

## Decision 002 — Port 8000 not exposed

**Date:** 2026-04-10 **Decision:** Port 8000 (Edge agent tunnel) is not exposed
in this deployment. **Reason:** Agent mode and remote Docker host management are
explicitly out of scope for this project. Exposing an unused port to the host
adds unnecessary surface area with no benefit. Port 8000 will only be added if a
future project introduces Edge or agent functionality.

---

## Decision 003 — Port 9443 not used, port 9000 HTTP as pre-Caddy exception

**Date:** 2026-04-10 **Decision:** Portainer's built-in HTTPS on port 9443 is
not enabled. HTTP access on port 9000 is used as a deliberate temporary
exception. **Reason:** TLS termination will be handled by Caddy in Stage 1
Project 4. Running two competing TLS configurations is inconsistent with the
program's Caddy-first approach to HTTPS. HTTP on 9000 is acceptable only because
the port is bound to 127.0.0.1 and the service is localhost-only at this stage.
**Review trigger:** Revisit when Caddy is deployed in Project 4.

---

## Decision 004 — Port 9000 bound to 127.0.0.1 only

**Date:** 2026-04-10 **Decision:** Port 9000 is explicitly bound to 127.0.0.1,
not 0.0.0.0. **Reason:** Portainer grants full Docker control to anyone who can
reach its UI. Binding to localhost prevents any accidental LAN exposure before
Caddy and a proper domain are in place. Consistent with SECURITY-BASELINE.md
localhost-first policy.

---

## Decision 005 — Docker socket mount, :ro flag pending Step 6 validation

**Date:** 2026-04-10 **Decision:** Docker socket is mounted without :ro flag
until Step 6 runtime validation confirms full functionality is preserved with it
applied. **Reason:** Portainer's official install documentation mounts the
socket without :ro. The hypothesis that :ro preserves full Portainer
functionality — create, start, stop, remove containers — has not been
runtime-validated. The flag will be added after Step 6 if validation confirms no
functionality is lost. If any operation fails with :ro, the flag stays off and
the reason is documented here. **Risk accepted:** The socket mount grants
Portainer effective root-equivalent access to the Docker host via the Docker
API. This is an accepted and documented trade-off for a container management
tool. Full risk treatment is in docs/security.md. **Outcome:** [To be filled in
during Step 6 validation]

---

## Decision 006 — homelab-internal network declared explicitly

**Date:** 2026-04-10 **Decision:** An explicit Docker network named
homelab-internal is declared in the compose file despite this being a
single-container project. **Reason:** STANDARDS.md requires explicit network
declarations and prohibits reliance on Docker's default bridge. Declaring the
network now makes the future Caddy integration a simple network attachment
rather than a structural change to the compose file.

---

## Decision 007 — MFA not configured

**Date:** 2026-04-10 **Decision:** No MFA is configured for this Portainer CE
localhost-first setup. **Reason:** No native MFA flow is being set up at this
stage. The service is localhost-only and the risk is accepted for a
single-operator local deployment. This decision is reviewed when Caddy exposes
the service to the LAN in Project 4.

---

## Decision 008 — Default admin username to be changed on first login

**Date:** 2026-04-10 **Decision:** The Portainer setup flow suggests admin as
the default username. This must be changed to a non-default value during
first-login setup. **Reason:** Default usernames are publicly known and reduce
the effort required for a brute-force attempt. Changing the username is a simple
and effective mitigation.

---

## Decision 009 — Container user behaviour to be verified at Step 6

**Date:** 2026-04-10 **Decision:** The internal user that the Portainer CE
container runs as was not confirmed from documentation alone. This will be
verified during Step 6 deployment using docker exec whoami. **Outcome:** [To be
filled in during Step 6 verification]

---

## Decision 010 — Tooling files added at root level

**Date:** 2026-04-14 **Decision:** The following files are added at root level
beyond the Step 4 baseline structure: package.json yarn.lock .yarnrc.yml
.commitlintrc.yml .yamllint.yml .markdownlint.yml .husky/ **Reason:**
Senior-level Git workflow requires commit message enforcement, YAML linting, and
Markdown linting in place from the first commit. These are developer tooling
files, not application files. Their presence at root is standard for Yarn-based
tooling setups. STANDARDS.md explicitly allows additional root-level files when
genuinely needed and documented. **Impact on Step 4 file plan:** Additive only.
No locked files are changed or removed.

---

## Decision 011 — node_modules excluded, yarn.lock committed

**Date:** 2026-04-14 **Decision:** node_modules/ is gitignored. yarn.lock is
committed. **Reason:** node_modules is a derived artifact and must never be
committed. yarn.lock is Yarn's reproducibility lockfile. Committing it ensures
all future installs resolve the exact same dependency tree across all machines
and contributors.

---

## Decision 012 — devDependencies pinned to exact resolved versions

**Date:** 2026-04-14 **Decision:** All tooling devDependencies use exact version
numbers resolved by Yarn at install time. No floating ranges or latest tags.
**Reason:** This repo exists to demonstrate clean, intentional, reproducible
engineering. Floating versions cause silent tooling drift over time and
undermine the reproducibility guarantee this project is built on.

---

## Decision 013 — yamllint pinned to 1.35.1

**Date:** 2026-04-14 **Decision:** yamllint is installed via pip3 at exactly
version 1.35.1. **Reason:** yamllint is a Python tool and sits outside the Yarn
dependency graph. Without an explicit version pin it can drift between machines
independently of yarn.lock. Pinning it here ensures consistent linting behaviour
everywhere. **Install command:** pip3 install yamllint==1.35.1 **Review
trigger:** Update when a new yamllint release addresses a bug or adds a rule
relevant to this project's YAML files.

---

## Decision 014 — Yarn managed via Corepack, not npm global install

**Date:** 2026-04-14 **Decision:** Yarn is enabled and version-pinned via
Corepack using corepack enable and yarn set version 4.10.3. Yarn is not
installed via npm install -g yarn. **Reason:** Yarn's own documentation
explicitly recommends Corepack as the correct install path for modern Yarn and
recommends against global npm installation. Corepack pins the Yarn version in
the packageManager field of package.json, making the Yarn version itself part of
the repo's reproducibility contract rather than an assumption about the local
machine.

---

## Decision 015 — Yarn PnP disabled, node-modules linker used

**Date:** 2026-04-14 **Decision:** Yarn 4 PnP mode is disabled via .yarnrc.yml
setting nodeLinker: node-modules. PnP-generated files .pnp.cjs and
.pnp.loader.mjs are removed. Auto-generated .gitattributes and .editorconfig
from yarn init are removed. **Reason:** PnP mode generates unplanned files that
were not part of the locked Step 4 file plan and are not needed for a
tooling-only setup on an infrastructure repo. node-modules linker matches the
planned approach and keeps the root clean and intentional. **Impact:**
.yarnrc.yml is added as a new root-level file and is committed. This is the
authorised deviation from the Step 4 file plan.

---

## Decision 016 — Prettier added for auto-formatting

**Date:** 2026-04-14 **Decision:** Prettier is added as a dev dependency and
wired into lint-staged to auto-format YAML and Markdown files before linters
run. **Reason:** yamllint and markdownlint validate but do not fix. Prettier
auto-corrects formatting issues like missing newlines, inconsistent indentation,
and line endings before validation runs. This prevents trivial formatting errors
from blocking commits and removes the need for manual formatting fixes.
**Workflow:** lint-staged runs Prettier first to fix, then linters validate.
Commits only land if both pass. **Pinned version:** exact version resolved by
Yarn at install time.

## Decision 017 — Volume and network declared as external

**Date:** 2026-04-21 **Decision:** homelab-portainer-data volume and
homelab-internal network are declared as external: true in docker-compose.yml
and created manually before starting the container. **Reason:** Docker Compose
automatically prefixes volumes and networks with the project name, producing
homelab-portainer_homelab-portainer-data instead of homelab-portainer-data.
Declaring them external and creating them manually enforces the exact names
required by NAMING-CONVENTIONS.md with no prefix. **Impact:** Volume and network
must be created manually before docker compose up on any new machine. This is
documented in docs/runbook.md.

## Decision 018 — Makefile added for single-command management

**Date:** 2026-04-21 **Decision:** A Makefile is added at root level providing
single-command management for all common operations: up, down, restart, logs,
ps, pull, update, backup, restore-test, clean, and validate. **Reason:** Long
Docker Compose commands are error-prone and hard to remember across projects. A
Makefile provides a consistent, documented interface that works on any Mac or
Linux machine without additional dependencies. It also embeds the backup and
restore procedures directly into the repo as executable targets rather than just
documentation. **Impact on file plan:** Additive only. Makefile added at root
level per the STANDARDS.md allowance for genuinely needed additions.
