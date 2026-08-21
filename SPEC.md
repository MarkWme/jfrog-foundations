# JFrog Foundations Workshop: Build Specification

This is the working brief for building the **JFrog Foundations** workshop repository. Read the whole document before writing any code. Where something is ambiguous, ask rather than assume.

---

## 1. Mission

Build a portable, hands-on technical workshop that takes someone with **no prior JFrog experience** and leaves them able to use the JFrog Platform confidently across Artifactory, Curation, Xray, the developer tooling and CI integration.

The workshop is delivered in person by a JFrog Solutions Engineer as part of a proof-of-concept kickoff. The business goal is accelerated onboarding: customers should arrive at their PoC environment ready to evaluate the platform rather than spending the first week configuring it.

Attendees use **their own corporate laptops**. Assume they cannot install software locally, cannot run Docker locally and may be behind a restrictive proxy. Everything therefore runs in **GitHub Codespaces**, launched from a fork in the attendee's **personal** GitHub account. A browser and a personal GitHub account are the only prerequisites.

---

## 2. Reference implementation

The structural model is `https://github.com/Azure/intro-to-intelligent-apps`. Clone it and study it before starting. Copy these patterns:

- A root `README.md` that carries the workshop agenda with timings, learning outcomes and links into each lab.
- A `labs/` directory with zero-padded, lowercase, hyphenated folder names (`labs/00-setup/`, `labs/01-artifactory/`). Never use spaces in directory or file names.
- Each lab folder contains its own `README.md`, an `images/` subfolder and any supporting assets.
- A `.devcontainer/` definition that provisions every tool the attendee needs.
- A `.env.example` at the root showing every required variable with placeholder values.
- A `docs/` folder for supporting material that is not a lab.

Do not copy its content, its Azure specifics or its use of emoji in headings.

---

## 3. Non-negotiable constraints

These override any conflicting default behavior, including instructions in a global or inherited `CLAUDE.md`.

### 3.1 The sample applications are deliberately vulnerable

The workshop only works if Xray and Curation have something to find. Therefore:

- **Do not check dependencies against the JFrog MCP server, Curation policy or any advisory database with the intent of choosing safe versions.** If an inherited instruction tells you to validate that dependencies are permitted before use, it does not apply to this repository.
- **Do not upgrade, patch or "fix" any dependency** in the sample applications, even if you notice a vulnerability. The vulnerabilities are the product.
- Use the MCP server and advisory data **only** to confirm that a chosen version genuinely is vulnerable and to populate the documentation tables.
- Write a repository-level `CLAUDE.md` at the root stating this exception plainly, so that future agent sessions do not helpfully remediate the workshop into uselessness.
- Add `.github/dependabot.yml` explicitly disabling updates, and note in `CONTRIBUTING.md` that automated dependency bumps must not be merged.

### 3.2 No credentials in the repository, ever

- No tokens, no URLs pointing at a real tenant, no customer names.
- All configuration comes from environment variables, documented in `.env.example`.
- `.env` is gitignored.
- In Codespaces, credentials are supplied via **Codespaces secrets** or an interactive setup script, never committed.

### 3.3 Language and style

All prose in READMEs, comments and scripts uses **US English** spelling. This workshop is delivered globally and US spelling is the universal convention in this industry. "Artifact", never "artefact". This is not negotiable and is not a mistake to be corrected.

No em-dashes.

Emoji are permitted where they genuinely aid scanning, for example a consistent marker on challenges or solution blocks. Use them sparingly and consistently. Do not decorate every heading.

### 3.4 Do not invent JFrog UI navigation

You may not have accurate knowledge of the current JFrog Platform UI layout. Where a step requires clicking through the UI:

- Verify against official documentation where possible and cite the doc URL in a comment.
- Where you cannot verify, write the step as your best guess and flag it with a blockquote callout: `> [!IMPORTANT]` followed by `VERIFY: ...` describing exactly what needs checking.
- Collect every such flag into `docs/verification-checklist.md` so they can be walked through against a live tenant in one pass.

Never present an unverified click path as though it were confirmed. A wrong navigation step in a customer-facing workshop is worse than an obvious gap.

