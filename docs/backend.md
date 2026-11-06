# Runzivo as an OpenHands backend

`bin/rzv-openhands-backend` runs an [OpenHands Agent Server](https://docs.openhands.dev/sdk/arch/agent-server.md) in a Runzivo sandbox and connects it to your machine through an SSH tunnel. Agent Canvas or the OpenHands SDK then uses it as a [remote backend](https://docs.openhands.dev/openhands/usage/agent-canvas/backend-setup/remote.md). This is the SSH-tunnel setup from the OpenHands [VM guide](https://docs.openhands.dev/openhands/usage/agent-canvas/backend-setup/vm.md); Runzivo opens no public port.

```sh
rzv-openhands-backend up --name my-task              # creates openhands-my-task, prints the backend URL
<password-manager-command> | rzv-openhands-backend key <sandbox-id> OPENAI_API_KEY
rzv-openhands-backend connect <sandbox-id>           # restarts the server with the key, reopens the tunnel
rzv-openhands-backend status <sandbox-id>            # status, time left, credits used
rzv-openhands-backend stop <sandbox-id>              # stops the charge; start, then connect, to wake it
rzv-openhands-backend down <sandbox-id>              # asks, then deletes the sandbox and its files
```

It needs `rzv` 0.26.0 or newer, signed in, and OpenSSH. Options for `up`: `--size`, `--lifetime 8h|12h|24h`, `--port` (local port, default 8000).

## What `up` does

1. `rzv sandboxes create --name openhands-<slug>`, then waits until it runs.
2. `rzv sandboxes ssh-config <sandbox-id> --write` for the `<sandbox-id>.rzv` alias.
3. Makes a random API key in `~/.config/rzv-openhands/<sandbox-id>.key` (mode 600) and sends it over SSH stdin to a mode 600 file in the sandbox.
4. Downloads Agent Server 1.60.1 (`agent-server-1.60.1-linux-x86_64`) from the OpenHands release, checks its SHA-256, and starts it on 127.0.0.1:8000 inside the sandbox, with `/workspace` as its workspace.
5. Opens `ssh -N -L 127.0.0.1:<port>:127.0.0.1:8000 <sandbox-id>.rzv` and checks `/health`.

## Connect

- Agent Canvas: Manage Backends, Add Backend, Host `http://127.0.0.1:8000`, and the key from the key file (`pbcopy < ~/.config/rzv-openhands/<sandbox-id>.key`).
- SDK: `Workspace(host="http://127.0.0.1:8000", api_key=<key>, working_dir="/workspace")`. `scripts/31-backend-task.py` is a full example.

## Model keys

`key <sandbox-id> <ENV_NAME>` reads a provider key on stdin and writes it over SSH to a mode 600 file in the sandbox. The Agent Server reads it as that environment variable, so the SDK can create `LLM(model=...)` without sending a key. If you type a key into Agent Canvas settings instead, it travels through the tunnel and the server stores it encrypted in the sandbox. Never use `rzv sandboxes exec --env` for keys.

## Stop, start and expiry

A stop ends the server and the tunnel. After `start`, run `connect`. Conversations are kept in `/workspace/openhands`, which survives a stop and start until the sandbox expires (8, 12 or 24 hours); do not count on other files surviving. Expiry or `down` deletes everything.

## Not available yet

Agent Canvas also has a built-in Providers tab (today only DigitalOcean). A Runzivo entry there would need public HTTPS access to the Agent Server in each sandbox, which Runzivo does not offer. Use the tunnel above until then.
