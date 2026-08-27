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

**Stage A is complete.** Verified 2026-08-24.

- [x] **A1.** Push the branch and open the repository on github.com.
      *MEDIUM.* **Result: done.**

- [x] **A2. The lab 00 Mermaid diagram renders as a diagram.**
      `labs/00-setup/README.md`, Concept section. **HIGH.**
      **Result: renders correctly.** The `<br/>` breaks, the apostrophe in
      "Other attendees' projects" and both subgraph titles are all fine. The
      same constructs are therefore safe to reuse in the diagrams for labs 01
      to 03.

- [x] **A3. Callouts render as callouts, not as blockquotes.**
      `> [!IMPORTANT]`, `> [!WARNING]`, `> [!NOTE]`. *MEDIUM.*
      **Result: all three render correctly.** Confirms the house style for
      `VERIFY:` flags.

- [x] **A4. Tables render.** *MEDIUM.*
      **Result: correct**, including the wide dependency table in
      `apps/node-dashboard/README.md`.

- [ ] **A5. Decide the license.** *MEDIUM.* **DEFERRED, not a verification
      item.**
      `LICENSE` is currently MIT, chosen to match the reference workshop.
      **Owner: Mark, pending confirmation from JFrog's open source team.**
      Not blocking any build phase. It is a single file swap whenever the answer
      arrives, and the only other place the license is named is the last line of
      the root README.

---

## Stage B: Codespace, with no JFrog credentials

This stage proves the devcontainer and the sample application. Deliberately
done before any JFrog connection exists, because the container must come up
cleanly without credentials.

About thirty minutes. **Do B5 and B6 before B7**, since the app cannot run
without dependencies.

**Stage B is complete as of 2026-08-27, with one optional item outstanding.**
B1 to B10 and B12 to B15 pass. B11 is inconclusive rather than failed, and is
not worth blocking on. Two bugs were found and fixed along the way, both in
`verify.sh`, and one wrong instruction was found and replaced with a script, in
B5.

- [x] **B1. Create a Codespace on a fresh personal fork, and time it.**
      **HIGH.** Target is under five minutes cold on 2-core, with no prebuild.
      Measure the **attendee's** path, on a fork, not the maintainer's.
      **Record:** the cold time.

      **Attempt 1, 2026-08-27: FAILED, cause found and fixed, needs a retest.**
      The image built correctly and quickly. Every layer succeeded: `jq`, `tree`,
      `jf version 2.120.0`, docker-in-docker and the GitHub CLI all installed,
      and the image exported. Container **creation** then failed:

      ```
      unable to find user vscode: no matching entries in passwd file
      ```

      `devcontainer.json` set `"remoteUser": "vscode"`, but the
      `javascript-node` image inherits its non-root user from the official
      `node` image and contains **`node`**, not `vscode`. Codespaces fell back
      to a recovery container on `devcontainers/base:alpine`, which is why the
      environment looked wrong rather than absent.

      Fixed by setting `"remoteUser": "node"`, confirmed against the image's own
      upstream definition in `devcontainers/images/src/javascript-node`, which
      uses exactly that.

      **Timings from the failed run, which are still useful:** 3 min 10 s total,
      of which the image build was about 114 s, on a cold cache with no
      prebuild. Comfortably inside the five minute target, and the parts that
      dominate (base image pull, features) are exactly what a prebuild removes.

      **Attempt 2, 2026-08-27 after the `remoteUser` fix and the Node 22 bump:
      PASS.** 2 min 40 s, clean start, no recovery container.
      `docker info` succeeded as `node`, which also settles the follow-on
      concern: the docker-in-docker feature put the remote user in the `docker`
      group correctly once that user actually existed.
      **Recorded cold time: 2 min 40 s**, against a five minute target.

- [x] **B2. The welcome banner appears**, naming lab 00. *MEDIUM.*
      **Result: pass.**