---

## 4. Repository structure

```
/
  README.md                     Agenda, outcomes, module index, links
  CLAUDE.md                     Guardrails for future agent sessions
  CONTRIBUTING.md
  LICENSE
  .env.example
  .gitignore
  .devcontainer/
    devcontainer.json
    postCreate.sh
  .github/
    workflows/                  CI used by the labs
    dependabot.yml              Disabled
  labs/
    00-setup/
    01-artifactory/
    02-curation/
    03-xray/
    ...
  apps/
    <sample application 1>/
    <sample application 2>/
  docs/
    instructor-guide.md
    tenant-prerequisites.md
    repo-setup.md               Prebuilds and upstream repository settings
    oidc-setup.md               Production authentication pattern
    glossary.md
    verification-checklist.md
    screenshot-checklist.md
    troubleshooting.md
    timings.md
  scripts/
    setup.sh                    Interactive JFrog connection setup
    verify.sh                   Environment health check
  provisioning/
    README.md                   Instructor prep, run once per delivery
    prep.sh                     Creates attendee projects, users, handout
```

---

## 5. Codespaces and devcontainer

The devcontainer is the single most important asset in the repository. If it does not come up cleanly first time in front of a room of fifteen people, the day is lost.

Requirements:

- Base on a Microsoft devcontainer image with **Node.js 20 LTS**.
- Include the **docker-in-docker** feature. The CI and container scanning labs need to build and inspect images.
- Install the **JFrog CLI** (`jf`) during image build or `postCreate`, pinned to a specific version. Do not rely on `curl | sh` against an unpinned latest.
- Install the **GitHub CLI**.
- Preinstall these VS Code extensions: the JFrog extension (`JFrog.jfrog-vscode-extension`), Docker, ESLint, Prettier, Markdown All in One.
- `postCreate.sh` should: install dependencies for the sample apps, print a short welcome banner naming the first lab, and run `scripts/verify.sh` so tool availability is confirmed before the attendee starts.
- **Codespaces prebuilds are the intended mechanism** for start-up performance. This approach was used successfully on the reference workshop. Structure the devcontainer so it benefits from prebuilds: put expensive work into the image definition and features rather than into `postCreate.sh`, since only the former is baked into a prebuild. Document the repository settings needed to enable prebuilds in `docs/repo-setup.md`, including that prebuilds are configured per branch and per region.
- Target a cold start under five minutes on a 2-core Codespace without a prebuild, and well under two minutes with one. Note in the documentation that a fork may not inherit the upstream prebuild, so measure the attendee's actual path rather than the maintainer's.
- The container must come up successfully with **no JFrog credentials present**. Lab 00 is where credentials get configured.

Also produce `docs/codespaces-troubleshooting.md` covering the predictable failures: corporate proxy blocking `github.dev`, Codespaces quota exhausted on a free account, container rebuild, port forwarding visibility.

---

## 6. Sample applications

Reference the existing demo application at `https://github.com/markwme-org/frogstatus/` for tone and scale. Do not clone it. Build fresh, minimal applications.

### 6.1 Primary application: Node.js

