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

_Added in build phase 3. The terms this section will cover are: repository,
local repository, remote repository, virtual repository, package type,
resolution, caching, and repository layout._

---

## Introduced in lab 02

_Added in build phase 3. Curation policy, curation condition, blocked package,
waiver, waiver request._

---

## Introduced in lab 03

_Added in build phase 3. Policy, rule, watch, violation, finding, severity,
CVE, CVSS, license policy, JFrog Security Research severity._

---

## Introduced in labs 04 to 06

_Added in build phase 4. `jf audit`, `jf curation-audit`, SCA, SAST,
Contextual Analysis, applicability, direct and transitive dependency, MCP
server._

---

## Introduced in labs 07 and 08

_Added in build phase 5. Build info, build scan, package alias, Job Summary,
Frogbot, OIDC, identity mapping._

---

## Introduced in labs 09 to 11

_Added in build phase 6. Impact analysis, SBOM, CycloneDX, SPDX, audit log,
curation dashboard._