- [x] **B3. `scripts/verify.sh` reports every tool present.**
      **HIGH.** Expect **Node 22** with no version warning, `jf` 2.120.0 with no
      pin drift warning, plus npm, Docker, gh, jq and git.
      The devcontainer moved from Node 20 to Node 22 on 2026-08-27, because Node
      20 is end of life and no longer a maintained variant of the base image.
      A Node version warning here means the base image tag and the check in
      `verify.sh` have drifted apart.
      **Watch for:** the Docker daemon check. A warning here immediately after
      start is normal and it should clear on a re-run.

      **Result 2026-08-27: pass.** Node v22.16.0 with no version warning, which
      confirms the Node 22 bump landed. `jf version 2.120.0` with no pin drift.
      npm 10.9.2, Docker 29.7.2, gh 2.98.0, jq 1.6, git 2.49.0, and the Docker
      daemon reported reachable rather than warning, so no re-run was needed.

- [x] **B4. `verify.sh` exits zero with no JFrog server configured.**
      **HIGH.** The "JFrog connection" section should read "no server named
      workshop configured yet" as information, not failure.
      ```bash
      bash scripts/verify.sh; echo "exit=$?"
      ```
      **If it fails:** container creation would report a scary warning to every
      attendee before lab 00, which is exactly the first impression to avoid.

      **Attempt 2, 2026-08-27 after the fix: PASS in this direction.** A fresh
      Codespace reports `no server named "workshop" configured yet` as
      information, the summary reads `All required tools present`, and creation
      completed rather than stalling.
      **The other direction is still untested** and is covered by D5 and D6:
      with a server actually configured, this must report `[ ok ] connection`
      and a real ping result. Bug 1 survived precisely because only the fresh
      direction was ever exercised, so that half is not optional.

      **Attempt 1, 2026-08-27: FAILED. Two bugs found, both fixed, needs a
      retest.** On a fresh Codespace with no credentials, `verify.sh` printed

      ```
        [ ok ] connection       server "workshop" configured
      ```

      which is impossible, and then stopped producing output. `postCreate.sh`
      was still running after ten minutes.

      **Bug 1: the existence check could never fail.** The check tested the exit
      code of `jf config show <id>`. That command prints
      `[Error] Server ID '<id>' does not exist.` and **still exits 0**, verified
      against JFrog CLI 2.120 and 2.121. So every fresh Codespace was reported
      as already connected, and `verify.sh` went on to ping a server that did
      not exist. Fixed by matching the output instead.

      **Bug 2: nothing bounded the network calls.** `jf rt ping` fails in about
      a second when reproduced locally, so the exact reason it stalled in the
      Codespace is **not confirmed**; the most likely candidate is an
      interactive prompt waiting on a terminal that a manual run provides and a
      creation-time run does not. Rather than chase it, both `jf` calls now run
      with a 20 s limit and with stdin detached, and `postCreate.sh` bounds the
      whole health check at 180 s. A health check is the last step of container
      creation, so it must not be able to block a Codespace coming up under any
      circumstances.

      A third bug was caught while testing the fix, and is worth recording
      because it is the same shape as bug 1. The replacement check was written
      as `jf config show | grep -q ...`, which under `set -o pipefail` reports
      failure **even on a match**: `grep -q` exits at the first hit, `jf` is
      killed by SIGPIPE and returns 141, and pipefail surfaces that as the
      pipeline's status. It had simply swapped one always-wrong answer for
      another. Only testing both directions caught it.

      **On the retest, check both directions**, not just the fresh one:
      ```bash
      bash scripts/verify.sh; echo "exit=$?"          # expect: not configured, exit 0
      ```
      then again after lab 00 has configured a server, where it must report
      `[ ok ] connection` and a real ping result. Both are now covered by
      regression tests run against an empty and a populated config directory.