- A small Express web application. Functionality is unimportant. Something mildly interesting is a bonus, something confusing is a liability. A simple status or dashboard page is fine.
- Between five and eight direct npm dependencies with **documented CVEs**, pinned to exact versions with no caret or tilde ranges.
- Candidate packages to investigate and verify, not to accept on trust: `lodash@4.17.15`, `minimist@1.2.0`, `axios@0.21.0`, `jsonwebtoken@8.5.1`, `node-fetch@2.6.0`, `tar@4.4.8`, `moment@2.29.1`, `express@4.16.0`. Confirm each is genuinely vulnerable before including it, and prefer a spread of severities so that Xray results are not uniformly critical.
- Aim for a mix of **direct and transitive** vulnerabilities, so the Xray impact analysis lab has something meaningful to trace.
- Include at least one package likely to trip a **Curation** policy on grounds other than CVE severity, for example license or package age, so Curation is not simply a duplicate of Xray.
- **Remediation is a one-way journey.** The application ships vulnerable, the attendee cleans it up during the workshop, and the whole environment is destroyed afterwards. Do not build toggle scripts, reset mechanisms or dual dependency sets. The attendee fixes things properly, using the tooling, exactly as they would at work.
- The application `README.md` carries a dependency table: package, shipped version, CVE identifiers, severity, direct or transitive, and the version that resolves it. The table documents the starting state and gives the instructor an answer key. It is not a script for a reset.
- This has a **sequencing consequence**: once a lab has the attendee remediate a dependency, every later lab loses that vulnerability as teaching material. Plan the module order so that each vulnerability is used for everything it needs to demonstrate before it is fixed, and deliberately leave some unfixed to feed the Xray and Curation UI labs at the end. Call out any ordering conflicts you find rather than silently working around them.
- The vulnerability set is therefore **layered by design**, across three sources: direct npm dependencies, transitive npm dependencies and the container base image. Attendees fix application dependencies. They do not fix the base image. This is what makes the CI narrative work, and it is described in section 6.2.

### 6.2 Container image

The base image carries the second layer of the vulnerability story and drives one of the most important realisations in the workshop, so treat its design as deliberately as the application's.

**The narrative.** The attendee remediates their application dependencies through the earlier labs. The CI build then goes green: the source code is clean, `jf audit` is satisfied, the build scan passes. Job done, apparently. Then they look at the Xray scan results for the resulting container image and find additional CVEs that exist nowhere in their source code, inherited entirely from the base image the application was packaged into.

Two distinct points are being made, and both matter:

1. Securing the dependencies you chose is not the same as securing the thing you ship. The attendee's code is clean. The artifact they are about to deploy is not.
2. **Scan findings and policy violations are not the same thing.** These base image CVEs need not stop the build. The policies in place were configured to catch particular conditions and they behaved correctly. The findings are still there to be seen. Understanding that the scan surface is broader than the enforcement surface is a genuinely useful distinction, and it sets up the conversation about how a customer decides what to enforce and what to merely observe.

Write the CI lab so the attendee experiences this by looking at the scan results, not by reading a statement about it. A green build followed by a populated findings list is the moment.

Requirements:

- Use an **older base image** carrying known OS-level vulnerabilities. Reference the base image currently used in `https://github.com/markwme-org/frogstatus/` for the kind of thing that works. Pin the tag.
- High or critical severity findings are **not** required. A credible set of findings that are clearly present and clearly attributable to the base image is sufficient. Do not chase severity at the expense of the provenance being obvious.
- The base image findings must be **clearly distinguishable** from anything originating in the application dependencies, so that when the attendee looks at the results the source of each finding is unambiguous. This is the property that actually matters. Verify it.
- Do not have the attendee fix the base image during the workshop. Discuss remediation as a concept, covering base image selection, rebuild cadence and watches on the image, but leave the findings in place for the Xray UI labs that follow.
- Multi-stage build, so the lab can discuss build-time versus runtime layers and why the final image should not carry the toolchain.
- Include a `.dockerignore`.
- The image must build in under two minutes in a Codespace.

### 6.3 Second application

Assume a second sample application in a different ecosystem will be needed later, most likely Python or Maven, to support optional modules for customers whose stack is not Node. Structure `apps/` and the labs so that adding one does not require rewriting existing content. Do not build it yet.

---

## 7. CI integration

Workflows live in `.github/workflows/` and must run in an attendee's **fork** with no changes beyond configuring secrets.

