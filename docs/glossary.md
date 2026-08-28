# Glossary

Every JFrog term the workshop uses, in plain language. Terms are also defined
where they first appear in a lab, so this is here for when you meet one again
three labs later and want a reminder.

This file grows with the labs. Terms are grouped by the lab that introduces
them, so if you are working through the workshop in order, you only ever need
to read down as far as where you are.

---

## The platform

**JFrog Platform**
The whole product. A single instance contains Artifactory, Xray, Curation and
the other services, sharing one set of users, permissions and projects.

**Artifactory**
The part that stores and serves packages, container images and other build
outputs. When a build resolves a dependency or publishes an artifact, it is
talking to Artifactory.

**Xray**
The part that scans what Artifactory holds, for known vulnerabilities and for
license problems, and applies your policies to what it finds.

**Curation**
The part that decides whether a package is allowed to be pulled in from a
public registry in the first place. Xray tells you about problems in what you
already have; Curation stops some of it arriving.

**Artifact**
Any file the platform stores: an npm tarball, a container image layer, a JAR, a
built binary. Note the spelling. This workshop uses US English throughout.

**Instance**
One deployment of the JFrog Platform, reached at one URL. The whole room shares
one instance today.

---

## Introduced in lab 00

**Project**
A workspace inside an instance, with its own repositories, users and
permissions. Projects are how fifteen people share one instance without
colliding. You are assigned one project and work inside it all day.

**Project key**
A project's short identifier, for example `user01`. The platform automatically
prefixes the names of resources you create inside the project with it, so
everyone in the room can create a repository called "npm" without a clash.

**JFrog CLI**
The `jf` command line tool. It is the main way you interact with the platform
from a terminal or a CI pipeline: resolving dependencies, publishing builds,
running scans.

**Server configuration**
A named set of connection details (URL plus credentials) that the JFrog CLI
stores locally, so you do not pass them on every command. This workshop calls
its configuration `workshop`. Created by `jf config add`, which
`scripts/setup.sh` runs for you.

**Access token**
A credential the platform issues that can be used instead of a password,
usually with a narrower scope and an expiry. Preferred over a password for
anything automated. You create one in lab 07 for CI.

**Platform tab / Administration tab**
The two main areas of the web UI. **Platform** is day-to-day work: browsing
artifacts, reading scan results, looking at builds. **Administration** is
configuration: repositories, users, policies.

---

## Introduced in lab 01

**Repository**
A container in Artifactory that holds artifacts of one package type. Everything
you store, proxy or resolve goes through one.

**Local repository**
A repository that stores artifacts you produced. Your builds publish here.
Nothing outside your instance is involved.

**Remote repository**
A proxy for a repository somewhere else, such as npmjs.org or Docker Hub. It
fetches on demand and keeps a copy. You cannot publish to one, because you do not
own what it proxies.

**Cache**
The stored copy a remote repository keeps after fetching something. Artifactory
exposes it as a separate repository whose key ends in `-cache`. It is why the
second request is fast, and why an upstream outage does not stop your build.

**Virtual repository**
A repository that aggregates other repositories behind a single name, and stores
nothing itself. It **aggregates** its members: it does not copy them. Point
builds at one of these.

**Package type**
The kind of package a repository holds, and the protocol it speaks. npm, Docker,
Maven, PyPI and so on. Fixed when the repository is created.

**Repository key**
A repository's unique name. Inside a project, your project key is prefixed
automatically, so `npm-local` becomes `user01-npm-local`.

**Resolution**
The act of a package manager asking a repository for a dependency and getting it.
"Resolving through Artifactory" means your package manager asks Artifactory
rather than the public registry.

**Dependency confusion**
An attack where someone publishes a public package using the same name as one of
your internal packages, hoping a build resolves theirs instead of yours.
Ordering local repositories before remote ones inside a virtual repository is the
mitigation.

**Set Me Up**
The UI action that generates the configuration a package manager needs to
resolve through a given repository, including credentials.

---

## Introduced in lab 02

**Curation**
The part of the platform that decides whether a package may enter your instance
at all. It evaluates packages arriving through a remote repository **before**
they are cached. Xray reports on what you have; Curation controls what arrives.

**Curation condition**
A reusable test that defines what makes a package unacceptable: a license, a CVE
severity range, an age since publication, a known-malicious flag. Conditions
exist independently of policies, so one can serve several.

**Curation policy**
A condition, a scope, an action and a waiver setting, combined and named. The
scope names which remote repositories it applies to.

**Allow list by license**
A condition that permits only the licenses you name and refuses everything else.
Default-deny: it catches licenses nobody has considered yet.

**Block list by license**
The opposite. It refuses the licenses you name and permits the rest, so it only
ever catches what you already knew to look for.

**Immature package**
A package version published more recently than a threshold you set. Blocking
these creates a cooldown, which is the standard mitigation against malicious
versions being picked up automatically within hours of publication.

**Blocked package**
A package Curation refused. The developer sees an install failure; the platform
records which policy stopped it and why.

**Waiver**
A recorded, approved exception permitting one specific package version despite a
policy. Not the same as disabling the policy, and the difference is that a waiver
is attributable.

**Decision owners**
The group permitted to approve a waiver. Having the requester and the approver be
different people is the entire point.

---

## Introduced in lab 03

**Finding**
Something Xray observed, such as a CVE affecting a component you hold. Xray
reports every finding it knows about, whether or not you have decided to act.

**Violation**
A finding that matched a rule in a policy attached by a watch. Violations have
consequences: a failed build, a notification, a blocked promotion. **The set of
findings is always larger than the set of violations**, and that is by design.

**Policy**
A named set of rules describing what you consider unacceptable. Written once,
applied in many places.

**Rule**
One condition inside a policy, plus the action to take when it matches. A policy
may hold several, commonly one per severity with different actions.

**Watch**
The binding between policies and the things they apply to: repositories, builds
or release bundles. A policy with no watch does nothing at all.

**Severity**
How serious a finding is. Critical, High, Medium, Low, Unknown. JFrog assigns
this using its own research as well as public data, so it can differ from the
score published elsewhere.

**CVE**
Common Vulnerabilities and Exposures. The public identifier for a specific known
vulnerability, such as `CVE-2021-44906`.

**CVSS**
Common Vulnerability Scoring System. A numeric score from 0 to 10 estimating
technical severity. Related to, but not the same as, the severity label.

**Contextual Analysis**
Analysis of whether a vulnerability is actually reachable given how you have used
the component. Produces one of: **Applicable**, **Not Applicable**, **Missing
Context**, **Undetermined**, **Not Covered**. Only `Applicable` means reachable.
`Not Covered` means nobody looked.

**Direct dependency**
A dependency your project declares itself, in `package.json` or equivalent.

**Transitive dependency**
A dependency of a dependency. You did not ask for it, and you usually cannot fix
it without changing the thing that did.

**License policy**
A policy that acts on the licenses of components rather than their
vulnerabilities.

---

## Introduced in labs 04 to 06

_Added in build phase 4. `jf audit`, `jf curation-audit`, SCA, SAST, secrets
detection, IaC scanning, MCP server._

Contextual Analysis, applicability, and direct versus transitive dependencies are
already defined under lab 03 above, since lab 03 needs them first.

---

## Introduced in labs 07 and 08

_Added in build phase 5. Build info, build scan, package alias, Job Summary,
Frogbot, OIDC, identity mapping._

---

## Introduced in labs 09 to 11

_Added in build phase 6. Impact analysis, SBOM, CycloneDX, SPDX, audit log,
curation dashboard._
