# Repository setup: prebuilds and upstream settings

Maintainer and instructor documentation. Attendees do not need this.

The devcontainer is the most important asset in the repository. If it does not
come up cleanly, first time, in front of a room of fifteen people, the day is
lost. Codespaces prebuilds are the mechanism that makes that reliable.

## What a prebuild is

Normally, creating a Codespace builds the container image on the spot: pull the
base image, install the devcontainer features, run the create commands. That
takes minutes.

A prebuild does that work ahead of time, on a schedule or on push, and stores
the result. Creating a Codespace then restores a ready-made image instead of
building one.

## What a prebuild does and does not bake

This is the detail that determines how the devcontainer is structured, so it is
worth being precise. A prebuild bakes:

- the base image and everything in `.devcontainer/Dockerfile`
- all devcontainer **features**
- `onCreateCommand`
- `updateContentCommand`

A prebuild does **not** bake `postCreateCommand`. That runs every time a
Codespace is created, prebuilt or not.

The devcontainer in this repository is arranged accordingly:

| Where | What | Baked |
| --- | --- | --- |
| `Dockerfile` | JFrog CLI (pinned), `jq`, `tree` | Yes |
| `features` | docker-in-docker, GitHub CLI | Yes |
| `updateContentCommand` | `npm ci` for the sample apps | Yes |
| `postCreateCommand` | Welcome banner, `scripts/verify.sh` | No |

So the expensive work is in the first three rows. `postCreate.sh` is
deliberately cheap, and it carries an idempotent guard that installs
dependencies only if `node_modules` is missing, which covers the case where a
Codespace was created without a prebuild.

If you add something slow, put it in the `Dockerfile` or in
`updateContent.sh`, not in `postCreate.sh`.

## Enabling prebuilds

On the **upstream** repository, as an administrator:

`Settings` then `Codespaces` then `Set up prebuild`.

> [!IMPORTANT]
> VERIFY: confirm this navigation path and the exact field labels against the
> current GitHub UI before a delivery. GitHub moves repository settings around
> more often than JFrog moves theirs.

Configure:

- **Branch**: the branch attendees fork from, normally `main`.
- **Region**: the region attendees will create Codespaces in. Prebuilds are
  stored per region.
- **Trigger**: on push to the configured branch is the sensible default, with
  a scheduled refresh as a backstop.
- **Devcontainer configuration**: `.devcontainer/devcontainer.json`.

Two properties of prebuilds that catch people out:

1. **Prebuilds are per branch.** A prebuild on `main` does nothing for a
   Codespace created from another branch.
2. **Prebuilds are per region.** An attendee in a region you did not configure
   gets a cold build. If the room is in one place this is easy. If the
   delivery is remote across regions, configure the regions you expect.

## The fork problem, which is the one that actually bites

Attendees work from a **fork in their personal GitHub account**, not from the
upstream repository.

> [!IMPORTANT]
> VERIFY: confirm whether a fork inherits the upstream prebuild in the current
> GitHub Codespaces implementation, and record the answer here with the date
> you checked it. The safe assumption, and the one the timings in this
> repository are based on, is that it does not.

Assume it does not. The consequence is that **the number you care about is not
the number you will measure**. Creating a Codespace on the upstream repository
as a maintainer is the fast path. Creating one on a fresh personal fork is the
attendee's path.

Measure the attendee's path:

1. Fork the repository into a personal account that has never done so.
2. Create a Codespace on that fork.
3. Time it from clicking create to the welcome banner appearing.

## Targets

| Path | Target |
| --- | --- |
| Cold, no prebuild, 2-core | Under 5 minutes |
| Warm, with prebuild | Well under 2 minutes |

If the cold path is over five minutes, move work out of `postCreate.sh` and
into the image, or trim a feature.

## Other upstream repository settings

- **Actions enabled.** Labs 07 and 08 run workflows in the attendee's fork.
  Forks have Actions disabled by default and the attendee has to enable them,
  which lab 07 covers.
- **Codespaces enabled** for the repository.
- **`.devcontainer/devcontainer.json` on the default branch**, so the fork
  picks it up without the attendee switching branches.
- **Template repository**: not used. Attendees fork, so that their fork keeps a
  link to upstream and can pull fixes made during the day.

## A note on Codespaces quota

Codespaces on a personal account has a monthly free allowance, and an attendee
who has been using Codespaces for other work may have exhausted it. There is
no way to detect this ahead of the day. It appears as a failure to create a
Codespace at all.

Cover it in the room at the start rather than debugging it per person. See
[`codespaces-troubleshooting.md`](codespaces-troubleshooting.md).
