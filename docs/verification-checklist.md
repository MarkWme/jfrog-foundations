# Verification checklist

Everything in this repository that has not been confirmed against a live JFrog
Platform instance, a live GitHub UI, or a real execution. Sequenced so it can be
walked in one pass, in this order, because later stages depend on earlier ones.

Item IDs are **stable**. Never renumber them, so that "B6 failed" means the same
thing in a week as it does today. Retire an ID rather than reusing it.

**Severity**, and it is the column that matters most:

| Marker | Meaning |
| --- | --- |
| **BLOCKER** | If this fails, content has to be redesigned, not just corrected. Stop and report before continuing. |
| **HIGH** | Attendee-facing. A failure means someone is told to do something impossible. |
| **MEDIUM** | Instructor-facing, or self-diagnosing with a clear error. |

**Status:** build phase 2. Covers the skeleton, the devcontainer, the
provisioning script, lab 00 and the sample application. Phases 3 to 6 add
stages G onward as labs land.

**How to record a result:** tick the box, and where an item says "record", write
the answer inline. Several later decisions depend on these values.

---

## Stage A: rendering only

No tenant, no Codespace. About five minutes, and worth doing first because it is
free and catches the most embarrassing class of error.

- [ ] **A1.** Push the branch and open the repository on github.com.
      *MEDIUM.*

- [ ] **A2. The lab 00 Mermaid diagram renders as a diagram.**
      `labs/00-setup/README.md`, Concept section. **HIGH.**
      Syntax-reviewed but never rendered, because rendering it locally would
      have meant an npm install outside the Artifactory package resolution
      policy.
      **Watch for:** the `<br/>` breaks inside node labels, the apostrophe in
      "Other attendees' projects", and the two subgraph titles.
      **If it fails:** a broken Mermaid block renders as raw text, on the
      attendee's very first page.

- [ ] **A3. Callouts render as callouts, not as blockquotes.**
      `> [!IMPORTANT]` in lab 00, `> [!WARNING]` in
      `apps/node-dashboard/README.md`, `> [!NOTE]` at the end of lab 00.
      *MEDIUM.*

- [ ] **A4. Tables render.** The module index in the root README, and the
      dependency table in `apps/node-dashboard/README.md`, which is wide.
      *MEDIUM.*

- [ ] **A5. Decide the license.** `LICENSE` is currently MIT, chosen to match
      the reference workshop. A JFrog-owned public repository may need
      Apache-2.0. **MEDIUM**, and it is a one-line swap, but it needs a decision
      from someone rather than a guess from me.
      **Record:** MIT or Apache-2.0.

---

## Stage B: Codespace, with no JFrog credentials

This stage proves the devcontainer and the sample application. Deliberately
done before any JFrog connection exists, because the container must come up
cleanly without credentials.

About thirty minutes. **Do B5 and B6 before B7**, since the app cannot run
without dependencies.

- [ ] **B1. Create a Codespace on a fresh personal fork, and time it.**
      **HIGH.** Target is under five minutes cold on 2-core, with no prebuild.
      Measure the **attendee's** path, on a fork, not the maintainer's.
      **Record:** the cold time.

- [ ] **B2. The welcome banner appears**, naming lab 00. *MEDIUM.*

- [ ] **B3. `scripts/verify.sh` reports every tool present.**
      **HIGH.** Expect Node 20 with no version warning, `jf` 2.120.0 with no pin
      drift warning, plus npm, Docker, gh, jq and git.
      **Watch for:** the Docker daemon check. A warning here immediately after
      start is normal and it should clear on a re-run.

- [ ] **B4. `verify.sh` exits zero with no JFrog server configured.**
      **HIGH.** The "JFrog connection" section should read "no server named
      workshop configured yet" as information, not failure.
      ```bash
      bash scripts/verify.sh; echo "exit=$?"
      ```
      **If it fails:** container creation would report a scary warning to every
      attendee before lab 00, which is exactly the first impression to avoid.

- [ ] **B5. Generate the sample application lock file.**
      **BLOCKER.** No `package-lock.json` is committed yet.
      ```bash
      cd apps/node-dashboard
      npm install --before=2020-11-01 --no-audit --no-fund
      ```
      **Why the date:** `2020-11-01` sits just after the newest direct pin,
      `axios@0.21.0` from October 2020. Every direct pin still resolves, and the
      transitive tree freezes period-accurate.
      **Why a Codespace:** a maintainer machine routes npm to Artifactory, which
      would embed the tenant hostname in every `resolved` URL. This repository
      may never contain a real tenant URL.

