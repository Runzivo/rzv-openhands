# Testing

## Checks

`scripts/10-check.sh` validates the skill (name matches its directory, a description of at most 1024 characters, triggers, no em dashes, relative references exist) and keeps each Markdown file to 60 lines. CI runs it and `shellcheck` on `scripts/` and `bin/` on every pull request; the `check` job is required on `main`.

## Live end-to-end test

`scripts/20-shared-e2e.sh` runs the skill through the OpenHands CLI on a Runzivo test environment. Each step is one headless OpenHands run in a project with the skill in `.agents/skills/runzivo`; the script checks every result with `rzv`:

1. create `openhands-<run>` and wait for running
2. set up the SSH alias and write `/workspace/e2e.txt` over SSH
3. report status, time left and credits used
4. stop, then 5. start and read `/workspace/e2e.txt` back
6. a delete request without confirmation must not delete
7. a confirmed delete removes the sandbox

```sh
OPENHANDS_BIN=<openhands 1.16.0> OPENAI_KEY_FILE=<mode-600 key file> E2E_DIR=<empty dir> \
  scripts/20-shared-e2e.sh
```

It needs a signed-in `rzv` whose `rzv whoami` shows `Environment: shared`, and an OpenAI key file with mode 600 (the default model is `openai/gpt-5-nano`). It waits on a lock directory so one test at a time uses sandboxes, deletes every sandbox it created even on failure, removes OpenHands state, and fails if the key appears in its output.

`scripts/30-backend-e2e.sh` tests `bin/rzv-openhands-backend` the same way: `up`, a request without the API key is refused, `key`, one task through the OpenHands SDK (`scripts/31-backend-task.py`, `openhands-sdk` and `openhands-tools` 1.60.1), stop, start, `connect`, the task's file still in `/workspace`, `down` refusing without `--yes`, then `down --yes`.

Install the CLI from the [release page](https://github.com/OpenHands/OpenHands-CLI/releases/tag/1.16.0) and check the asset's SHA-256 against the digest shown there before running it.
