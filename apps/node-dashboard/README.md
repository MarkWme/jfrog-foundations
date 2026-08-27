# Service Status dashboard

The sample application for the JFrog Foundations workshop. A small Express
service that renders a status dashboard for a handful of fictional internal
services, plus a JSON API.

> [!WARNING]
> **This application ships known-vulnerable dependencies on purpose.** They are
> the teaching material for the Curation, Xray and CI labs. Do not upgrade,
> patch or "fix" anything here outside of the lab that asks you to, and never
> merge an automated dependency bump. See
> [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

The application itself is deliberately dull. Server-rendered HTML, no bundler,
no frontend framework, no build step. Nobody attending this workshop should
have to debug the sample application, only its dependencies.

---

## Running it

Dependencies are installed automatically when your Codespace is created. If
`node_modules` is missing, see [Generating the lock file](#generating-the-lock-file).

```bash
cd apps/node-dashboard
npm start
```

Then open the forwarded port 3000 from the **Ports** panel in your Codespace.

### Routes

| Route | What it does | Dependency it exercises |
| --- | --- | --- |
| `GET /` | Dashboard page with a 24 hour uptime chart | `express`, `highcharts`, `moment` |
| `GET /api/status` | Aggregated status JSON, including an upstream probe | `lodash`, `axios` |
| `GET /api/upstream` | Legacy upstream poller | `node-fetch` |
| `GET /api/token` | Mints a short-lived bearer token | `jsonwebtoken` |
| `GET /api/admin` | Token-protected detail view | `jsonwebtoken` |
| `GET /api/diagnostics` | Streams a `.tar.gz` support bundle | `tar` |
| `GET /healthz` | Liveness check, does no work | none |

Exercising the protected route:

```bash
TOKEN=$(curl -s localhost:3000/api/token | jq -r .token)
curl -s -H "Authorization: Bearer $TOKEN" localhost:3000/api/admin | jq
```

### Configuration

All optional. The defaults work offline.

| Variable | Default | Notes |
| --- | --- | --- |
| `PORT` | `3000` | |
| `HOST` | `0.0.0.0` | Must be `0.0.0.0` for Codespaces port forwarding |
| `UPSTREAM_URL` | `https://example.com/` | A reserved documentation domain, so an unreachable upstream degrades gracefully rather than hanging |
| `UPSTREAM_TIMEOUT_MS` | `1500` | |
| `JWT_SECRET` | a placeholder | See the note below |

`src/app.js` falls back to a hardcoded `JWT_SECRET` so the token routes work
out of the box. **It is not a real credential**, and it is left in place partly
because it is a realistic finding for the secrets scanning in labs 05 and 07 to
have something to say about. It is not a pattern to copy.

---

## Dependency table

This is the instructor's answer key. It documents the **intended starting
state** and which lab consumes each finding. It is not a script for a reset:
there is no reset, and no toggle scripts exist anywhere in this repository.
Remediation is one way, exactly as it is at work.

CVE identifiers and severities below were confirmed against the JFrog Catalog
at build time.

> [!NOTE]
> Two caveats on this table. The Catalog returns at most ten CVEs per package,
> so the lists for `axios`, `lodash` and `tar` are **truncated**, not complete.
> And CVE data moves: new advisories land against old versions all the time.
> The authoritative list for a given delivery is whatever Xray reports on your
> own instance. Treat this table as the shape of the answer, not the whole of it.

| Package | Shipped | Verified CVEs | Highest | Direct or transitive | Remediated in |
| --- | --- | --- | --- | --- | --- |
| `axios` | 0.21.0 | CVE-2026-42043, CVE-2025-62718, CVE-2024-57965, CVE-2026-44496, CVE-2026-44495, CVE-2026-44492, CVE-2026-44490, CVE-2026-44487, CVE-2026-44486, CVE-2026-42039 (truncated) | Critical | Direct | **Lab 04**, guided |
| `lodash` | 4.17.15 | CVE-2026-4800, CVE-2020-8203, CVE-2021-23337, CVE-2026-2950, CVE-2025-13465, CVE-2020-28500 | Critical | Direct | **Lab 05**, guided, from the IDE |
| `minimist` | 1.2.5 | CVE-2021-44906 | Critical | **Transitive**, via `tar` to `mkdirp@0.5.5` | **Lab 07**, by bumping `tar` |
| `tar` | 4.4.8 | CVE-2026-73566, CVE-2026-59874, CVE-2026-59873, CVE-2026-59871, CVE-2026-26960, CVE-2026-24842, CVE-2021-37712, CVE-2021-37701, CVE-2021-32804, CVE-2021-32803 (truncated) | High | Direct | **Lab 07**, as the carrier of `minimist` |
| `moment` | 2.29.1 | CVE-2022-24785, CVE-2022-31129 | High | Direct | **Lab 05**, challenge |
| `jsonwebtoken` | 8.5.1 | CVE-2022-23539, CVE-2022-23540, CVE-2022-23541 | High | Direct | **Never.** Kept for lab 10 |
| `node-fetch` | 2.6.0 | CVE-2020-15168, CVE-2022-0235 | Medium | Direct | **Lab 04**, challenge |
| `express` | 4.16.0 | CVE-2024-29041, CVE-2024-43796 | Medium | Direct | **Never.** Kept for labs 09 and 10 |
| `highcharts` | 8.2.0 | None. License `LicenseRef-jfrog-highcharts` | n/a | Direct | **Never.** Blocked by Curation in lab 02, waived in lab 11 |

### Why some findings are never fixed

Once an attendee remediates a dependency, every later lab loses it as teaching
material. The set above is therefore layered on purpose:

- `express` and `jsonwebtoken` survive to the end, so labs 09 and 10 have real
  findings to explore. They also demonstrate the distinction that matters most
  in the workshop: the Xray policy configured in lab 03 fails on **Critical
  only**, so these are **findings that are not violations**.
- `highcharts` carries no CVE at all. It trips Curation on **license** grounds,
  which is what stops the Curation labs from being a duplicate of the Xray labs.
- The **container base image** is never remediated. See below.

The full sequence, and the reasoning behind the ordering, is in
[`PLAN.md`](../../PLAN.md) section 3.

### Why `minimist` is transitive

`minimist` is not in `package.json`. It arrives through `tar@4.4.8`, which
depends on `mkdirp@^0.5.0`, which depends on `minimist`. That gives lab 10 a
real two-hop trace for impact analysis, and gives lab 07 a Critical that
**cannot be fixed by editing the line that caused it**, which is a far better
exercise than a direct pin.

It also depends entirely on the lock file, which is the next section.

---

## Generating the lock file

`package-lock.json` is the most load-bearing file in this application. It, not
`package.json`, is what fixes the transitive vulnerabilities the later labs
depend on.

The version resolved matters. `tar@4.4.8` asks for `mkdirp@^0.5.0`. Resolved
today that gives `mkdirp@0.5.6`, which pulls `minimist@1.2.8` and is
**patched**, so the transitive Critical silently disappears. Resolved as at late
2020 it gives `mkdirp@0.5.5`, which pulls `minimist@1.2.5` and carries
CVE-2021-44906 at Critical.

### Who regenerates it, and when

**It is a committed artifact and a one-time maintainer task.** It is not
generated per attendee and it is deliberately not wired into
`scripts/setup.sh`.

That is a design decision, not an omission. If every attendee regenerated it,
the transitive tree would drift between deliveries: new advisories land against
old versions constantly, and transitive dependencies patch themselves. The
dependency table above would stop matching what Xray reports, and the
remediation sequence the labs depend on would decay silently. A committed lock
file is what makes the workshop reproducible, and `npm ci` is what enforces it.

Regenerate it only when the dependency set in `package.json` changes:

```bash
bash scripts/regenerate-lockfile.sh
```

Run that **inside a Codespace**. The script removes `node_modules`, resolves
with the date cutoff, and then verifies its own output. It refuses to run if npm
is pointed anywhere other than public npm, and it fails loudly if the required
transitive versions did not land, because both mistakes are otherwise silent.

### Why it is a script rather than an instruction

Three things have to be true at once, and getting any of them wrong fails
quietly:

1. **A clean tree.** npm seeds resolution from whatever is already in
   `node_modules`. If modern versions are installed they satisfy the caret
   ranges, nothing gets re-resolved, and `--before` does nothing whatsoever.
   This is exactly how the first attempt produced `minimist@1.2.8` instead of
   `1.2.5`: the devcontainer had already installed current versions at
   create time.
2. **Public npm.** A lock file resolved through Artifactory embeds the tenant
   hostname in every `resolved` URL, and this repository may never contain a
   real tenant URL. A maintainer machine configured for JFrog will fail this
   check, which is the intended behavior.
3. **The date cutoff.** `2020-11-01` sits just after the newest direct pin,
   `axios@0.21.0` from October 2020, so every direct pin still resolves while
   the transitive tree freezes period-accurate.

> [!IMPORTANT]
> After regenerating, confirm the chain from npm's own point of view:
>
> ```bash
> cd apps/node-dashboard && npm ls minimist mkdirp
> ```
>
> Expect `mkdirp@0.5.5` and `minimist@1.2.5`. If you see `minimist@1.2.8` the
> cutoff did not take effect and lab 07 has no subject.

---

## Container image

`Dockerfile` is a two-stage build, and the split carries teaching material in
both directions.

**Build stage: `node:22-bookworm-slim`.** Current, and resolves dependencies
from the committed lock file. In lab 07 this resolution moves to Artifactory.

**Runtime stage: `node:16.20.2-bullseye-slim`.** Pinned to an exact patch, and
pinned deliberately old. This is the third layer of the vulnerability story.

The narrative in lab 07 depends on this. The attendee remediates the
application's dependencies through the earlier labs, the build goes green,
`jf audit` is satisfied and the build scan passes. Job done, apparently. Then
they look at the Xray scan of the resulting container image and find CVEs that
exist nowhere in their source code, inherited entirely from this base image.

Two points land at once, and both matter:

1. Securing the dependencies you chose is not the same as securing the thing you
   ship. The attendee's code is clean. The artifact is not.
2. **Scan findings and policy violations are not the same thing.** These
   findings need not stop the build. The policies were configured to catch
   particular conditions and they behaved correctly.

The property that makes this work is **provenance being obvious**: base image
findings appear in Xray as Debian package components, not npm components, so
when the attendee looks at the results the source of each finding is
unambiguous.

> [!IMPORTANT]
> VERIFY: scan this image on the delivery instance and confirm two things.
> First, that the base image produces a credible set of findings, and second,
> that they are clearly attributable to Debian packages rather than to anything
> in `package.json`. High or critical severity is **not** required here: clear
> provenance matters more than severity. If the finding set is too thin, the
> fallback is non-slim `node:16.20.2-bullseye`, then a `buster` tag. Logged in
> [`docs/verification-checklist.md`](../../docs/verification-checklist.md).

**The attendee never fixes the base image.** Lab 07 discusses base image
selection, rebuild cadence and putting a watch on the image, and then leaves the
findings in place for the Xray UI labs that follow.

### Building it

Lab 07 does this through the JFrog CLI so the build is recorded. To build it
directly while developing:

```bash
cd apps/node-dashboard
docker build -t node-dashboard:dev .
docker run --rm -p 3000:3000 node-dashboard:dev
```

The build must complete in under two minutes in a Codespace.

---

## A second application

`apps/` is structured so that a second sample application in another ecosystem,
most likely Python or Maven, can be added alongside as a sibling directory
without any existing lab changing a path. It is out of scope for now.