- [ ] **B6. Confirm the transitive Critical actually landed.**
      **BLOCKER**, and the single most consequential item in this file.
      ```bash
      npm ls minimist mkdirp
      ```
      **Expect:** `mkdirp@0.5.5` and `minimist@1.2.5`.
      **If you see `minimist@1.2.8`:** the cutoff did not apply. `minimist@1.2.8`
      is patched, so lab 07's central exercise, tracing a Critical you cannot
      fix by editing the line that caused it, has no subject. **Stop and tell
      me**: lab 07 gets redesigned around a direct dependency instead.

- [ ] **B7. Run the application and check every route.**
      **BLOCKER.** It has never been executed.
      ```bash
      cd apps/node-dashboard && npm start
      ```
      Then `/`, `/healthz`, `/api/status`, `/api/upstream`, `/api/token`,
      `/api/admin`, `/api/diagnostics`.

- [ ] **B8. The Highcharts chart renders on `/`.**
      **HIGH.** Proves `express.static` is finding
      `node_modules/highcharts/highcharts.js`. If the chart area shows the
      fallback text instead, the static mount path is wrong.

- [ ] **B9. `/api/diagnostics` returns a valid archive.**
      **HIGH**, and the most likely failure in this stage.
      ```bash
      curl -s localhost:3000/api/diagnostics | tar -tzf - | head
      ```
      **Why:** `tar@4.4.8` is old enough that its `fs` usage may warn or fail on
      Node 20. If it breaks, `tar` needs replacing with a different old-and-
      vulnerable carrier for the `minimist` chain, which loops back to B6.

- [ ] **B10. The token round trip works.** *MEDIUM.*
      ```bash
      TOKEN=$(curl -s localhost:3000/api/token | jq -r .token)
      curl -s -H "Authorization: Bearer $TOKEN" localhost:3000/api/admin | jq
      ```

- [ ] **B11. `axios@0.21.0` accepts `validateStatus: null`.** *MEDIUM.*
      `src/app.js`, `probeUpstream`. Hit `/api/status` and check the `upstream`
      object. Because the call is wrapped in try/catch, a wrong option name
      fails silently by always taking the error path rather than reporting a
      status code.

- [ ] **B12. Build the container image, and time it.**
      **HIGH.** Must be under two minutes in a Codespace.
      ```bash
      cd apps/node-dashboard && docker build -t node-dashboard:dev .
      ```
      **Record:** the build time.

- [ ] **B13. Run the image.** **HIGH.**
      ```bash
      docker run --rm -p 3000:3000 node-dashboard:dev
      ```
      Confirm the app serves under Node 16 and that `docker ps` eventually shows
      the healthcheck as healthy.
      **Watch for:** `node_modules` was resolved by the build stage's npm 10 and
      has to run on the runtime stage's Node 16. Every dependency is pure
      JavaScript so this should hold, but it is untested.

- [ ] **B14. Port 3000 forwards.** *MEDIUM.* Confirm it appears in the Ports
      panel as Private and opens in the browser.

- [ ] **B15. Rebuild the container and confirm the lock file survives.**
      **HIGH.** After B5, a rebuild should take the `npm ci` path and leave
      `package-lock.json` untouched.
      **Why:** the fallback path is deliberately `--no-package-lock`, so that an
      install can never silently write a wrong lock file. This confirms the
      guard works in the direction that matters.

---

## Stage C: trial tenant, instructor side

Provisioning. About thirty minutes.

- [ ] **C1. Confirm the required capabilities are enabled** on the delivery
      instance: Artifactory, Xray, JFrog Advanced Security, and **Curation**,
      which is not in a default trial. **HIGH.** Nothing in the repository
      checks for these or degrades without them, deliberately.

- [ ] **C2. Create a platform administrator access token.** *MEDIUM.*