- Use `jfrog/setup-jfrog-cli` for authentication. **The hands-on path uses a static access token**, because on the day the GitHub environment is unpredictable: a customer's GitHub Enterprise instance, a personal account, or something with policy restrictions that make OIDC trust configuration impossible to complete in a classroom. Codespaces will be strongly mandated but cannot be guaranteed.
- **OIDC is documented as the recommended production pattern**, in `docs/oidc-setup.md`, as a full walkthrough covering the JFrog side identity mapping and the GitHub side workflow permissions. Explain why it is preferable and what it removes, namely a long-lived credential sitting in repository secrets. Reference it from the CI lab so the attendee knows it exists and knows where to find it afterwards.
- This split reflects a core goal of the workshop: the attendee leaves ready to implement what they have learned **in their own environment**, not merely able to repeat it in ours. Anywhere the classroom shortcut differs from what you would do in production, say so explicitly and point at the production pattern. Apply this principle beyond OIDC.
- Demonstrate the **JFrog CLI package alias** (`https://docs.jfrog.com/artifactory/docs/jfrog-cli-package-alias`) as the low-friction route to converting an existing pipeline to resolve through Artifactory. This is the headline of the CI lab: minimal change to an existing pipeline, immediate visibility.
- Build the workflow up in stages across the lab rather than presenting one finished file: resolve dependencies through Artifactory, then publish build info, then scan the build, then build and scan the container image, then surface results through the **JFrog Job Summary**. The ordering matters. The build should be passing and apparently finished before the attendee examines the image scan results, so the base image findings arrive as something they discover rather than more of the same. See section 6.2.
- Add **Frogbot** workflows for both pull request scanning and scheduled scanning of the default branch. Document the required secrets and the repository settings that let Frogbot comment on pull requests.
- Every workflow needs `workflow_dispatch` so it can be triggered manually when a demo needs rescuing.
- Workflows must fail with a clear, readable error when secrets are missing, not with an obscure authentication trace.

---

## 8. Module content standard

### 8.1 The teaching model

An attendee who copies a command from a page into a terminal and watches the expected output appear has learned almost nothing. They have demonstrated that they can copy. The workshop must make them think, because thinking is what produces retention and because a PoC will present them with problems no walkthrough anticipated.

The workshop therefore uses **two lab formats**. Which one a lab uses is determined by a single test:

> Does the attendee already have enough knowledge to have a realistic chance of working this out, given documentation?

If no, it is a **guided lab**. If yes, it is a **challenge lab**. You cannot discover an interface you have never seen, and a room full of people fruitlessly hunting through documentation for a concept nobody has introduced is a failed workshop, not a rigorous one.

The practical consequence is an arc across the day. Early labs are mostly guided because everything is new. Later labs are mostly challenge-based because the foundations are in place. By Part 4 the attendee should be working almost entirely from scenarios.

**Additionally, every guided lab ends with a challenge.** The guided portion teaches the mechanic once, then the challenge has the attendee apply that same mechanic to a different case without instructions. This is the single highest-value pattern in the workshop: it converts a demonstration into a capability, and it costs very little time because the attendee already knows the tool.

### 8.2 Challenge design

Challenges are scenario-framed, in the voice of someone the attendee would actually hear from at work. They state a business problem and ask what the attendee would do about it. They do not state the solution in disguised form.

A worked example of the register to aim for:

> Your CISO has raised concerns about the recent wave of malicious packages on npm. They want assurance that no newly published package can be pulled into a build until someone has verified it is safe. How would you implement this?

Note what that does. It never mentions Curation, never names a policy type and never says which condition to configure. It describes an outcome, and locating the mechanism is the work.

Every challenge must contain:

- **The scenario.** Business framing, two or three sentences, no JFrog terminology if it can be avoided.
- **Success criteria.** An explicit, checkable statement of what should be true when they are done. Without this, attendees do not know when to stop, and the instructor cannot tell who has finished.
- **Documentation links.** Two or three pointers to the relevant JFrog documentation pages. The attendee should never be searching blind. Knowing where to look is itself a workshop outcome, since it is what they will do in their own environment afterwards.
- **A collapsible solution**, using `<details><summary>`. Full steps, the same quality as a guided lab. This is a legitimate exit, not an admission of failure, and the lab text should say so. An attendee stuck at fifteen minutes who reads the solution and understands it has still learned more than one who copied commands for fifteen minutes.
- **A timebox**, stated in the text. Challenges are otherwise unbounded and will wreck the schedule.

### 8.3 Lab template

Every lab `README.md` follows this shape. Consistency matters more than flair.

