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

**Status:** build phase 4. Labs 00 to 06. Later phases add to it.

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

## Lab 01: Artifactory

**Format:** guided plus challenge. **Prerequisites:** lab 00.

### Takes as given

| Assumed | Where from | Risk |
| --- | --- | --- |
| A working Codespace and JFrog connection | Lab 00 | Low, and lab 01 links back |
| That `npm install` fetches packages from somewhere over the internet | Stated as assumed for the whole workshop | Low |
| Comfort clicking through a form-based admin UI | General | Low |
| That an `npm login` flow opening a browser tab is normal | Step 6 walks it through click by click | Low |

**Not assumed:** what a repository is, what proxying means, what a cache is, or
anything about Docker beyond the challenge naming Docker Hub. The Docker
challenge deliberately needs no Docker knowledge: it is the same three forms
with a different package type.

Note that step 5 no longer asks the attendee to edit `.env`. The repository names
are derived by `scripts/setup.sh` in lab 00, so step 5 is a check rather than an
edit, and it assumes nothing beyond running `grep`.

### Introduces

Repository, local, remote and virtual repository, cache, package type,
repository key, resolution, default deployment repository, Set Me Up. All
defined inline and in the [glossary](glossary.md).

### Establishes for later labs

| Established | Used by |
| --- | --- |
| Three npm repositories with the project prefix | 02, 03, 04, 07 |
| npm in the Codespace configured to resolve through Artifactory | 02, 03 |
| `JF_NPM_VIRTUAL_REPO` and `JF_DOCKER_REPO` in `.env` | 07, and the CI workflows |
| That a remote repository has a separate `-cache` repository | 03, 09, 10 |
| The habit of checking the project selector when something is missing | All later labs |

### Known gaps

- **Set Me Up writes a credential into `~/.npmrc`.** The lab says so and says why
  it is acceptable in a disposable container, but an attendee who takes that
  pattern back to a laptop has learned something slightly wrong. Lab 07 corrects
  it; if lab 07 is dropped for a customer, that correction is lost.
- The lab does not explain the npm protocol or what a registry API is. It does
  not need to, but an attendee who asks will not find the answer here.

---

## Lab 02: Curation

**Format:** guided plus challenge. **Prerequisites:** labs 00, 01.

### Takes as given

| Assumed | Where from | Risk |
| --- | --- | --- |
| An npm remote repository exists and npm resolves through it | Lab 01 | Low, and it is a checkpoint there |
| The attendee has the shared admin credentials | Lab 00 step 1 mentions them; the handout carries them | **Medium.** An attendee who mislaid the handout stalls here |
| Using a private browser window | Stated in step 1 | Low |
| That a software license is something with legal consequences | General professional knowledge | Low, and the lab does not need any specific license knowledge |
| That "malicious packages on npm" is a real phenomenon | Named in the challenge scenario | Low. The scenario explains itself |

**Not assumed:** what Curation is, how it differs from Xray, what a waiver is,
what an allow list versus a block list implies, or what package immaturity means.
The challenge is solvable from the concept section alone.

### Introduces

Curation, condition, policy, scope, allow list and block list by license,
immature package, blocked package, waiver, decision owners.

### Establishes for later labs

| Established | Used by |
| --- | --- |
| A license Curation policy scoped to the attendee's own remote | 11 |
| An approved waiver for `highcharts@8.2.0`, with an audit trail | 07 resolves without a block, 11 reads the record |
| An immaturity policy from the challenge | 11 |
| That some tasks need an admin account, and why | 11 |

### Known gaps

- **The blocked-install message is not yet in the lab.** It carries a VERIFY
  flag. Until it is captured, an attendee cannot easily tell a Curation block
  from a network failure, which is the most likely confusion in this lab.
- **Self-approving the waiver is pedagogically awkward.** The lab names this
  explicitly rather than hiding it, but it does mean the attendee never sees the
  separation of duties working, only described.
- The lab assumes the room will follow the scoping instruction. One attendee who
  does not affects everyone, and no amount of lab text fully removes that.

---

## Lab 03: Xray

**Format:** guided plus challenge. **Prerequisites:** labs 00, 01.

Note that lab 02 is **not** a prerequisite. Xray and Curation are independent,
and a customer who wants only one can have it.

### Takes as given

| Assumed | Where from | Risk |
| --- | --- | --- |
| npm repositories exist including a cache, and npm resolves through them | Lab 01 | Low |
| That vulnerabilities in dependencies are a thing worth managing | General | Low |
| Patience for asynchronous indexing | Step 4 says so explicitly | **Medium.** An impatient attendee concludes it failed |
| That a build can be failed by an automated check | General CI familiarity | Low. Not needed until lab 07 |

**Not assumed:** what a CVE or CVSS is, what a policy, rule or watch is, what
severity means, or what Contextual Analysis does. All defined before use.

### Introduces

Finding, violation, policy, rule, watch, severity, CVE, CVSS, Contextual
Analysis and all five of its verdicts, direct and transitive dependency, license
policy.

### Establishes for later labs

| Established | Used by |
| --- | --- |
| A Critical-only security policy that counts non-applicable findings | 07, where the build fails on it |
| A watch over the attendee's npm repositories | 07 extends it to the build |
| The finding versus violation distinction | 07 is built on it, 10 relies on it |
| That Contextual Analysis verdicts exist and what they mean | 05 teaches remediation using them |
| A real violation with the attendee's own name on it | 09, 10 |

### Known gaps

- **The lab assumes Xray policies are administrable inside a project.** If they
  turn out to be instance-level like Curation, the lab needs the shared admin
  account. This carries a VERIFY flag and is the largest open risk in Part 1.