- [ ] **C3. `prep.sh --dry-run` succeeds.** *MEDIUM.*
      ```bash
      cd provisioning
      export JF_ACCESS_TOKEN='<platform admin token>'
      ./prep.sh --url https://<instance> --count 2 --dry-run
      ```
      Confirms the token preflight against `GET /access/api/v1/projects` and
      prints the plan without creating anything.

- [ ] **C4. `prep.sh --count 2` creates projects and users.** **HIGH.**
      Confirms `POST /access/api/v1/projects` and `POST /access/api/v2/users`.

- [ ] **C5. The project role name is correct.**
      **BLOCKER.** `provisioning/prep.sh`, `ROLE`, currently `Project Admin`.
      Taken from the platform UI, because the
      [REST API reference](https://docs.jfrog.com/projects/reference/addorupdateprojectuser)
      documents `roles` as an array of strings without listing the built-in
      names.
      **A 400 on the role assignment step means the name is wrong.** Find the
      correct one under the project's Members tab and re-run with `--role`.
      **Record:** the working role name.
      **Why BLOCKER:** attendees must be able to create repositories, policies
      and watches inside their project. A role without those privileges makes
      lab 01 onward fail with permission errors that look like broken labs.

- [ ] **C6. Re-run `prep.sh` with the same arguments.** **HIGH.**
      Every step should report "already exists" and the script should exit zero.
      Confirm the handout still shows the **original** password for the existing
      users, annotated `existing user`, rather than a new one.

- [ ] **C7. The handout is correct and protected.** *MEDIUM.*
      `provisioning/out/handout.md` and `.csv`, mode `600`, with the instance
      URL, project key, username and password per attendee. Confirm
      `provisioning/out/` is gitignored.

- [ ] **C8. Error paths are readable.** *MEDIUM.* Run once with a deliberately
      bad token and confirm the 401 and 403 messages are clear rather than a
      raw dump.

---

## Stage D: trial tenant, as an attendee

Work lab 00 exactly as `user01`, from the handout. This is the stage that
carries the most design risk. About thirty minutes.

- [ ] **D1. First sign-in behavior.** **HIGH.**
      `labs/00-setup/README.md` step 5 is written for the case where the
      platform forces a password change on first web UI sign-in for an
      API-created user.
      **Record:** forced, or not. If not forced, step 5 simplifies and several
      warnings about the handout password going stale can be deleted.

- [ ] **D2. The welcome page matches.** *MEDIUM.* Compare against
      `labs/00-setup/images/jfrog-platform-trial-welcome-screen.png`, which
      predates this build. Confirm **Getting Started** is where the lab says.

- [ ] **D3. Both the Platform and Administration tabs are visible to a
      non-admin attendee.**
      **BLOCKER**, and the highest-impact item in this file after B6.
      **If Administration is hidden:** labs 01 to 03 need restructuring, because
      they create repositories and policies from that area. **Stop and tell me.**

- [ ] **D4. The project selector.** **HIGH.** Confirm its location and
      behavior, and specifically what a user assigned to exactly one project
      sees in it. Compare against `images/projects-selection.png`.

- [ ] **D5. `scripts/setup.sh` works via username and password.** **HIGH.**
      ```bash
      bash scripts/setup.sh
      ```
      Choose option 1. Confirm it ends with "Connection confirmed."

- [ ] **D6. `jf rt ping` returns OK for a project-scoped user.**
      **BLOCKER.**
      **If it needs a permission attendees do not have**, the lab 00 checkpoint
      fails for the entire room and needs replacing with a different check.

- [ ] **D7. The project access check in `verify.sh` is meaningful.** **HIGH.**
      It calls `GET /api/repositories?project=<key>`. Run it with a **bogus**
      project key too.
      **If both return 200**, the check proves nothing, and a check that always
      passes is worse than no check: it gives false confidence at the exact
      moment an attendee is trying to confirm their setup. Replace it with the
      UI confirmation from lab 00 step 6.

- [ ] **D8. `setup.sh` re-runs cleanly** over an existing configuration.
      *MEDIUM.* It removes and re-adds rather than editing, so this should be
      safe, and attendees will do it after a typo.

- [ ] **D9. `setup.sh` option 2, access token,** configures successfully.
      *MEDIUM.* Not used until lab 07, but the code path exists now.

- [ ] **D10. `.env` contains no credential.** **HIGH.**
      ```bash
      cat .env
      ```
      Only `JF_URL`, `JF_PROJECT`, `JF_SERVER_ID` and the placeholders. This is
      the property that makes displaying `.env` in front of a room safe.

- [ ] **D11. `user01` can create a repository inside their project.** **HIGH.**
      Not a lab 00 step, but lab 01 is unwritable until this is known. Confirm
      the project key prefix is applied automatically.

- [ ] **D12. What permission does creating a Curation policy actually need?**
      **BLOCKER**, and the largest known unknown in the whole design.
      Curation has no project scoping. `PLAN.md` records the decision to grant
      whatever is required, up to platform administrator.
      **Record:** the permission that works, and what else it exposes to the
      attendee.
      **Why it matters:** it determines whether labs 02 and 11 are attendee-led
      at all, and it determines what you tell the room about staying inside
      their own project.

- [ ] **D13. A Curation policy can be scoped to one attendee's own
      repositories.** **BLOCKER.**
      **If a policy cannot be scoped narrowly**, one attendee's policy blocks
      packages for the entire room, and labs 02 and 11 have to become an
      instructor demonstration.

---

## Stage E: the vulnerability set

Needs stage B for the built image and stage D for a working connection. This is
where the teaching material either exists or does not.

- [ ] **E1. `jf audit` on the sample application matches the documented set.**
      **HIGH.** Compare against the dependency table in
      `apps/node-dashboard/README.md`. Exact CVE lists will differ, since new
      advisories land against old versions constantly and the Catalog truncates
      at ten per package. What matters is that the **highest severity per
      package** still matches.
      **Record:** any package whose highest severity has changed.

- [ ] **E2. `minimist` appears as a transitive Critical**, attributed through
      `tar` to `mkdirp`. **BLOCKER.** Confirms B6 from the platform's own point
      of view rather than npm's.

- [ ] **E3. The built image produces base image findings.** **HIGH.**
      Scan `node-dashboard:dev`. High or critical severity is **not** required.

- [ ] **E4. Base image findings are attributable to Debian packages, not npm
      packages.**
      **BLOCKER.** This is the property lab 07's entire payoff rests on: when
      the attendee looks at the results, the source of each finding must be
      unambiguous.
      **If the set is too thin or the provenance is muddy:** fall back to
      non-slim `node:16.20.2-bullseye`, then a `buster` tag.
      **Record:** roughly how many findings, and whether the component type
      makes the origin obvious at a glance.

- [ ] **E5. `highcharts@8.2.0` is blocked by a license-based Curation policy.**
      **BLOCKER.** The Catalog reports its license as
      `LicenseRef-jfrog-highcharts`, a non-OSI reference.
      **If it is not blocked:** it is the only non-CVE finding in the
      application, and without it the Curation labs are a duplicate of the Xray
      labs. A different license-tripping package is needed.

- [ ] **E6. A Critical-only Xray policy leaves `express` and `jsonwebtoken` as
      findings that are not violations.** **HIGH.**
      This is what makes lab 07's "scan surface is wider than enforcement
      surface" point true of the application itself, not only of the base image.

- [ ] **E7. Record the recommended fix versions.** *MEDIUM.*
      Run `jf audit` and note what it recommends per package, for the
      instructor's own reference. The dependency table deliberately does not
      hardcode these, because they go stale between deliveries and would then
      contradict the tool in front of the room.

---

## Stage F: GitHub settings

Needed for phase 5, worth confirming while you are in here.

- [ ] **F1. The Codespaces prebuild settings path.** *MEDIUM.*
      `docs/repo-setup.md` documents `Settings` then `Codespaces` then
      `Set up prebuild`. Confirm against the current GitHub UI.

- [ ] **F2. Whether a fork inherits the upstream prebuild.** **HIGH.**
      The repository assumes it does **not**, which is the safe assumption.
      Configure a prebuild on the upstream default branch, then fork into a
      clean account and create a Codespace.
      **Record:** inherited or not, the warm time, and the date checked.

- [ ] **F3. Actions on a fork.** *MEDIUM.* Confirm an attendee can enable
      Actions on their own fork, since labs 07 and 08 depend on it.

---

## Screenshots

Two to capture and three to re-check. Tracked separately in
[`screenshot-checklist.md`](screenshot-checklist.md), and best done during
stage D while you are signed in as an attendee.