```markdown
# NN - Title

**Format:** Guided | Challenge
**Duration:** approximately N minutes
**Prerequisites:** labs NN, NN

## What you will learn
Three to five bullets, each a concrete capability.

## Why this matters
One short paragraph connecting the exercise to something the attendee
actually cares about at work.

## Concept
Where a mental model is needed before the hands-on work. A Mermaid
diagram belongs here more often than not. Keep it short: enough to
make the following steps make sense, not a lecture.

## Steps          (guided labs)
Numbered. Every command in a fenced block, copy-pasteable, no
placeholder values that have not been defined in lab 00. Expected
output shown after any command whose result is not obvious.

## Scenario       (challenge labs)
The situation, the success criteria, the documentation links, the
timebox, and a collapsible solution.

## Checkpoint
An explicit, verifiable statement of what should now be true. Where
possible a command the attendee can run to confirm it.

## What just happened
A short explanation of the mechanics behind what they just did. This
is where the learning actually lands. In a challenge lab this section
does more work, because attendees will have reached the outcome by
different routes and need the underlying model made explicit.

## Challenge
Applies the lab's mechanic to a new case, without instructions.
Required in guided labs. See section 8.2 for what it must contain.

## Going further
Optional extension for attendees who finish early. Not assessed, not
timed, exists purely to absorb spare capacity in a room moving at
different speeds.

## Troubleshooting
The two or three failures most likely to occur, with fixes.

## Next
Link to the following lab.
```

Note the distinction between the two trailing sections. **Challenge** is required and everyone is expected to attempt it. **Going further** solves classroom pacing, giving faster attendees somewhere to go while the room catches up. Both are real sections that deserve real content. Neither is filler.

### 8.4 Format assignment

Propose a format for each lab in `PLAN.md` and justify it against the test in 8.1. As a starting position:

- `00-setup` is fully guided. There is no learning value in making anyone deduce how to launch a Codespace.
- Part 1 is mostly guided, since every concept is new, with a challenge closing each lab.
- Part 2 is mixed. First contact with each tool is guided, subsequent use is challenge-based.
- Part 3 is mixed, weighted toward challenge. Attendees generally know CI.
- Part 4 is mostly challenge-based. By this point they have the vocabulary, the platform contains their own data, and "find out which of your builds is affected by this CVE" is a better exercise than a click-by-click tour.

Do not treat this as fixed. If a lab resists its assigned format, say so.

### 8.5 Diagrams

Use **Mermaid diagrams** wherever they clarify a relationship, a flow or a piece of architecture. Concepts like the relationship between virtual, local and remote repositories are far better shown than described, and a diagram earns its place in most Concept sections.

Rules:

- Must render on **GitHub**. Test the syntax. Avoid features GitHub's Mermaid version does not support.
- Use `<br/>` for line breaks inside node labels. `\n` does not work.
- Label edges with what is actually happening. For the repository diagram, a virtual repository **aggregates** its local and remote repositories. It does not "resolve from" them, and the distinction matters to comprehension.
- Keep them small. One relationship per diagram. A diagram that needs a legend has failed.
- Diagrams are for concepts and flows, not decoration. Do not add one to a lab that does not need one.

### 8.6 General notes

- **Checkpoints** matter because in a room of fifteen, the instructor needs a fast way to tell who is stuck.
- Keep prose tight. Senior technical attendees disengage from padding.

### Write for a complete newcomer

The first review of this content will be done by someone who has just joined JFrog, working through it cold, specifically to find the assumptions we have made without noticing. Write to survive that review.

- Assume **zero prior JFrog knowledge**. The attendee has never seen the platform.
- Introduce every piece of JFrog terminology on first use with a one-line definition, and maintain `docs/glossary.md` covering the lot: repository types, build info, watch, policy, violation, waiver, project, curation rule and so on.
- Do not assume knowledge of adjacent tooling either. Familiarity with npm and Git is fair. Familiarity with Docker multi-stage builds, GitHub Actions syntax or OIDC is not.
- Where a lab depends on something established earlier, link back to it rather than assuming it was retained.
- Keep a running `docs/assumed-knowledge.md` listing what each lab takes as given. This is the checklist the reviewer works against.
- This matters most in challenge labs. A challenge that assumes knowledge the attendee does not have is not a challenge, it is a dead end.