- [x] **B5. Generate the sample application lock file.**
      **BLOCKER.** In a Codespace:
      ```bash
      bash scripts/regenerate-lockfile.sh
      cd apps/node-dashboard && npm ls minimist mkdirp
      ```
      **Attempt 1, 2026-08-27: produced the wrong tree.** The documented command
      was a bare `npm install --before=...`, which had no effect: the
      devcontainer installs dependencies at create time, npm seeds resolution
      from the existing `node_modules`, current versions already satisfied the
      caret ranges, so nothing was re-resolved. The whole transitive tree came
      back modern, `follow-redirects@1.16.0` and `semver@5.7.2` among them.
      Replaced by a script that removes the tree first, refuses a non-public
      registry, and verifies its own output.
      **This is a one-time maintainer task and the result is committed.** It is
      deliberately not part of `setup.sh` and not run per attendee: a
      regenerated tree drifts between deliveries and would silently decay the
      remediation sequence the labs depend on.

      **Attempt 2, 2026-08-27 using the script: PASS.** 81 packages resolved in
      8 seconds, every registry host `registry.npmjs.org`, `mkdirp@0.5.5` and
      `minimist@1.2.5` both confirmed by the script's own checks. Committed.
      Independently re-verified against the committed file: 82 entries, all
      eight direct pins exact, no non-public host, no tenant hostname anywhere
      in the tree.
      Worth noting that npm printed its own deprecation warnings for `tar@4.4.8`
      and `axios@0.21.0` during the install. That is expected and is a preview
      of what the labs teach: npm knows these are bad and says so in passing,
      while the workshop uses `jf audit` to say what is actually wrong and what
      to do about it.

- [x] **B6. Confirm the transitive Critical actually landed.**
      **BLOCKER**, and the single most consequential item in this file.
      ```bash
      npm ls minimist mkdirp
      ```
      **Expect:** `mkdirp@0.5.5` and `minimist@1.2.5`.

      **Attempt 1, 2026-08-27: FAILED.** Got `mkdirp@0.5.6` and
      `minimist@1.2.8`, which is patched, so lab 07 had no subject. Cause was
      B5, not this check.

      **Attempt 2, 2026-08-27 after regenerating with the script: PASS.**
      ```
      tar@4.4.8
      └─┬ mkdirp@0.5.5
        └── minimist@1.2.5
      ```
      **Lab 07's central exercise now has its subject**: a Critical two hops
      down, reachable only by tracing, and not fixable by editing the line that
      caused it. The image was rebuilt afterwards so it carries this tree, which
      E2 depends on.

      **If it fails again after using the script**, `--before` is not doing what
      the design assumes, and this stops being a documentation problem. Stop and
      tell me. The fallback is `overrides` in `package.json` pinning the
      transitive directly, which works but is visible to a curious attendee and
      therefore weakens lab 07's trace exercise, or redesigning lab 07 around a
      direct dependency.

- [x] **B7. Run the application and check every route.**
      **BLOCKER.** It has never been executed.
      ```bash
      cd apps/node-dashboard && npm start
      ```
      Then `/`, `/healthz`, `/api/status`, `/api/upstream`, `/api/token`,
      `/api/admin`, `/api/diagnostics`.
      **Result 2026-08-27: pass.** App starts, UI opens, every endpoint
      responds. `/api/status` returns sensible aggregates and the deterministic
      data behaves: 3 healthy, 3 degraded, stable across reloads.

- [x] **B8. The Highcharts chart renders on `/`.**
      **HIGH.** Proves `express.static` is finding
      `node_modules/highcharts/highcharts.js`. If the chart area shows the
      fallback text instead, the static mount path is wrong.
      **Result 2026-08-27: pass.** An uptime chart renders at the top of the
      page, which is exactly the success condition: the chart drawing at all
      means `express.static` found the library in `node_modules`. The fallback
      would have been a line of plain text saying the chart library did not
      load.

