# homelab-portainer — Runbook

Operational procedures for Portainer CE. All commands are run from the
homelab-portainer project root unless stated otherwise.

---

## Prerequisites

Before running any command on a new machine:

1. Docker Desktop installed and running
1. Corepack enabled: `corepack enable`
1. Yarn set to correct version: `yarn set version 4.10.3`
1. yamllint installed: `pip3 install yamllint==1.35.1`
1. Volume created manually: `docker volume create homelab-portainer-data`
1. Network created manually: `docker network create homelab-internal`

The volume and network must exist before starting the container. They are
declared as external in docker-compose.yml and will not be created
automatically. See docs/decisions.md Decision 017.

---

## Start

```bash
make up
```

This command creates the volume and network if not already present, starts the
Portainer container in the background, and prints the UI address on completion.

Portainer is available at <http://localhost:9000> once the container is running.

---

## Stop

```bash
make down
```

Stops and removes the container. The volume and network are preserved. All
Portainer data survives.

---

## Restart

```bash
make restart
```

Restarts the running container without removing it. Faster than down and up. Use
this after configuration changes that do not require a full redeploy.

---

## Check Status

```bash
make ps
```

Shows the current container status, image, and port bindings.

---

## Follow Logs

```bash
make logs
```

Streams live log output from the Portainer container. Press Ctrl+C to stop.

---

## Update Image Version

Before updating, check the Portainer CE changelog for breaking changes at
<https://github.com/portainer/portainer/releases>

Then update the version pin in docker-compose.yml:

```plaintext
image: portainer/portainer-ce:NEW_VERSION
```

Document the version change in docs/decisions.md with the date and reason. Then
run:

```bash
make update
```

This pulls the new image, stops the container, and starts it with the new image.

After updating, verify the container starts cleanly, the UI is accessible at
<http://localhost:9000>, login works with existing credentials, and all settings
and environments are intact.

---

## Backup

```bash
make backup
```

Exports the homelab-portainer-data volume to a timestamped tar archive in the
backups/ directory. The backups/ directory is gitignored and local only.

Example output file: `backups/portainer-data-backup-20260421-162647.tar.gz`

Run a backup before any image version update, any significant configuration
change, or any planned maintenance.

---

## Restore

To restore from a backup into a running Portainer instance:

1. Stop the container:

```bash
make down
```

1. Remove the existing volume:

```bash
docker volume rm homelab-portainer-data
```

1. Recreate the empty volume:

```bash
docker volume create homelab-portainer-data
```

1. Restore the backup archive into the volume:

```bash
docker run --rm \
  -v homelab-portainer-data:/target \
  -v "$(pwd)/backups:/backup" \
  alpine \
  sh -c 'cd /target && tar xzf $(ls /backup/*.tar.gz | tail -1)'
```

1. To restore a specific backup rather than the latest, replace the command
   with:

```bash
docker run --rm \
  -v homelab-portainer-data:/target \
  -v "$(pwd)/backups:/backup" \
  alpine \
  sh -c 'cd /target && tar xzf /backup/portainer-data-backup-20260421-162647.tar.gz'
```

1. Start the container and verify login works and all settings are intact:

```bash
make up
```

---

## Test Restore Without Affecting Production

```bash
make restore-test
```

This creates a temporary test volume, restores the latest backup into it, lists
the restored contents, and then removes the test volume. Production data is
never touched.

---

## Full Teardown

```bash
make clean
```

Stops the container and removes the volume and network. This destroys all
Portainer data. A confirmation prompt is shown before proceeding. Run a backup
before running clean.

---

## Validate Linting

```bash
make validate
```

Runs Prettier formatting check, yamllint, and markdownlint against all project
files. Use this before committing to confirm everything is clean.

---

## Troubleshooting

### Container fails to start — port already in use

**Symptom:** `docker compose up -d` fails with bind: address already in use.

**Cause:** Something else is already using port 9000 on localhost.

**Fix:**

```bash
lsof -i :9000
```

Identify the process using port 9000 and stop it. Then run `make up` again.

---

### UI shows login page but login fails

**Symptom:** Portainer loads at <http://localhost:9000> but credentials are
rejected.

**Cause:** Either the password was entered incorrectly or the volume was
recreated and the account no longer exists.

**Check:**

```bash
make logs
```

Look for authentication error messages.

**Fix — if volume was accidentally recreated:** Restore from the latest backup
using the restore procedure above.

**Fix — if password is genuinely forgotten:** The only recovery path is to
restore from a backup or reset the Portainer database by removing the volume and
starting fresh. All configuration will be lost.

---

### Container starts but UI is not reachable

**Symptom:** `make ps` shows the container as running but
<http://localhost:9000> does not load.

**Cause:** Port binding may not have applied correctly or the container is still
initialising.

**Fix:**

```bash
make logs
```

Wait for the line `starting HTTP server | bind_address=:9000` to appear. This
confirms Portainer is ready to serve requests. If the line never appears, check
for startup errors in the log output.

Also verify the port is bound correctly:

```bash
docker inspect homelab-portainer --format '{{json .HostConfig.PortBindings}}'
```

Expected output:

```plaintext
{"9000/tcp":[{"HostIp":"127.0.0.1","HostPort":"9000"}]}
```

---

### Volume or network not found on a new machine

**Symptom:** `make up` fails with volume not found or network not found.

**Cause:** The volume and network are declared as external and must be created
manually before the first `make up` on any machine.

**Fix:**

```bash
docker volume create homelab-portainer-data
docker network create homelab-internal
make up
```

---

### Container does not restart after Docker daemon restart

**Symptom:** After restarting Docker Desktop, the Portainer container is not
running.

**Cause:** The restart policy may not have been applied correctly.

**Check:**

```bash
docker inspect homelab-portainer --format '{{json .HostConfig.RestartPolicy}}'
```

Expected output:

```plaintext
{"Name":"unless-stopped","MaximumRetryCount":0}
```

**Fix:** If the restart policy is wrong, run `make down` and `make up` to
recreate the container with the correct policy from docker-compose.yml.