- **Asynchronous indexing is the weakest point for classroom pacing.** If
  indexing is slow, fifteen people are waiting with nothing to do. The Going
  further section exists partly to absorb that.
- The lab does not explain how Xray decides severity, beyond noting that JFrog
  research contributes. An attendee who asks why JFrog disagrees with NVD gets a
  pointer in Going further rather than an answer.

---

## Lab 04: CLI

**Format:** guided plus challenge. **Prerequisites:** labs 00, 01, 02, 03.

### Takes as given

| Assumed | Where from | Risk |
| --- | --- | --- |
| A JFrog CLI server configuration named `workshop` | Lab 00 | Low, and it is a checkpoint there |
| A Curation policy scoped to the attendee's own remote | Lab 02 | Low. `jf curation-audit`'s challenge depends on it existing |
| Finding, violation, severity, CVE, Contextual Analysis and its five verdicts | Lab 03 | Low, and the lab links back rather than redefining them |
| Comfort editing `package.json` by hand | General | Low |

**Not assumed:** any prior use of a CLI security tool, or that an attendee has
ever seen a fixed-versions field before.

### Introduces

`jf audit`, `jf curation-audit`, and the idea that both run without a watch or
a policy attached first. All defined inline and in the
[glossary](glossary.md).

### Establishes for later labs

| Established | Used by |
| --- | --- |
| `axios` remediated to a patched version | 07, 09, 10 lose it as a finding |
| `node-fetch` remediated to a patched `2.x` version | Same |
| The habit of reading a fixed-versions field rather than guessing a version | 05, 06 |

### Known gaps

- **The exact default table columns `jf audit` prints have not been checked
  against a live tenant.** Carries a VERIFY flag. If they differ from what the
  lab describes, an attendee is not blocked, only mildly surprised.
- **Whether a waived package like `highcharts` reports as blocked, warning or
  approved under `jf curation-audit` is unconfirmed.** The lab hedges rather
  than asserting one of the three.

---

## Lab 05: IDE

**Format:** guided plus challenge. **Prerequisites:** labs 00, 01, 03.

### Takes as given

| Assumed | Where from | Risk |
| --- | --- | --- |
| The JFrog VS Code extension is already installed | The devcontainer, never taught explicitly before this lab | Low. The lab says so rather than assuming it went unnoticed |
| A JFrog CLI server configuration named `workshop` | Lab 00 | Low. The extension is designed to reuse it |
| Contextual Analysis and its five verdicts | Lab 03 | Low |
| Basic VS Code navigation: the activity bar, opening a folder | General | Low |

**Not assumed:** any prior use of a security-focused IDE extension, or any
distinction between SCA and SAST before this lab draws it.

### Introduces

SCA versus SAST as a distinction rather than just a word, and the two SAST
findings already documented in the sample application. Both are in the
[glossary](glossary.md).

### Establishes for later labs

| Established | Used by |
| --- | --- |
| `lodash` remediated to a patched version | 07, 09, 10 lose it as a finding |
| `moment` remediated to a patched version | Same |
| The two SAST findings, read but never fixed | Nothing later depends on them remaining, they simply stay |

### Known gaps

- **The sign-in flow and the scan results layout both carry VERIFY flags.**
  JFrog's own documentation describes two different shapes for the results
  view depending on which page you read, and this workshop has not resolved
  which one the pinned extension version actually shows.
- **Whether a Codespace in this workshop has GitHub Copilot available is not
  assumed anywhere load-bearing.** The Going further section mentions an
  agent-assisted fix option, but nothing in the checkpoint or challenge
  requires it.

---

## Lab 06: MCP

**Format:** guided plus challenge, optional. **Prerequisites:** labs 00, 01,
02, 04.

### Takes as given

| Assumed | Where from | Risk |
| --- | --- | --- |
| An AI coding agent is available in the room | Not guaranteed. The lab states this openly and nothing later depends on it | Medium, entirely outside this repository's control |
| A JFrog CLI server configuration named `workshop`, for the `JF_URL` value | Lab 00 | Low |
| The `highcharts` waiver and the immaturity policy from lab 02 | Lab 02 | Low, used only in Going further |
| That the attendee's agent supports MCP configuration at all | General, true of most current coding agents | Low, and the lab is written host agnostically for exactly this reason |

**Not assumed:** any prior use of MCP by name, or that the attendee's agent is
any specific product.

### Introduces

MCP, the Model Context Protocol, and a second Curation condition, package
version aged with no newer version identified, distinct from lab 02's
immaturity condition. Both in the [glossary](glossary.md).

### Establishes for later labs

Nothing later depends on this lab, by design. See PLAN.md's R3: an AI coding
agent may not be available on a given delivery, so nothing load-bearing can
live only here.

### Known gaps

- **Whether the JFrog MCP Server is enabled on this workshop's tenant at all
  is unconfirmed.** This is a platform administrator setting rather than
  something an attendee can fix, and it is the largest open risk in this lab.
- **The exact MCP client configuration shape and authorization flow have not
  been checked against a live tenant or a specific agent.** The lab is
  deliberately vague about which agent an attendee is using, which makes this
  harder to pin down than the UI-navigation VERIFY flags elsewhere.

---

## Later labs

Added in build phases 5 to 6, as the labs are written.

One thing to watch for as they land, because it is the most likely place for
this file to go stale: **challenge labs are where an unnoticed assumption does
the most damage.** A challenge that assumes knowledge the attendee does not
have is not a challenge, it is a dead end, and the attendee cannot tell the
difference between the two from the inside.