- [x] **B9. `/api/diagnostics` returns a valid archive.**
      **HIGH**, and the most likely failure in this stage.
      ```bash
      curl -s localhost:3000/api/diagnostics | tar -tzf - | head
      ```
      **Why:** `tar@4.4.8` is old enough that its `fs` usage may warn or fail on
      a modern Node. The devcontainer now runs **Node 22**, two majors further
      from `tar` 4's era than the Node 20 this was originally written against,
      so treat this as slightly more likely to fail than before.
      If it breaks, `tar` needs replacing with a different old-and-vulnerable
      carrier for the `minimist` chain, which loops back to B6. **Tell me rather
      than swapping it yourself**: the replacement has to satisfy three things
      at once, namely a real CVE of its own, a transitive dependency that is
      still vulnerable when resolved at the 2020 cutoff, and a plausible use in
      the application.

      **Result 2026-08-27: pass, and this was the one I expected to fail.**
      `tar@4.4.8` works on Node 22. The archive listed
      `package.json`, `src/`, and the four source files, exactly the intended
      contents, and hitting the endpoint from a browser produced a download.
      So `tar` stays as the carrier for the `minimist` chain.

- [x] **B10. The token round trip works.** *MEDIUM.*
      ```bash
      TOKEN="$(curl -fsS 127.0.0.1:3000/api/token | jq -r .token)"
      curl -fsS -H "Authorization: Bearer ${TOKEN}" 127.0.0.1:3000/api/admin | jq
      ```
      **Result 2026-08-27: endpoint works**, confirmed by hand. The original
      one-liner did not, cause unknown. Rewritten to use `127.0.0.1` rather than
      `localhost`, which removes an IPv6-versus-IPv4 ambiguity, and `-fsS` so a
      failure is visible rather than producing an empty token silently.
      **Still to confirm:** that the rewritten command works as pasted.

- [ ] **B11. `axios@0.21.0` accepts `validateStatus: null`.** *MEDIUM.*
      `src/app.js`, `probeUpstream`.
      **Result 2026-08-27: inconclusive, and that is the honest answer.**
      `/api/status` returned
      `"upstream": {"reachable": true, "statusCode": 200, "elapsedMs": 42}`,
      so axios works and nothing throws. But `validateStatus` only changes
      behavior on a **non-2xx** response, and `example.com` returns 200, so this
      run cannot distinguish a correct option name from an ignored one.
      **To actually test it**, point the app at something that returns an error
      status and confirm `reachable: true` with that status rather than
      `reachable: false`:
      ```bash
      UPSTREAM_URL=https://example.com/nonexistent npm start
      curl -fsS 127.0.0.1:3000/api/status | jq .upstream
      ```
      Low stakes either way: the call is wrapped in try/catch, so the worst case
      is a probe that reports unreachable instead of a status code.
      **Status: the only Stage B item still open, and it does not block Stage C
      or anything after it.** Pick it up whenever, or leave it and let lab 07's
      CI run exercise the code path against a real upstream instead.

- [x] **B12. Build the container image, and time it.**
      **HIGH.** Must be under two minutes in a Codespace.
      ```bash
      cd apps/node-dashboard && docker build -t node-dashboard:dev .
      ```
      **Result 2026-08-27: pass, 22 seconds.** Comfortably inside the two minute
      target, with plenty of headroom for the base image to grow.

- [x] **B13. Run the image.** **HIGH.**
      ```bash
      docker run --rm -p 3000:3000 node-dashboard:dev
      ```
      Confirm the app serves under Node 16 and that `docker ps` eventually shows
      the healthcheck as healthy.
      **Watch for:** `node_modules` was resolved by the build stage's npm and
      has to run on the runtime stage's Node 16. Every dependency is pure
      JavaScript so this should hold.

      **Result 2026-08-27: pass.** Container runs, serves the UI, and
      `docker ps` reports `Up (healthy)`, so the `HEALTHCHECK` works and the
      cross-version `node_modules` copy is fine.
      **Still to confirm, the Node 16 runtime itself.** Two ways, either is
      enough:
      ```bash
      docker exec <container> node --version          # expect v16.20.2
      ```
      or read it out of the application, which reports its own runtime:
      ```bash
      TOKEN="$(curl -fsS 127.0.0.1:3000/api/token | jq -r .token)"
      curl -fsS -H "Authorization: Bearer ${TOKEN}" 127.0.0.1:3000/api/admin \
        | jq .configuration.nodeVersion
      ```
      Note that the second one reports **v22** when run against `npm start` in
      the Codespace and must report **v16** against the container. That
      difference is the whole point of the two-stage build, and it is worth
      seeing once.

      **Result 2026-08-27: pass.** `node --version` in the container reports
      **v16.20.2**, exactly the pinned runtime base, against v22.16.0 in the
      Codespace. So the two-stage split works and `node_modules` resolved by
      npm 10 runs correctly on Node 16.

