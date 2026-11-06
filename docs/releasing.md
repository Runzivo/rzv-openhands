# Releasing

1. Merge to `main` with the `check` job green.
2. Add a `## vX.Y.Z` section to `CHANGELOG.md`, then tag: `git tag -a vX.Y.Z -m vX.Y.Z && git push origin vX.Y.Z`.
3. Create the GitHub release from the tag. The install command in the README points at the tag.
4. Update the skill in the [OpenHands extensions registry](https://github.com/OpenHands/extensions) with a pull request that copies `skills/runzivo/` to `skills/runzivo/` there and keeps its marketplace entry in `marketplaces/openhands-extensions.json`. Follow that repository's `AGENTS.md` and pull request template, and run `python scripts/sync_extensions.py` there before pushing.

The registry copy and this repository must match. Change the skill here first.
