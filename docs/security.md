# Security

- The skill is Markdown. It has no scripts, makes no network calls and reads none of your code.
- It uses your existing `rzv` sign-in. The agent never asks for a Runzivo token; if you are signed out it asks you to run `rzv login` yourself.
- It contains no AI provider keys. OpenHands uses the key you configure for it, on your machine.
- If a tool inside the sandbox needs a key, the skill tells the agent to have you pipe it over SSH stdin into a mode 600 file in the sandbox home. Keys never go on a command line, in `rzv sandboxes exec --env`, in `/workspace` or in the agent's replies.
- The agent asks before deleting a sandbox and only stops or deletes sandboxes it created or that you name.
- `bin/rzv-openhands-backend` calls only `rzv` and OpenSSH. Provider keys you give it with `key` are readable by commands the agent runs in that sandbox, as on any machine where an agent uses a key. Its Agent Server API key lives in `~/.config/rzv-openhands/` (mode 600) and reaches the sandbox over SSH stdin. The server listens on 127.0.0.1 in the sandbox; only your SSH tunnel reaches it. It downloads one pinned Agent Server release and checks its SHA-256.
- `rzv` keeps its credentials in its own owner-only files and never prints them.

Report a security problem through the contact on https://runzivo.dev, not a public issue.