- [x] **B14. Port 3000 forwards.** *MEDIUM.*
      **Result 2026-08-27: pass.** Appears in the Ports panel, app and API both
      reachable in the browser.

- [x] **B15. Rebuild the container and confirm the lock file survives.**
      **HIGH.** Do this **after** the lock file from B5 is committed, otherwise
      there is nothing to preserve and the test is meaningless.

      There is no command to run first. Rebuild from the command palette:
      `Codespaces: Rebuild Container`. Then, once it comes back:
      ```bash
      git status --short apps/node-dashboard/package-lock.json
      cd apps/node-dashboard && npm ls minimist mkdirp
      ```
      **Expect:** `git status` reports **nothing**, meaning the file is
      unmodified, and the tree still shows `mkdirp@0.5.5` and `minimist@1.2.5`.
      **If `git status` shows the file as modified**, the rebuild rewrote it.
      That is the failure this item exists to catch.
      **Why it matters:** the no-lock-file fallback in `updateContent.sh` is
      deliberately `--no-package-lock`, so an install can never silently write a
      wrong lock file. With a lock file present it must take the `npm ci` path
      instead and leave the file alone. B5's failure is what this guard is
      protecting against, so it is worth confirming it works.

      **Result 2026-08-27: pass.** Container rebuilt, reconnected, and
      `git status` printed nothing. The guard holds: a rebuild takes the
      `npm ci` path and leaves the committed lock file untouched.

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

      **Attempt 1, 2026-08-27: FAILED, fixed, needs a retest.** `jf api` rejected
      the invocation with `Wrong number of arguments (5)` and dumped its own help
      text, which the script then reported as "could not reach the instance".
      Two separate defects:

      **Argument order.** `prep.sh` put flags after the endpoint path. On JFrog
      CLI **2.120.0**, the version this workshop pins, that makes the CLI count
      the flags as positional arguments and fail. On **2.121.0** the same
      invocation works. It was written and tested against 2.121.0 on a
      maintainer machine, so it passed there and shipped broken. Flags now come
      before the path, verified against **both** binaries for GET, POST, PUT and
      DELETE, with and without a body.

      **A misleading diagnosis.** The no-status path asserted the host was
      unreachable, which sent the reader towards a network problem when the real
      cause was the command. It now says only that no HTTP status came back,
      names both possibilities, prefers the CLI's own `[Error]` lines, and
      prints the CLI version.

      Also added a specific 404 case, since `/access/api/v1/projects` exists on
      every JFrog instance and a 404 there almost always means the URL is not a
      JFrog instance or has a path on the end, and an `err_body` helper so a
      non-JSON response is truncated instead of printing a screenful of HTML.

      The process lesson is recorded in `CONTRIBUTING.md`: anything invoking
      `jf` gets tested against the pinned version, not the local one.

