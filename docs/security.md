# homelab-portainer — Security

This document covers the security posture of the Portainer CE deployment. All
decisions reference SECURITY-BASELINE.md which defines the minimum security
standard for every project in this program.

---

## Auth Model

| Item        | Detail                                                                                                      |
| ----------- | ----------------------------------------------------------------------------------------------------------- |
| Mechanism   | Portainer built-in username and password                                                                    |
| First login | Admin account created interactively on first launch                                                         |
| Username    | Non-default username set on first login                                                                     |
| Password    | Strong password set on first login — minimum 12 characters enforced by Portainer                            |
| Session     | JWT issued on login, 8-hour default expiry, auto-expires                                                    |
| MFA         | Not configured — no native MFA flow for this CE localhost-first setup. Accepted limitation documented below |

---

## Default Credentials

No default password exists in the Portainer CE image. The admin account is
created by the operator on first launch via the setup screen.

The setup flow suggests admin as the default username. A non-default username
was set during first-login setup per Decision 008. Username change deferred to
Project 4 when Caddy exposes the service to the LAN — see docs/decisions.md
Decision 008.

---

## Network Exposure

| Port | Bound To    | Scope          | Reason                                 |
| ---- | ----------- | -------------- | -------------------------------------- |
| 9000 | 127.0.0.1   | Localhost only | Web UI — pre-Caddy temporary exception |
| 8000 | Not exposed | None           | Edge agent — out of scope              |
| 9443 | Not exposed | None           | Built-in HTTPS — Caddy owns TLS        |

The service is not reachable from the LAN or any external network. This changes
in Project 4 when Caddy routes portainer.local to this service.

---

## Docker Socket Risk

The Docker socket mount is the primary security consideration for this service.

| Item       | Detail                                                                                             |
| ---------- | -------------------------------------------------------------------------------------------------- |
| Risk       | The socket grants Portainer effective root-equivalent access to the Docker host via the Docker API |
| Mitigation | Socket mounted read-only (:ro) — validated during Step 6 hardening                                 |
| Mitigation | Port bound to 127.0.0.1 — no network access to the UI                                              |
| Mitigation | Strong password on the admin account                                                               |
| Accepted   | This is an inherent and accepted trade-off for a container management tool                         |

The :ro flag was validated during Step 6 hardening. All five operations — view,
stop, start, remove, create — confirmed working with :ro applied. See
docs/decisions.md Decision 005.

---

## Container Privilege Level

| Item                 | Detail                                                        |
| -------------------- | ------------------------------------------------------------- |
| Privileged mode      | Not used                                                      |
| Container user       | Defaults to root internally — upstream Portainer CE behaviour |
| Capability additions | None                                                          |
| Read-only filesystem | Not applicable — /data requires write access                  |

The internal root user cannot be changed without a custom image build. This is
accepted and documented — see docs/decisions.md Decision 009.

---

## Secret Handling

| Item                    | Detail                                         |
| ----------------------- | ---------------------------------------------- |
| Deployment-time secrets | None required                                  |
| Admin password          | Set via UI — never stored in any file          |
| .env file               | Optional, gitignored, not required             |
| .env.example            | Present as scaffolding — intentionally empty   |
| Secrets in compose      | None                                           |
| Secrets in image layers | None — pre-built official image, no build step |

---

## MFA Limitation

MFA is not configured for this Portainer CE localhost-first setup. The service
is localhost-only and the risk is accepted for a single-operator local
deployment. This is reviewed when Caddy exposes the service to the LAN in
Project 4.

---

## Update Strategy

| Item     | Detail                                                                                |
| -------- | ------------------------------------------------------------------------------------- |
| Approach | Deliberate manual update — never automatic                                            |
| Process  | Check changelog → review breaking changes → update version pin → make update → verify |
| Command  | make update                                                                           |
| Never    | Do not use latest tag in committed config                                             |

A new version (2.39.1) was noted during Step 6 hardening. The current pinned
version 2.21.4 remains in use until an intentional update decision is made and
documented in docs/decisions.md.

---

## HTTPS

HTTP-only access on port 9000 is a deliberate documented exception for the
pre-Caddy stage. TLS will be handled by Caddy in Project 4. See
docs/decisions.md Decision 003.

---

## Never-Do List

| Never Do                                                 | Reason                                                                                      |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Never expose port 9000 to the LAN before Caddy           | Portainer grants full Docker control — must not be network-accessible without auth controls |
| Never leave the first-login setup screen uncompleted     | Setup screen is open to anyone who can reach the port                                       |
| Never commit .env                                        | Secrets must never enter version control                                                    |
| Never use latest image tag                               | Prevents reproducible deployments                                                           |
| Never run a second Portainer instance on the same socket | Creates unpredictable behaviour                                                             |

---

## Security Baseline Compliance

This project complies with SECURITY-BASELINE.md. All deviations are documented
in docs/decisions.md with written reasons and accepted risk.

| Baseline Area      | Status                                                  |
| ------------------ | ------------------------------------------------------- |
| Secret handling    | ✅ No secrets in any committed file                     |
| Authentication     | ✅ Strong password, non-default username                |
| Network exposure   | ✅ Localhost only                                       |
| Container security | ✅ No privileged mode, socket :ro validated             |
| Data protection    | ✅ Named volume, backup tested end to end               |
| Update strategy    | ✅ Pinned version, manual deliberate updates            |
| HTTPS              | ⚠️ Exception — HTTP only pre-Caddy, documented          |
| MFA                | ⚠️ Exception — not configured in this setup, documented |
