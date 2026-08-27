# Instructor provisioning

Run once per delivery, against a fresh JFrog trial instance, before the day.

Everything here is instructor prep. Attendees never run it.

## What it creates

`prep.sh` creates exactly three things per attendee:

1. A **JFrog Project**, keyed `user01`, `user02` and so on.
2. A **user** with the same name, and a generated password.
3. A **project membership** giving that user the project administrator role
   inside their own project, and nowhere else.

Then it writes a handout to `provisioning/out/`.

## What it deliberately does not create

Repositories. Curation policies. Xray policies. Watches. Builds. Access
tokens. Any of the actual content of the workshop.

This is a design constraint, not an oversight. The workshop exists so that
attendees become familiar with the platform by creating things themselves, and
every resource this script creates is a resource an attendee does not learn to
create. The line is drawn at what is impossible or unreasonable for an
attendee to do from inside their own project: the project itself, their
account, their permissions.

If a lab would run more smoothly with something pre-created here, that is a
signal the lab needs rewriting. Raise it rather than extending this script.

## Prerequisites

- A JFrog trial instance, with Curation and JFrog Advanced Security already
  provisioned. Capability provisioning is outside this repository, and no lab
  checks for it. See [`../docs/tenant-prerequisites.md`](../docs/tenant-prerequisites.md).
- A **platform administrator access token** for that instance.
- `bash`, the **JFrog CLI** (`jf`) and `jq` on the machine you run this from.
  A Mac with the Xcode command line tools, `brew install jq` and the JFrog CLI
  is enough.

  The script talks to the platform through `jf api`, the CLI's authenticated
  passthrough to any JFrog Platform REST endpoint. That is deliberate on two
  counts: it reads better than a hand-built `curl`, and anyone poking around in
  this script picks up a command they can use themselves. The endpoint paths are
  cited inline, so you can still see exactly which REST APIs are being called.

  It writes its temporary CLI configuration to a throwaway directory, so it
  **cannot touch the server profiles you already have**, and the admin token
  never appears on a command line where `ps` would show it.

## Running it

```bash
cd provisioning
export JF_ACCESS_TOKEN='<platform admin token>'
./prep.sh --url https://example.jfrog.io --count 15
```

Look before you leap. `--dry-run` validates the token, prints the plan and
changes nothing:

```bash
./prep.sh --url https://example.jfrog.io --count 15 --dry-run
```

Full options: `./prep.sh --help`.

The token is read from `JF_ACCESS_TOKEN` rather than a flag by default, so it
does not end up in your shell history. `--token` exists but prefer the
environment variable.

### It is safe to re-run

Every step treats "already exists" as success. Re-running after a partial
failure fixes up what is missing and leaves the rest alone.

If a **user already exists**, the script does not reset their password, because
doing so would invalidate a handout you may already have distributed.

To keep the handout usable across re-runs, **passwords are carried forward from
the previous `handout.csv`**. So a re-run reproduces a complete, valid handout
rather than a table full of placeholders. The previous handout is also copied to
`handout.md.bak` and `handout.csv.bak` before being overwritten.

Where a password genuinely cannot be recovered, because the user existed before
this script ever ran, the row reads
`(unknown: reset in the UI or delete the user and re-run)`. Both of those work:
reset the password in the platform UI, or delete the user and let the next run
create them fresh.

## The handout

Written to `provisioning/out/`, which is gitignored:

- `handout.md`, a markdown table, easiest to print or paste into a slide.
- `handout.csv`, the same data, for a mail merge or a spreadsheet.

Both are written with `600` permissions and **contain attendee passwords**. Do
not commit them, do not paste them into chat, and delete them after the
delivery.

Each attendee needs four values, all of which are on their row plus the
instance URL at the top of the file:

| Value | Used in |
| --- | --- |
| Instance URL | Lab 00, signing in and configuring the CLI |
| Project key | Lab 00, and every lab after it |
| Username | Lab 00 |
| Password | Lab 00 |

Generated passwords avoid the characters that get misread off a printed page:
no `i`, `l`, `o`, `0` or `1`.

## Expect a password change on first sign-in

The platform may require a password change when an attendee first signs in to
the web UI. That is normal. If they change it, the new password is what
`scripts/setup.sh` needs in lab 00, not the one on the handout. Lab 00 says so,
but it is worth mentioning in the room.

## Teardown

Delete the projects, then delete the trial instance. There is nothing else to
do and no cleanup script to run.

The instance is disposable and is destroyed after every delivery, which is why
no lab step needs to be reversible and why attendees can be told to experiment
freely and try the destructive options.

One thing to know: **Curation policies are not owned by a project**, because
Curation has no project scoping. They survive project deletion. Deleting the
instance is what removes them. If you ever reuse an instance across
deliveries, which is not the intended model, the attendee-prefixed Curation
policies from the previous run need clearing by hand.

## If it fails

The script prints the failing HTTP status and the platform's own error message
for each step, and exits non-zero if anything failed.

**A 400 on the role assignment step** is the most likely failure, and it
almost certainly means the role name is different on your instance. The
default is `Project Admin`. Check the role names in the platform UI under your
project's Members tab and re-run with `--role`:

```bash
./prep.sh --url https://example.jfrog.io --count 15 --role 'Project Admin'
```

This is flagged in [`../docs/verification-checklist.md`](../docs/verification-checklist.md)
as needing confirmation against a live tenant.

**A 401** means the token is wrong or expired. **A 403** means the token is
valid but is not a platform administrator token.