- [ ] **C4. `prep.sh --count 2` creates projects and users.** **HIGH.**
      Confirms `POST /access/api/v1/projects` and `POST /access/api/v2/users`.

      **2026-08-27: PASS.** Both projects and both users created. The
      membership was queried directly and is correct:
      ```json
      {"members":[{"name":"user01","roles":["Project Admin"]}]}
      ```

      A detour worth recording, because it cost time. The project appeared to
      have no members in the UI, and that was read as the assignment having
      silently failed. It had not: the API shows the membership present and
      correct. The UI was being read wrongly, or members are shown somewhere
      other than where they were looked for. **See D4**, which now has to pin
      down where the platform actually displays project membership, because lab
      00 sends attendees to look at exactly that.

      Ruling out the transport was still worthwhile: `jf api` was pointed at a
      local listener and the raw HTTP confirmed the PUT carries
      `Content-Length: 27` and `{"roles":["Project Admin"]}` on the correct
      path. So the request shape is verified rather than assumed.

      **Also noted: `user01` already existed** on this instance before the first
      real run, so its password was deliberately not reset and the handout reads
      `(unchanged, see previous handout)`. There is therefore no working password
      for `user01`. **Use `user02` for Stage D**, or reset `user01` in the UI
      first.

- [ ] **C5. The project role name is correct.**
      **BLOCKER.** `provisioning/prep.sh`, `ROLE`, currently `Project Admin`.
      Taken from the platform UI, because the
      [REST API reference](https://docs.jfrog.com/projects/reference/addorupdateprojectuser)
      documents `roles` as an array of strings without listing the built-in
      names.
      **Why BLOCKER:** attendees must be able to create repositories, policies
      and watches inside their project. A role without those privileges makes
      lab 01 onward fail with permission errors that look like broken labs.

      **2026-08-27: PASS. The working role name is `Project Admin`**, exactly as
      guessed, listed as `"type": "ADMIN"` with `environments: [DEV, PROD]`.

      Its action list settles several later questions, so it is recorded here
      rather than rediscovered:

      | Lab needs | Actions present |
      | --- | --- |
      | 01, create repositories | `CREATE_LOCAL_REPO`, `CREATE_REMOTE_REPO`, `CREATE_VIRTUAL_REPO`, and the matching `DELETE_*` |
      | 03, policies and watches | `POLICIES_SECURITY`, `WATCHES_SECURITY`, `RULES_SECURITY`, `READ_POLICIES_SECURITY` |
      | 03 and 10, scan results | `TRIGGER_SECURITY`, `ISSUES_SECURITY`, `LICENCES_SECURITY`, `REPORTS_SECURITY` |
      | 07 and 09, builds | `READ_BUILD`, `DEPLOY_BUILD`, `ANNOTATE_BUILD`, `DELETE_BUILD` |
      | project self-service | `MANAGE_MEMBERS`, `MANAGE_RESOURCES` |

      **The significant absence is Curation.** There is no curation action of any
      kind in any of the nine predefined project roles. That is positive
      evidence for what `PLAN.md` only assumed: Curation sits outside the
      project boundary entirely, so no project role can grant it. **D12 cannot
      be solved by picking a different project role**, and the permission has to
      come from outside the project. Worth knowing before spending time on D12.

      **The original pass condition for this item was the wrong test.** It was
      "does the role step avoid a 400", and absence of an error proves nothing
      about whether the assignment did anything. `prep.sh` now validates `ROLE`
      against `GET /access/api/v1/projects/{key}/roles` before use and reads the
      membership back from `GET /access/api/v1/projects/{key}/users` afterwards.
      That change was made on a wrong diagnosis but is worth keeping on its own
      merits. To look by hand:
      ```bash
      jf config add prep-check --url https://<instance> \
        --access-token "$JF_ACCESS_TOKEN" --interactive=false
      jf api --method GET --server-id prep-check /access/api/v1/projects/user01/roles
      jf api --method GET --server-id prep-check /access/api/v1/projects/user01/users
      jf config rm prep-check --quiet
      ```
      Flags go **before** the path, see C3.
      **Record:** the working role name.

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

      **Also pin down where the UI shows project membership.** During C4 a
      project looked empty in the UI while the API reported the member present
      and correctly roled. Whichever view was being read is not the one that
      shows members, and lab 00 step 6 sends attendees to look at project
      membership, so the lab needs the right path. Record where members actually
      appear.

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