### Screenshots

You cannot produce screenshots of the JFrog Platform. Where one is needed, insert:

```markdown
<!-- SCREENSHOT: labs/03-xray/images/xray-watch-creation.png
     Capture: the Watch creation dialog with the policy dropdown open,
     showing the workshop policy selected. -->
```

Log every one of these in `docs/screenshot-checklist.md` with its path, its lab and the capture description, so the whole set can be produced in a single sitting.

Challenge labs need **fewer** screenshots than guided labs. A screenshot of the destination gives the answer away. Restrict them to the collapsible solution blocks.

---

## 9. Multi-attendee isolation

Fifteen attendees will share one JFrog tenant. Isolation is handled by **JFrog Projects**, one per attendee.

- Each attendee is assigned a Project. The Project gives them their own workspace and automatically applies a project key prefix to the resources created within it, so repository and build naming collisions are handled by the platform rather than by convention.
- Lab 00 establishes the attendee's project key as an environment variable and confirms access to it. Every subsequent lab works inside that project.
- Teardown is deleting the project, not running a bespoke cleanup script.

**Curation is the exception.** Curation does not support Projects. This needs handling explicitly:

- Curation policy names must carry a manually applied attendee prefix.
- Each policy must be scoped so it applies only to that attendee's own repositories, not tenant-wide. A policy accidentally applied across the tenant will block packages for the entire room, which is a memorable workshop for the wrong reasons.
- The Curation lab must make this constraint visible rather than papering over it. It is a genuine platform characteristic and an attendee will notice the inconsistency.
- Curation policies survive project deletion, but see the teardown note below.

### Teardown

The workshop runs on a **single JFrog trial instance per delivery**, which is destroyed in its entirety afterwards. There is no per-attendee cleanup, no reset script and no requirement for any lab step to be reversible. Attendees can be told this, and it is liberating: they should experiment freely, break things and try the destructive options.

One instance per attendee is not an option. Instances carry a real cost and fifteen of them for one workshop is not viable, which is why Projects are doing the isolation work.

**Assume the trial instance has every required capability already enabled**, including Curation, which is not present in a default trial and is provisioned separately. Do not write verification steps, capability checks or fallback paths for missing features. That provisioning is handled outside this repository.

Because the instance is disposable, nothing in the repository may hardcode an instance URL. This is already covered in section 3.2 and matters more here, since the URL changes for every delivery.

### Instructor provisioning

The repository ships a **prep script** that the instructor runs against a fresh trial instance ahead of the delivery, in a `provisioning/` directory with its own README.

Scope, in order of priority:

- Create the attendee projects, keyed sequentially as `user01`, `user02` and so on, with the count driven by a parameter.
- Create the corresponding attendee users and assign each to their project with an appropriate role.
- Emit a **handout artifact**: a simple table of attendee identifier, project key, username and initial credential, ready to distribute in the room.
- Anything else genuinely required before lab 00 can begin. Identify these as you build the labs and add them, but see the boundary below first.

Use **JFrog CLI or the REST API**, whichever produces the simpler and more readable script. Terraform is acceptable if it turns out materially cleaner, but the deciding factor is how easily an SE who has never seen the script can read it, run it and fix it fifteen minutes before a workshop. Favour a single script with clear output and idempotent behavior over sophistication.

**The provisioning boundary is a design constraint, not an implementation detail.** The workshop exists so that attendees become familiar with the platform by creating things themselves. Every resource the prep script creates is a resource the attendee does not learn to create. Provision only what is impossible or unreasonable for an attendee to do from within their own project: the project itself, their account, their permissions. Repositories, policies, watches, curation rules and builds are all workshop content and must be created by hand during the labs.

If you find yourself wanting to pre-create something to make a lab run more smoothly, that is a signal the lab needs rewriting, not that the prep script needs extending. Raise it rather than absorbing it.

Document in `docs/tenant-prerequisites.md` what the SE must do before the day: obtain the trial instance, run the prep script, and distribute the handout. Keep it short. The provisioning detail belongs in `provisioning/README.md`.

---

## 10. Module plan

