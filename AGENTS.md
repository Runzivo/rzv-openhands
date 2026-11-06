# rzv-openhands agent guide

A public MIT repository with one OpenHands skill, `skills/runzivo`, and `bin/rzv-openhands-backend`, which runs an OpenHands Agent Server in a sandbox behind an SSH tunnel. Customers read it, so commit nothing internal: no private repository names, hosts, workspace ids, unreleased plans or secrets.

- The skill and the helper only drive the `rzv` CLI (0.26.0 or newer). No API calls of its own, no tokens, no bundled AI keys, nothing that reads user code.
- Follow the [Agent Skills format](https://agentskills.io/specification) and the OpenHands `triggers:` extension. Use plain hyphens, never em dashes.
- Every Markdown file stays at 60 lines or fewer.
- Run `bash scripts/10-check.sh` and `shellcheck scripts/*.sh bin/*` before pushing. The live test is `scripts/20-shared-e2e.sh` ([docs/testing.md](docs/testing.md)).
- Third-party actions are pinned to full commit SHAs.
