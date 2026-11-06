# Runzivo for OpenHands

An [OpenHands](https://github.com/OpenHands/OpenHands) skill that lets an OpenHands agent run work in a [Runzivo](https://runzivo.dev) sandbox: a Linux VM in your Runzivo workspace. The agent creates the sandbox, connects over SSH, runs commands, reports status, cost and expiry, stops and starts it, and deletes it after you confirm.

[![CI](https://github.com/Runzivo/rzv-openhands/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Runzivo/rzv-openhands/actions/workflows/ci.yml) [![Latest release](https://img.shields.io/github/v/release/Runzivo/rzv-openhands)](https://github.com/Runzivo/rzv-openhands/releases/latest) [![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE) [![Runzivo](https://img.shields.io/badge/Runzivo-sandboxes-0B0F14)](https://runzivo.dev/sandboxes/)

<img src="assets/demo.gif" width="1200" alt="Animated demo of the Runzivo skill for OpenHands, in a terminal panel: the skill is cloned at v0.1.0 and copied to ~/.agents/skills, then OpenHands headless tasks have the agent run rzv to create openhands-e2e191030, write the SSH alias and run uname -sm (Linux x86_64) and write /workspace/e2e.txt over SSH, show status (running, about 7 hours 58 minutes left, about 1.57 minutes of credits), stop, start and read skill-ok back from /workspace, and delete only after the user confirms. The sandbox ID shown is a placeholder." />

The skill is Markdown only. It calls the `rzv` CLI that you already use; it has no code of its own, stores no tokens and contains no AI provider keys.

## Requirements

- `rzv` 0.26.0 or newer, signed in with `rzv login`. Install it with `curl -fsSL https://runzivo.dev/downloads/rzv/install.sh | sh`.
- OpenSSH on macOS or Linux for the `<sandbox-id>.rzv` alias. Without it the agent uses `rzv sandboxes exec`.
- An OpenHands version that loads Agent Skills from `.agents/skills/` (the CLI 1.16.0 and Agent Canvas do).

## Install

For every project (user skill):

```sh
git clone --depth 1 --branch v0.1.0 https://github.com/Runzivo/rzv-openhands.git
mkdir -p ~/.agents/skills && cp -R rzv-openhands/skills/runzivo ~/.agents/skills/
```

For one project, copy `skills/runzivo` to `<project>/.agents/skills/runzivo` instead. The skill loads when your message mentions Runzivo, or when the agent decides it needs it.

## Use

Ask OpenHands, for example:

- "Create a Runzivo sandbox and run the test suite there."
- "What is the status of my Runzivo sandbox, and how much has it cost?"
- "Stop the Runzivo sandbox." / "Delete the Runzivo sandbox."

Sandboxes the skill creates are named `openhands-<slug>`. More in [docs/usage.md](docs/usage.md).

## Run the OpenHands agent itself in a sandbox

`bin/rzv-openhands-backend up` starts an OpenHands Agent Server in a Runzivo sandbox and tunnels it to `http://127.0.0.1:8000` over SSH, for Agent Canvas or the SDK. See [docs/backend.md](docs/backend.md).

## Docs

| Page | What it covers |
| --- | --- |
| [Usage](docs/usage.md) | What the agent does, persistence, billing |
| [Backend](docs/backend.md) | The Agent Server in a sandbox, over an SSH tunnel |
| [Security](docs/security.md) | Keys, sign-in and what the skill never does |
| [Testing](docs/testing.md) | Checks and the live end-to-end test |
| [Releasing](docs/releasing.md) | Tags and the OpenHands extensions registry |

## Licence

MIT. `rzv` and the Runzivo service have their own licences and terms.