This is the current outline. It will change. Build for modularity: each lab self-contained, declaring its prerequisites, so modules can be swapped in or out per customer without breaking links.

**Part 1: Setup and Configuration**
- `00-setup` Fork, Codespace, JFrog connection, project assignment, verification
- `01-artifactory` Local, remote and virtual repositories, and how resolution works
- `02-curation` Rules controlling what is allowed to enter
- `03-xray` Policies and watches

**Part 2: Developer Experience**
- `04-cli` JFrog CLI authentication, `jf audit`, `jf curation-audit`
- `05-ide` The JFrog VS Code extension: SCA, SAST, Contextual Analysis, JFrog Security Research severities
- `06-mcp` (optional) The JFrog MCP Server, validating dependencies against Curation policy before committing them

**Part 3: CI Integration**
- `07-github-actions` Package alias, build info, build scanning, image scanning, Job Summary
- `08-frogbot` Pull request and branch scanning

**Part 4: Exploring the Platform UI**
- `09-artifactory-ui` Builds and artifacts, tracing versions and repositories
- `10-xray-ui` Scan results, impact analysis, SBOM export
- `11-curation-ui` Dashboard, audit logs, waiver approvals

The UI labs come last deliberately. By this point the attendee has generated real builds, real scans and real violations, so the admin views contain their own data rather than an empty demo.

Anticipate later optional modules covering Release Bundles, Distribution and AppTrust. Do not build them, but do not structure anything in a way that makes adding them painful.

---

## 11. How to work

Do not attempt this in one pass.

**Phase 0.** Read this document and the reference repository. Produce `PLAN.md` covering your proposed structure, the sample application design, the devcontainer approach, a **proposed guided or challenge format for every lab with justification**, and any open questions. **Stop and wait for review.**

**Phase 1.** Repository skeleton, devcontainer, `scripts/`, `provisioning/`, root `README.md`, `CLAUDE.md`, lab `00-setup`. This must be independently testable: running the prep script against a trial instance, then a fork and a Codespace launch, should get an attendee to a working, verified environment. Stop for review.

**Phase 2.** The Node sample application and its Dockerfile, with the dependency table populated and verified.

**Phase 3.** Labs 01 to 03.

**Phase 4.** Labs 04 to 06.

**Phase 5.** Labs 07 to 08 and the CI workflows.

**Phase 6.** Labs 09 to 11.

**Phase 7.** Instructor guide, troubleshooting, verification and screenshot checklists, final link audit.

**Phase 8.** The agenda. Only once all content exists and per-lab durations are known should `docs/timings.md` and the agenda section of the root README be written. Do not invent timings earlier in the process. If you need a placeholder before then, mark it clearly as one.

At each phase boundary, summarise what was built, what needs human verification and what you had to guess. One commit per lab, conventional commit messages.

---

## 12. Definition of done

- A fresh fork plus a new Codespace reaches a verified working environment with no manual steps beyond those documented in lab 00.
- Every internal link resolves. Run a link check.
- Every command in every lab has been syntax-checked. Commands that require a live tenant are flagged for verification rather than assumed correct.
- No secrets, no real tenant URLs, no customer identifiers anywhere in the repository or its history.
- `docs/verification-checklist.md`, `docs/screenshot-checklist.md` and `docs/assumed-knowledge.md` are complete and actionable.
- Every JFrog term used is defined on first use and present in the glossary.
- The remediation sequence has been traced end to end: no lab depends on a vulnerability that an earlier lab has already had the attendee fix.
- Every challenge has success criteria, documentation links, a timebox and a working collapsible solution.
- Every Mermaid diagram renders correctly on GitHub.
- All prose uses US English spelling.
- The whole workshop is achievable in a single day, with per-lab timings in `docs/timings.md` that sum to the agenda in the root README.
- The prep script creates only projects, users and permissions. Every other resource the workshop touches is created by an attendee during a lab.

---

## 13. Out of scope

- Slide decks and presentation material.
- Provisioning the JFrog tenant itself.
- The second sample application in a non-Node ecosystem.
- Anything requiring local installation on an attendee device.
