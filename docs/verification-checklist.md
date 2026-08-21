# Verification checklist

Every step in this repository that has **not** been confirmed against a live
JFrog Platform instance or a live GitHub UI, collected so the whole set can be
walked through in one pass.

Do this once against the delivery instance, before the day. It is the highest
value hour of preparation available, because each item here is a place where an
attendee could be told to click something that is not there.

**How to use it:** work down the list, confirm or correct the step in the file
named, and tick the box. When an item is corrected in the source file, remove
the `> [!IMPORTANT] VERIFY:` callout there as well, and delete the row here.

**Status:** build phase 1. Covers the skeleton, the devcontainer, the
provisioning script and lab 00. Later phases add to it.

---

## Provisioning

- [ ] **The project role name.**
      `provisioning/prep.sh`, `ROLE` variable near the top.
      The script assigns `Project Admin`. The
      [REST API reference](https://docs.jfrog.com/projects/reference/addorupdateprojectuser)
      documents the `roles` field as an array of strings without listing the
      built-in role names, so this string is taken from the platform UI rather
      than from documentation.
      **Check:** run `prep.sh --count 1` against the instance. If the role
      assignment step returns 400, find the correct role name under the
      project's Members tab in the UI and re-run with `--role`.
      **Why it matters:** attendees need to create repositories, policies and
      watches inside their project. A role without those privileges makes lab
      01 onward fail with permission errors that look like broken labs.

- [ ] **Attendee permissions for Curation.**
      Cross-cutting, affects labs 02 and 11.
      Curation has no project scoping, so a project role alone will not let an
      attendee create a Curation policy. `PLAN.md` records the decision to
      grant whatever is needed, up to platform administrator.
      **Check:** sign in as `user01` and confirm they can create a Curation
      policy scoped to their own repositories. Confirm what else that
      permission exposes.
      **Why it matters:** this is the largest known unknown in the workshop
      design. It affects labs 02 and 11 and it affects what you say to the room
      about staying inside your own project.

- [ ] **First sign-in behavior for an API-created user.**
      `labs/00-setup/README.md` step 5, and `provisioning/README.md`.
      Lab 00 is written for the case where the platform requires a password
      change on first web UI sign-in.
      **Check:** sign in as a freshly provisioned attendee user and record what
      actually happens. If no password change is forced, simplify step 5 and
      remove the warnings about the handout password going stale.
      **Why it matters:** it is the most likely cause of `scripts/setup.sh`
      failing for an attendee, and lab 00 and the troubleshooting guide both
      lean on it.

---

## Lab 00

- [ ] **The project selector.**
      `labs/00-setup/README.md` step 6.
      Location and behavior of the project selector in the current UI, and
      specifically what an attendee assigned to exactly one project sees in it.
      The existing screenshot `images/projects-selection.png` predates this
      build and should be re-checked rather than trusted.
      **Why it matters:** every lab from 01 onward assumes the attendee is
      working inside their project.

- [ ] **The welcome page and the Getting Started link.**
      `labs/00-setup/README.md` step 5.
      Confirm a newly provisioned non-admin user lands on the welcome page
      shown in `images/jfrog-platform-trial-welcome-screen.png`, and that
      **Getting Started** is where the lab says it is.
      **Why it matters:** it is the attendee's first impression, and being
      wrong here undermines confidence in everything after it.

- [ ] **The Platform and Administration tabs.**
      `labs/00-setup/README.md` step 5.
      Confirm both tabs are visible to a non-admin attendee user. If
      Administration is hidden for them, labs 01 to 03 need rewriting, because
      they create repositories and policies from that area.
      **Why it matters:** high impact. This one changes the structure of Part 1
      if it is wrong.

- [ ] **`jf rt ping` as the connection checkpoint.**
      `labs/00-setup/README.md` checkpoint, `scripts/verify.sh`.
      Confirm it returns `OK` for a project-scoped attendee user with no
      instance-wide read permission.
      **Why it matters:** if `ping` needs a permission attendees do not have,
      the lab 00 checkpoint fails for everyone and a different check is needed.

- [ ] **The project access check in the health script.**
      `scripts/verify.sh`, the `project access` check.
      It calls `GET /api/repositories?project=<key>`. Confirm this returns a
      non-200 for a project key that does not exist. If it returns 200
      regardless, the check proves nothing and should be replaced by the UI
      confirmation in lab 00 step 6.
      **Why it matters:** a check that always passes is worse than no check,
      because it gives false confidence at the exact moment the attendee is
      trying to confirm their setup.

---

## GitHub

- [ ] **The Codespaces prebuild settings path.**
      `docs/repo-setup.md`.
      Documented as `Settings` then `Codespaces` then `Set up prebuild`.
      Confirm the navigation and the field labels in the current GitHub UI.
      **Why it matters:** it is instructor-facing rather than attendee-facing,
      so the cost of being wrong is lower, but it is prep work done under time
      pressure.

- [ ] **Whether a fork inherits the upstream prebuild.**
      `docs/repo-setup.md`.
      The repository assumes it does **not**, which is the safe assumption.
      **Check:** fork into a clean personal account, create a Codespace, and
      time it to the welcome banner. Record the result and the date.
      **Why it matters:** it sets the expectation for how long the room waits
      at the start of the day, and it is the number that determines whether
      lab 00 fits its slot.

- [ ] **Cold and warm Codespace creation times.**
      `docs/repo-setup.md`, targets table.
      Targets are under five minutes cold on 2-core, well under two minutes
      with a prebuild. Measure the attendee's path, on a fork, not the
      maintainer's.
      **Why it matters:** if the cold path is much slower, work needs moving
      out of `postCreate.sh` into the image, and the agenda needs to absorb it.

---

## Rendering

- [ ] **The lab 00 Mermaid diagram renders on GitHub.**
      `labs/00-setup/README.md`, Concept section.
      Syntax-reviewed but not rendered, because rendering it during the build
      would have meant installing a package outside the organization's
      Artifactory package resolution policy. Push the branch and look at the
      rendered README on github.com.
      **Watch for:** the `<br/>` line breaks inside node labels, the apostrophe
      in "Other attendees' projects", and the two subgraph titles.
      **Why it matters:** a Mermaid block that fails to parse renders as raw
      text on GitHub, which looks broken on the attendee's first page.

---

## Commands not yet run against a live instance

Everything below is syntax-checked but has never been executed against a real
JFrog Platform instance. Confirm each returns what the surrounding
documentation claims.

- [ ] `prep.sh` end to end with `--count 2`, then again to confirm the
      "already exists" paths behave and the handout is still correct
- [ ] `prep.sh --dry-run`, including its token preflight
- [ ] `scripts/setup.sh` with username and password
- [ ] `scripts/setup.sh` with an access token, option 2
- [ ] `scripts/setup.sh` re-run over an existing configuration
- [ ] `scripts/verify.sh` with a working connection, confirming every `[ ok ]`
      line it claims
- [ ] `jf rt ping`
- [ ] `jf config show` output, which lab 00 sends attendees to look at in
      Going further
