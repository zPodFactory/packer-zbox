# Releasing

Two scripts, standard library only, the same in every zPodFactory repository. What differs per
repository is the configuration block at the top of each one.

| Script | Does |
|---|---|
| `release.py` | cuts a version: changelog heading, version bump, commit, tag, push. Also `--check` and `--draft`. |
| `release_notes.py` | turns a version's `CHANGELOG.md` section into the GitHub release note. Run by the workflow. |

## Release in one command

You committed a few changes. Now:

```
python3 tools/release.py 0.2.0 --push --from-commits
```

- fills `[Unreleased]` in `CHANGELOG.md` from the commits since the last tag (subjects become the
  entries, grouped Added / Changed / Fixed / Removed; docs and version-bump commits are left out)
- turns `[Unreleased]` into `## [0.2.0] — <today>` and opens a fresh empty `[Unreleased]`
- sets the version in the script (or, for packer, points the build script at the new var file)
- runs the tests, if the repository has a suite
- commits `Release 0.2.0`, tags `v0.2.0`, pushes `main` and the tag

GitHub then runs `.github/workflows/release.yml` on the tag: the same checks, then the
`[0.2.0]` section is published as the release note, marked latest. About a minute.

Add `--dry-run` to see the section and the plan without changing anything.

## Release when you want to write the entries yourself

```
python3 tools/release.py --draft --write      # the commit candidates, written under [Unreleased]
$EDITOR CHANGELOG.md                          # reword, delete what nobody needs
git commit -am "Changelog for 0.2.0"
python3 tools/release.py 0.2.0 --push
```

`--draft` alone only prints the candidates. Or skip the draft and write the entries as you go:
every change gets a line under `[Unreleased]`, and the cut needs nothing else.

## What stops a release

`release.py` refuses, before changing anything:

- a working tree that is not clean, or a branch other than `main`
- an empty `[Unreleased]` (nothing to say is not a release; `--from-commits` fills it)
- a version that is not above the newest tag, or does not look like this project's versions
- packer: a var file for that version that does not exist yet
- a tracked `.env`, `*.log` or other file that must stay local
- any string from `.release-denylist` in the tree or in the commits since the last tag. That file
  is local and git-ignored: names that must never enter the history.

`python3 tools/release.py --check` runs the rules that must hold between releases too: the shipped
version equals the newest changelog section, every tag has a section, nothing local is tracked.
`.github/workflows/checks.yml` runs it on every push.

## Fixing a release note after the fact

Edit the section in `CHANGELOG.md`, commit, push. Then on GitHub: Actions, release, Run workflow,
version `0.2.0`. The release is updated in place; the tag never moves. A blank version republishes
every tag, which is also how releases are backfilled for old tags.

Never tag by hand, never edit a release in GitHub's editor: the file is the source, the release is a
copy.

## The configuration block

At the top of `release.py`:

| Setting | Meaning |
|---|---|
| `PROJECT` | name used in the tag message |
| `VERSION_FILE`, `VERSION_PATTERN` | where the shipped version is, and the regex (one group) that finds it |
| `VERSION_SHAPE` | `\d+\.\d+\.\d+` for the CLIs, `\d+\.\d+(\.\d+)?` for packer |
| `VERSION_IN_FILE` | what is written into `VERSION_FILE`: `{version}`, or `{major_minor}` for packer |
| `REQUIRED_FILES` | files that must exist before a cut, e.g. `zbox-{major_minor}.json` |
| `ALSO_UPDATE` | other files carrying the version, e.g. a README status line |
| `TEST_COMMAND` | run before the commit; `()` when there is no suite |
| `MUST_STAY_LOCAL` | regex for files that must never be tracked |

At the top of `release_notes.py`: `facts(version)`, markdown placed above the section. Empty for a
CLI; the ISO, its checksum, the OVA link and the build command for a packer appliance.
