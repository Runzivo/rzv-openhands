# Usage

The skill teaches the agent these steps. Each is one `rzv` command that the agent runs in its terminal.

| Step | Command |
| --- | --- |
| Check sign-in | `rzv version`, `rzv whoami` |
| Create | `rzv sandboxes create --name openhands-<slug> [--size] [--lifetime 8h\|12h\|24h] --json` |
| Wait | `rzv sandboxes get <sandbox-id> --json` until `status` is `running` |
| Connect | `rzv sandboxes ssh-config <sandbox-id> --write`, then `ssh <sandbox-id>.rzv` |
| Run work | `ssh <sandbox-id>.rzv '...'`, `rsync`, or `rzv sandboxes exec <sandbox-id> -- '...'` |
| Status and cost | `rzv sandboxes get <sandbox-id> --json`: `expires_at`, `remaining_seconds`, `credits_used` |
| Sleep, wake | `rzv sandboxes stop <sandbox-id>`, `rzv sandboxes start <sandbox-id>` |
| Delete | `rzv sandboxes delete <sandbox-id>`, only after you confirm |

The agent finds `rzv` in `$RZV_BIN`, then `PATH`, then `~/.local/bin/rzv`.

## Names

Sandboxes are named `openhands-<slug>`, for example `openhands-fix-login`, so you can tell them apart in `rzv sandboxes list` and in the portal.

## Lifetime, stop and start

- Lifetimes are 8 hours (default), 12 or 24 where offered. A lifetime cannot be extended.
- A stopped sandbox is not charged. Running processes end at a stop.
- Files in `/workspace` are kept across a stop and start until expiry. Keep your work there; do not count on anything else surviving.
- At expiry or delete, the VM and all its files are removed.

## Billing

Runzivo bills the sandbox's running minutes to your workspace credit, at the rate of its size. `rzv sandboxes get` and `rzv sandboxes list` show the credits used. Your AI provider bills model use to you directly; Runzivo is not involved.

## OpenHands runs the agent on your machine

In the OpenHands CLI and a local Agent Canvas, the agent runs `rzv` on your computer with your sign-in. Headless mode (`openhands --headless`) approves every action without asking, so the agent's own confirmation before delete is the only check. Use the interactive CLI if you want to approve each command.

Errors and what to do: [skills/runzivo/references/errors.md](../skills/runzivo/references/errors.md).
