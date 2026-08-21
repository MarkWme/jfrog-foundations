# JFrog Foundations

A hands-on workshop that takes you from no prior JFrog experience to using the
JFrog Platform confidently across Artifactory, Curation, Xray, the developer
tooling and CI.

Everything runs in your browser through GitHub Codespaces. You need a browser
and a personal GitHub account. Nothing is installed on your laptop.

---

## Agenda

> [!IMPORTANT]
> **PLACEHOLDER.** Timings are not written yet. They are set in the final build
> phase, once every lab exists and its duration has been measured, so that the
> agenda and `docs/timings.md` actually agree with reality. Do not plan a
> delivery against this section yet.

The workshop is designed for a single day, in four parts, with the platform UI
labs deliberately last so that the admin views contain your own builds and scan
results rather than an empty demo.

## What you will be able to do afterwards

- Design an Artifactory repository layout, and explain why a virtual repository
  is the right thing to point a build at
- Control what enters your software supply chain from public registries, and
  justify the policy to someone who has to sign off on it
- Configure Xray policies and watches, and tell the difference between a scan
  finding and a policy violation
- Use the JFrog CLI and the VS Code extension to find and fix vulnerable
  dependencies before they reach a build
- Convert an existing CI pipeline to resolve through Artifactory, publish build
  information, scan a build and scan a container image
- Trace a CVE from a scan result back to the builds and artifacts it affects,
  and produce an SBOM
- Explain what changes when you do all of this in your own environment rather
  than in a workshop

## Getting started

Start here. It takes you from a browser to a verified working environment.

**[00 - Setup](labs/00-setup/README.md)**

You need the handout from your instructor: the instance URL, your project key,
your username and your password.

## Modules

Each lab is self-contained and declares its own prerequisites, so modules can
be swapped in or out for a given audience.

Labs are either **guided**, where every step is written out, or a
**challenge**, where you get a scenario and work out the solution yourself with
documentation links and a collapsible answer to fall back on. Every guided lab
ends with a challenge. The day moves from mostly guided to mostly challenge as
your footing improves.

### Part 1: Setup and configuration

| Lab | Focus | Format | Status |
| --- | --- | --- | --- |
| [00 - Setup](labs/00-setup/README.md) | Fork, Codespace, JFrog connection, project assignment, verification | Guided | Available |
| 01 - Artifactory | Local, remote and virtual repositories, and how resolution works | Guided + challenge | Phase 3 |
| 02 - Curation | Controlling what is allowed to enter from public registries | Guided + challenge | Phase 3 |
| 03 - Xray | Policies, watches, findings and violations | Guided + challenge | Phase 3 |

### Part 2: Developer experience

| Lab | Focus | Format | Status |
| --- | --- | --- | --- |
| 04 - CLI | JFrog CLI authentication, `jf audit`, `jf curation-audit` | Guided + challenge | Phase 4 |
| 05 - IDE | The JFrog VS Code extension: SCA, SAST, Contextual Analysis | Guided + challenge | Phase 4 |
| 06 - MCP _(optional)_ | The JFrog MCP Server, checking a dependency before you commit it | Guided + challenge | Phase 4 |

### Part 3: CI integration

| Lab | Focus | Format | Status |
| --- | --- | --- | --- |
| 07 - GitHub Actions | Package alias, build info, build scanning, image scanning, Job Summary | Mixed | Phase 5 |
| 08 - Frogbot | Pull request and branch scanning | Challenge | Phase 5 |

### Part 4: Exploring the platform UI

| Lab | Focus | Format | Status |
| --- | --- | --- | --- |
| 09 - Artifactory UI | Builds and artifacts, tracing versions and repositories | Challenge | Phase 6 |
| 10 - Xray UI | Scan results, impact analysis, SBOM export | Guided orientation + challenge | Phase 6 |
| 11 - Curation UI | Dashboard, audit logs, waiver approvals | Challenge | Phase 6 |

Lab 06 is optional. It is not a prerequisite for anything, and nothing taught
only there is needed later, because an AI coding agent is not available in
every customer environment.

## The sample application

The workshop uses a small Node.js application in `apps/`, added in the next
build phase, that ships with **known-vulnerable dependencies on purpose**. Those vulnerabilities are
the teaching material: you find them, trace them and fix them during the day,
using the platform.

Two consequences worth knowing up front:

- **Remediation is one way.** There are no reset or toggle scripts. You fix
  things properly, with the tooling, exactly as you would at work.
- **Some findings are left unfixed deliberately**, so that the later labs have
  real data to work with. The container base image in particular is never
  remediated during the workshop, and lab 07 explains why that is the point
  rather than an omission.

If an automated tool offers to upgrade a dependency in `apps/`, decline. See
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## Documentation

For attendees:

| Document | What it is for |
| --- | --- |
| [Glossary](docs/glossary.md) | Every JFrog term used, defined |
| [Troubleshooting](docs/troubleshooting.md) | When something does not work |
| [Codespaces troubleshooting](docs/codespaces-troubleshooting.md) | Proxies, quota, rebuilds, port forwarding |

For instructors and maintainers:

| Document | What it is for |
| --- | --- |
| [Tenant prerequisites](docs/tenant-prerequisites.md) | What to do before the day |
| [Provisioning](provisioning/README.md) | The prep script, and where its boundary is |
| [Repository setup](docs/repo-setup.md) | Codespaces prebuilds and upstream settings |
| [Verification checklist](docs/verification-checklist.md) | Every unverified step, to walk against a live tenant |
| [Screenshot checklist](docs/screenshot-checklist.md) | Every screenshot still to be captured |
| [Assumed knowledge](docs/assumed-knowledge.md) | What each lab takes as given |

## Prerequisites

- A **personal** GitHub account. Corporate and enterprise-managed accounts
  frequently restrict forking or Codespaces, which is slow to diagnose on the
  day. [Sign up free](https://github.com/join).
- A browser.
- The handout from your instructor.

Familiarity with `npm` and `git` is assumed. Familiarity with Docker
multi-stage builds, GitHub Actions or OIDC is **not**: those are introduced
where they come up.

## Building this repository

This repository is built in phases against [`SPEC.md`](SPEC.md), with the
agreed structure and design decisions recorded in [`PLAN.md`](PLAN.md). If you
are contributing, read [`CONTRIBUTING.md`](CONTRIBUTING.md) first, and note the
rule about never remediating a dependency in `apps/`.

## License

[MIT](LICENSE).
