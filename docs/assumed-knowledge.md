# Assumed knowledge

What each lab takes as given, and where it was established.

This is the checklist for the newcomer review. The first review of this
workshop is done by someone who has just joined JFrog, working through it cold,
specifically to find the assumptions we made without noticing. This file is
what they work against: for each lab, read what it claims to assume, then check
the lab actually holds to it.

**Two rules the workshop is written to.** If a lab breaks either, that is a
bug worth reporting, not a gap in the reader.

1. **Zero prior JFrog knowledge.** Every piece of JFrog terminology is defined
   on first use and appears in the [glossary](glossary.md).
2. **No assumed knowledge of adjacent tooling beyond npm and Git.** Docker
   multi-stage builds, GitHub Actions syntax and OIDC each get an introduction
   where they are first needed, rather than being assumed.

**Status:** build phase 1. Lab 00 only. Later phases add to it.

---

## Assumed across the whole workshop

Established before lab 00, and never taught by it.

| Assumed | Notes |
| --- | --- |
| Basic command line use | Running a command, reading its output, editing a file. Not scripting. |
| Basic Git | Clone, commit, push, what a branch is. Fair for the audience. |
| Basic npm | That `package.json` declares dependencies and `npm install` fetches them. Not the resolution algorithm, and not lock file semantics, which lab 07 needs and therefore introduces. |
| A public registry exists | That packages normally come from somewhere like npmjs.org over the internet. |
| Reading a browser UI | Finding a tab, a dropdown, a dialog. |

**Deliberately not assumed anywhere:** JFrog products, artifact repository
management as a concept, CVEs and CVSS scoring, SBOMs, Docker, container
images, GitHub Actions, CI concepts beyond "a pipeline builds our code", OIDC,
supply chain security vocabulary.

---

## Lab 00: setup

**Format:** guided. **Prerequisites:** none.

### Takes as given

| Assumed | Where the attendee got it | Risk |
| --- | --- | --- |
| Has, or can create, a personal GitHub account | Prerequisite, stated in the root README and in step 1 | Low. Step 1 links to signup. |
| Can find the Fork button on a GitHub repository | General GitHub familiarity | Low, and a screenshot is on the [screenshot checklist](screenshot-checklist.md) to remove the risk entirely |
| Can open a terminal panel in a browser IDE | Not assumed. The lab says the terminal appears at the bottom and prints a banner | None |
| Can run a `bash` command | Assumed across the workshop | Low |
| Has the handout | Distributed by the instructor. Step 1 lists the four values on it | Medium if an attendee arrives late. Worth restating in the room. |

### Introduces

Every one of these is defined in the lab text on first use and is in the
[glossary](glossary.md): JFrog Platform, Artifactory, Xray, Curation, artifact,
instance, fork, Codespace, devcontainer, Project, project key, JFrog CLI,
server configuration, access token, Platform tab, Administration tab.

### Establishes for later labs

Things every subsequent lab is allowed to rely on. If a later lab needs one of
these and lab 00 has been skipped, the later lab must link back rather than
assume.

| Established | Used by |
| --- | --- |
| A running Codespace on the attendee's own fork | All labs |
| A JFrog CLI server configuration named `workshop` | 01 onward |
| `.env` containing `JF_URL`, `JF_PROJECT`, `JF_SERVER_ID` | 01 onward, and the CI workflows |
| The attendee knows their project key and has selected the project in the UI | 01 onward |
| The attendee has signed in to the web UI at least once | 01 onward |
| `bash scripts/verify.sh` is the first move when something breaks | All labs, and the troubleshooting guide |
| The instance is disposable, so experimenting freely is encouraged | All labs. This is stated once, in lab 00, and not repeated. |

### Known gaps

Honest notes on where this lab is thin.

- **The Codespaces quota problem cannot be pre-detected.** An attendee whose
  personal account has exhausted its free Codespaces allowance cannot start.
  Lab 00 does not mention it, because there is nothing useful an attendee can
  do about it mid-lab. It is covered in
  [codespaces-troubleshooting.md](codespaces-troubleshooting.md) and is
  something for the instructor to raise at the start.
- **The lab assumes the attendee can reach the JFrog instance from their
  browser.** A corporate proxy that blocks the instance URL would break step 5
  and the lab does not cover it, because the fix is not the attendee's to
  apply.
- **No closing challenge**, unlike every other guided lab in the workshop.
  This is deliberate and recorded in `PLAN.md`: there is no transferable
  mechanic here to reapply, and a challenge at minute five costs schedule for
  no learning.

---

## Later labs

Added in build phases 3 to 6, as the labs are written.

One thing to watch for as they land, because it is the most likely place for
this file to go stale: **challenge labs are where an unnoticed assumption does
the most damage.** A challenge that assumes knowledge the attendee does not
have is not a challenge, it is a dead end, and the attendee cannot tell the
difference between the two from the inside.
