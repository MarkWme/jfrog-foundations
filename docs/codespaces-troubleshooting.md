# Codespaces troubleshooting

The predictable failures, and what to do about them. If your problem is with
the JFrog Platform rather than the Codespace, see
[`troubleshooting.md`](troubleshooting.md).

Most of these are quicker to cover once, in the room, at the start of lab 00
than to debug fifteen times individually.

---

## The Codespace will not open, or the browser tab hangs

### A corporate proxy is blocking the Codespaces domains

This is the most common failure on a corporate laptop, and the most likely to
affect several people at once.

The web editor needs more than `github.com`. It also needs, at minimum:

- `github.dev`
- `*.github.dev`
- `*.githubpreview.dev`
- `*.app.github.dev`

A proxy that allows `github.com` and blocks `github.dev` produces a tab that
loads part way and then stalls, or an editor that never finishes connecting.

What to do, in order of preference:

1. **Use a personal device or a guest or mobile network.** Fastest fix by a
   wide margin, and it needs no approvals.
2. **Tether to a phone.** Works, and takes thirty seconds.
3. Ask the customer's IT to allow the domains. This is the right long-term
   answer and it will not happen during the workshop.

Worth raising with the customer before the day, as part of the prerequisites
conversation, rather than discovering it at 09:05.

### Codespaces quota is exhausted

Personal GitHub accounts include a monthly Codespaces allowance. An attendee
who already uses Codespaces may have used it up. It shows up as a refusal to
create the Codespace, with a billing or spending limit message.

Options:

- Delete unused Codespaces on that account. `github.com/codespaces` lists
  them. A stopped Codespace still consumes storage quota.
- Use a different personal account.
- Add a payment method, if the attendee is willing. Not something to push.

There is no way to check this ahead of the day, so ask at the start whether
anyone is a heavy Codespaces user.

### The account is a corporate GitHub account with policy restrictions

An enterprise-managed account may block forking to a personal namespace, block
Codespaces entirely, or restrict which machine types are available.

Use a personal account. The workshop prerequisites say personal for exactly
this reason.

---

## The Codespace opens but the environment looks wrong

### The Codespace opened in "recovery mode"

Recovery mode means container creation failed and Codespaces started a plain
fallback container instead, so it could give you a terminal to fix things with.
The tell is that none of the workshop tools are present and the environment
bears no resemblance to what lab 00 describes.

This is **not** something an attendee can fix, and it is not their mistake. It
means the devcontainer definition in the repository is broken for this
environment. Tell your instructor.

To see the actual cause: command palette, then
`Codespaces: View Creation Log`. Read for the **last** error before
`Creating recovery container`, not the first warning. The image can build
perfectly and the container still fail to start afterwards, so a log full of
successful build steps does not mean the build was the problem.

One failure of this shape has already been found and fixed during development:
a `remoteUser` in `devcontainer.json` naming a user that does not exist in the
base image, which produces
`unable to find user <name>: no matching entries in passwd file`.

### The welcome banner never appeared

The banner is printed by `.devcontainer/postCreate.sh`. If you did not see it,
either creation is still finishing or the create step failed.

Check the creation log: command palette, then
`Codespaces: View Creation Log`.

You can always run the health check by hand:

```bash
bash scripts/verify.sh
```

### A required tool is missing

`scripts/verify.sh` reports which one. This means the image did not build as
expected, and the fix is almost always a rebuild:

Command palette, then `Codespaces: Rebuild Container`.

If a rebuild does not fix it, use `Codespaces: Full Rebuild Container`, which
discards the cached image and builds from scratch. Slower, and more thorough.

### `jf` is present but the version is unexpected

`scripts/verify.sh` warns when the JFrog CLI on `PATH` is not the version the
image pinned. Usually this means a CLI was installed by hand into the
container and is shadowing the pinned one.

```bash
command -v jf
which -a jf
```

Remove the extra copy, or rebuild the container.

### The Docker daemon is not reachable

`scripts/verify.sh` reports this as a warning rather than a failure, because it
is frequently just a timing artifact in the first seconds after start. Wait a
moment and re-run the check.

If it persists:

```bash
docker info
```

A rebuild is the next step. The docker-in-docker feature occasionally fails to
start cleanly on a fresh container.

### `node_modules` is missing in a sample application

Dependencies are installed by `updateContentCommand`, which a prebuild bakes.
If you are on the unprebuilt path and something interrupted creation, install
them by hand:

```bash
bash .devcontainer/updateContent.sh
```

---

## The Codespace is slow to create

A cold create with no prebuild should finish in under five minutes on a 2-core
machine. Under two minutes with a prebuild.

If every attendee is slow, the likely cause is that **the fork did not inherit
the upstream prebuild**. That is expected behavior and it is why
[`repo-setup.md`](repo-setup.md) says to measure the attendee's path rather
than the maintainer's. There is nothing to fix on the day. It is a reason to
start lab 00 while doing the introductions.

---

## Port forwarding: the application is running but the browser shows nothing

The sample application listens on port 3000. Codespaces forwards it
automatically and shows a notification with an `Open in Browser` button.

If you missed the notification, use the **Ports** panel next to the terminal.
It lists forwarded ports with a local address for each.

Two things that look like a broken application but are not:

- **The port is forwarded as Private.** Private is the default and is correct:
  it works for you, in your browser, signed in to GitHub. It does not work for
  a colleague you send the URL to. To share, right-click the port and change
  visibility to Public. Do not do this out of habit.
- **You opened the wrong URL.** A forwarded port has a generated hostname. It
  is not `localhost:3000` in your own browser unless you are using the desktop
  VS Code client.

If the port is not listed at all, the application is not listening. Check the
terminal it was started in.

---

## Starting over

In escalating order of severity:

| Situation | Action |
| --- | --- |
| A tool is missing or misbehaving | `Codespaces: Rebuild Container` |
| A rebuild did not help | `Codespaces: Full Rebuild Container` |
| The Codespace is unrecoverable | Delete it at `github.com/codespaces` and create a new one |

Deleting a Codespace destroys anything you have not pushed. During this
workshop that is usually acceptable, and often faster than debugging. Your
JFrog-side work lives on the platform and is unaffected.

You will need to run `bash scripts/setup.sh` again in a new Codespace, because
the JFrog CLI configuration lives in the container, not on the platform.
