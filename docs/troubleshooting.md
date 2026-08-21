# Troubleshooting

Start here when something does not work. Most problems fall into one of three
buckets, and knowing which one you are in saves a lot of time.

| Symptom | Go to |
| --- | --- |
| The Codespace will not open, a tool is missing, a port will not forward | [Codespaces troubleshooting](codespaces-troubleshooting.md) |
| The JFrog CLI cannot connect or authenticate | [Connection problems](#connection-problems) below |
| A lab step behaves differently from what the lab says | [When a lab is wrong](#when-a-lab-is-wrong) below |

Each lab also has its own troubleshooting section covering the two or three
failures most likely in that lab specifically. Check there too.

---

## First move, always

```bash
bash scripts/verify.sh
```

It checks your tools, your configuration and your JFrog connection separately,
so it tells you which of the three is broken. That is usually most of the
diagnosis.

---

## Connection problems

### `jf rt ping` fails, or `scripts/setup.sh` says the connection failed

In rough order of likelihood:

**The URL has a path on the end.** The CLI wants the platform base URL, for
example `https://example.jfrog.io`. A URL copied out of the browser address bar
is often `https://example.jfrog.io/ui/login` or similar. `scripts/setup.sh`
strips a `/ui` path for you, but check what it actually used.

**The password changed.** If the platform made you set a new password when you
first signed in to the web UI, the handout password is no longer valid. Use the
current one.

**You have not signed in to the web UI yet.** Do that first, then configure the
CLI.

**A typo in a password you cannot see.** Password entry is deliberately not
echoed. Just run `bash scripts/setup.sh` again: re-running is safe and expected.

Whatever you change, re-confirm:

```bash
bash scripts/verify.sh
```

### `jf` commands worked and have stopped working

**Are you in a new Codespace?** The JFrog CLI configuration lives inside the
container, not on the platform. A new or rebuilt Codespace has no
configuration, and you need to run `bash scripts/setup.sh` again. Your work on
the platform is unaffected.

Check what the CLI currently thinks:

```bash
jf config show
```

### A command fails with a permissions error

Check you are operating inside your own project. Your project key is in `.env`:

```bash
grep JF_PROJECT .env
```

Many commands take a `--project` flag, and if it is missing or wrong you can be
denied access to something you do own.

If the resource genuinely is inside your project and you are denied, that is a
permissions question for your instructor rather than something to fix yourself.

### A package install is blocked

If a package install fails with a message about the package being blocked
rather than a network error, that is **Curation** doing its job, and it is
probably your own policy from lab 02 doing it.

That is a feature, not a fault, and lab 02 covers both legitimate ways out:
request a waiver, or correct the policy. The important first step is reading
the message rather than retrying the command.

If a Curation policy you created is blocking more than you intended, check its
**scope**. A policy scoped tenant-wide instead of to your own repositories will
affect the whole room. Fix the scope, and tell your instructor.

---

## When a lab is wrong

The JFrog Platform UI changes, and parts of this workshop describe click paths
that were correct when they were written.

Steps that have not been verified against a live instance are marked in the
text:

> [!IMPORTANT]
> VERIFY: what needs checking.

If you hit one of these and the UI does not match, you have found a real gap
rather than made a mistake. Tell your instructor: the whole set is collected in
[`verification-checklist.md`](verification-checklist.md) and gets corrected
from feedback like this.

The same applies to anything where the lab says one thing and the platform does
another. Say so. It is more useful than working around it silently.

---

## Things that are not problems

A short list of things that look wrong and are not.

**The health check says no JFrog server is configured.** Correct, before lab
00. The environment is built to come up cleanly with no credentials.

**`npm ci` printed vulnerability warnings.** Expected. The sample application
ships with known-vulnerable dependencies on purpose, and finding them is the
workshop. The container creation step suppresses `npm audit` output for this
reason, but other tooling may still comment.

**A scan shows findings but the build passed.** Also expected, and it is one of
the more important ideas in the workshop. What a scan *finds* and what a policy
*enforces* are two different surfaces. Lab 07 covers this directly.

**You broke something on the platform.** Fine. This instance is destroyed after
the workshop. There is no shared state to protect and no cleanup to run.
Experiment, including with the destructive options.

---

## Getting unstuck in a challenge lab

Challenge labs have a timebox and a collapsible solution. Reading the solution
when you are stuck is a legitimate exit, not a failure, and the labs say so
deliberately.

An attendee who reads the solution at fifteen minutes and understands it has
learned more than one who copied commands for fifteen minutes. Use the timebox.
