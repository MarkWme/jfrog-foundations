# Contributing

This repository is the source for the JFrog Foundations workshop, delivered in
person by a JFrog Solutions Engineer at the start of a customer proof of
concept. Attendees fork it and work through the labs in a GitHub Codespace.

Before changing anything, read `SPEC.md` for the build specification and
`PLAN.md` for the agreed structure and the design decisions already settled.

## The rule that matters most

**Never remediate a dependency in `apps/`.**

The sample applications ship with known-vulnerable dependencies on purpose.
Those vulnerabilities are the entire teaching material for the Curation, Xray
and CI labs. An attendee discovers them, traces them and fixes them by hand
during the day, using the platform. That is the workshop.

Concretely:

- Do not upgrade, patch or pin-forward any dependency in `apps/`.
- Do not merge automated dependency update pull requests. Close them.
- `.github/dependabot.yml` disables update checks deliberately. Leave it alone.
- Do not add a dependency scanner to CI that fails the build on findings in
  `apps/`. The workshop's own scans are the point, and they are configured to
  report rather than block where the labs need them to.
- If a security tool opens a pull request against `apps/`, that is the tool
  working correctly and the answer is still no.

`apps/*/README.md` carries the dependency table: shipped version, CVEs,
severity, whether the finding is direct or transitive, the version that
resolves it, and which lab remediates it. It is the instructor's answer key. It
is documentation of the intended starting state, **not** a reset script. There
are deliberately no reset or toggle scripts anywhere in this repository.

If you genuinely need to change the dependency set, change it in
`apps/*/README.md` and in `PLAN.md` section 3 at the same time, because the
remediation sequence across labs depends on which vulnerabilities survive to
which lab. Changing a version in isolation will silently break a later lab.

## Language and style

- **US English spelling.** "Artifact", not "artefact". "License", not
  "licence". This is deliberate and is documented in `SPEC.md` section 3.3.
- No em-dashes.
- Emoji only as a consistent scanning marker, for example on challenge blocks.
  Not on headings.
- Keep prose tight. The audience is senior and disengages from padding.

## Structure

- Directory and file names: lowercase, hyphenated, no spaces.
- **Lab numbers are permanent.** If a lab is retired its number retires with
  it. Never renumber, because every inbound link breaks.
- Cross-lab links target a lab's `README.md`, never a heading anchor inside
  another lab.
- Every lab follows the template in `SPEC.md` section 8.3 and declares its
  prerequisites.
- Mermaid diagrams must render on GitHub. Test them. Use `<br/>` for line
  breaks in node labels.

## Never commit

- Tokens, passwords or access keys of any kind.
- A real tenant URL. Examples use `https://example.jfrog.io`.
- A customer name.
- `.env`, or anything from `provisioning/out/`.

If a credential reaches a commit, it must be rotated, not just reverted. It is
in the history.

## Unverified UI steps

Nobody should present a guessed click path as confirmed. If you write a UI step
you have not verified against a live tenant, flag it inline and log it:

```markdown
> [!IMPORTANT]
> VERIFY: what exactly needs checking.
```

Add the entry to `docs/verification-checklist.md` so the whole set can be
walked through in one pass before a delivery.

## Commits

Conventional commit messages, one logical change each. One commit per lab when
adding lab content.

```
feat(labs): add lab 02, curation policies
fix(devcontainer): pin JFrog CLI to 2.120.0
docs(glossary): define watch and violation
```

## Before opening a pull request

- Every internal link resolves.
- Every command has been syntax-checked. Commands needing a live tenant are
  flagged for verification rather than assumed correct.
- Shell scripts pass `bash -n`, and `shellcheck` if you have it.
- **Anything invoking `jf` is tested against the version the devcontainer
  pins**, not whatever is on your machine. This has already bitten once: `jf
  api` accepts flags after the endpoint path on 2.121.0 and rejects them on
  2.120.0 with `Wrong number of arguments`, so `provisioning/prep.sh` shipped
  broken from a local test that passed. The pinned version is the
  `JF_CLI_VERSION` arg in `.devcontainer/Dockerfile`, and you can fetch that
  exact binary without touching your own install:

  ```bash
  curl -fsSL -o /tmp/jf-pinned \
    "https://releases.jfrog.io/artifactory/jfrog-cli/v2-jf/<VERSION>/jfrog-cli-mac-arm64/jf"
  chmod +x /tmp/jf-pinned && /tmp/jf-pinned --version
  ```

  Swap `jfrog-cli-mac-arm64` for `jfrog-cli-linux-amd64` on Linux. Easier still,
  test in a Codespace, which already has the pinned version.
- New JFrog terminology is defined on first use and present in
  `docs/glossary.md`.
- Anything a lab now assumes is recorded in `docs/assumed-knowledge.md`.
