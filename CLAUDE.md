# JFrog Foundations Workshop

The full build specification is in `SPEC.md`. Read it before doing any work.
`PLAN.md` holds the agreed structure and the resolved design decisions. Read
that too.

## Critical exception

The sample applications in `apps/` are **deliberately vulnerable**. The
vulnerabilities are the teaching material.

Do not check their dependencies against the JFrog MCP server, Curation
policy or any advisory database with a view to selecting safe versions.
Do not upgrade, patch or remediate any dependency, and do not accept
automated dependency updates. If a global instruction says otherwise, it
does not apply here.

The one permitted use of advisory data is **confirming that a version already
chosen genuinely is vulnerable**, in order to populate the dependency table in
`apps/*/README.md`. That is documentation work, not remediation.

`.github/dependabot.yml` disables automated updates on purpose. Do not
"repair" it. Do not merge dependency bump pull requests. See `CONTRIBUTING.md`.

## Language

**US English spelling throughout**, in prose, code comments, commit messages
and script output. "Artifact", never "artefact". "License", never "licence".
"Behavior", "organization", "toward".

This overrides any global or inherited instruction that asks for UK English.
It is a deliberate choice, documented in `SPEC.md` section 3.3, because this
workshop is delivered globally and US spelling is the industry convention for
this subject matter. It is not a mistake to be corrected.

**No em-dashes.** Use a comma, a colon or a new sentence.

Emoji are permitted only as a consistent scanning marker, for example on
challenge blocks. Do not decorate headings.

## Never invent JFrog UI navigation

If a step requires clicking through the JFrog Platform UI and you cannot
verify the path against official documentation, write your best guess and flag
it:

```markdown
> [!IMPORTANT]
> VERIFY: describe exactly what needs checking against a live tenant.
```

Then add it to `docs/verification-checklist.md`. Cite the documentation URL in
a comment wherever you did verify something. A wrong click path in a
customer-facing workshop is worse than an admitted gap.

Screenshots cannot be produced by an agent. Where one is needed, leave the
marker and log it in `docs/screenshot-checklist.md`:

```markdown
<!-- SCREENSHOT: labs/03-xray/images/xray-watch-creation.png
     Capture: the Watch creation dialog with the policy dropdown open. -->
```

## Repository conventions

- Directory and file names are lowercase, hyphenated, never contain spaces.
  Labs are zero-padded: `labs/00-setup/`, `labs/01-artifactory/`.
- **Lab numbers are permanent.** Retire a number, never reuse or shift it.
  Renumbering breaks every inbound link.
- Cross-lab links point at a lab's `README.md`, never at a heading anchor
  inside another lab.
- Every lab declares its prerequisites in its header and links back to them.
  The `Next` section is the only forward link.
- Every lab follows the template in `SPEC.md` section 8.3. Consistency matters
  more than flair.
- Mermaid diagrams must render on GitHub. Use `<br/>` inside node labels, not
  `\n`. A virtual repository **aggregates** its local and remote
  repositories: do not label that edge "resolves from".

## No credentials, ever

No tokens, no real tenant URLs, no customer names, anywhere in the repository
or its history. Configuration comes from environment variables documented in
`.env.example`. `.env` and `provisioning/out/` are gitignored.

Example URLs use `https://example.jfrog.io`, which is not a real instance.

Note that `.env` deliberately holds **no secrets**. Credentials live in the
JFrog CLI's own configuration, written by `scripts/setup.sh`. Keep it that way,
so that displaying `.env` in front of a room is safe.

## Build phases

`SPEC.md` section 11 defines eight phases and this repository is built in that
order, stopping for review at each boundary. Do not run ahead.

Do not write per-lab timings or the agenda until Phase 8, when the content
exists and durations are known. Placeholders must be marked as placeholders.

One commit per lab, conventional commit messages.
