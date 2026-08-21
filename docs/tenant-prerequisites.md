# Tenant prerequisites

What the Solutions Engineer does before the day. Short by design. The detail
lives in [`../provisioning/README.md`](../provisioning/README.md).

## Before the delivery

1. **Obtain a JFrog trial instance** for this delivery. One instance per
   delivery, shared by the whole room, destroyed afterwards. One instance per
   attendee is not viable.

2. **Confirm the required capabilities are provisioned** on it:

   - Artifactory
   - Xray
   - JFrog Advanced Security (needed by lab 05 for SAST and Contextual
     Analysis)
   - **Curation**, which is not present in a default trial and is provisioned
     separately

   Sort this out well ahead of the day. Nothing in the repository checks for
   these capabilities or degrades gracefully without them, deliberately: the
   labs assume they are present.

3. **Create a platform administrator access token** for the instance.

4. **Run the prep script** to create the attendee projects, users and
   permissions:

   ```bash
   cd provisioning
   export JF_ACCESS_TOKEN='<platform admin token>'
   ./prep.sh --url https://example.jfrog.io --count 15
   ```

   See [`../provisioning/README.md`](../provisioning/README.md) for options,
   the dry run, and what to do when the role assignment fails.

5. **Distribute the handout** from `provisioning/out/`. Each attendee needs the
   instance URL, their project key, their username and their password. One row
   each.

6. **Enable Codespaces prebuilds** on the upstream repository, so the room is
   not waiting on cold container builds. See
   [`repo-setup.md`](repo-setup.md), and note the warning there that a fork
   may not inherit the upstream prebuild.

7. **Walk the verification checklist.** Every unverified UI click path and
   every command needing a live tenant is collected in
   [`verification-checklist.md`](verification-checklist.md). Walk it against
   this instance in one pass. Doing this once, before the day, is the single
   highest-value hour of preparation available.

## Permissions note

Attendees are granted more than their own project. Labs 02 and 11 cover
Curation, and **Curation does not support Projects**, so working with a
Curation policy requires a permission that is not scoped to a project.

The practical effect is that attendees can see, and potentially edit, each
other's Curation policies. The labs handle this by convention: every policy
name carries the attendee's own prefix, and every policy is explicitly scoped
to that attendee's own repositories. Lab 02 makes this a checkpointed step
rather than a passing remark.

Two things follow for you:

- Mention in the room that Curation policies are shared ground and that
  everyone works only on their own prefix.
- An attendee with a broad permission can affect other people. A Curation
  policy applied tenant-wide instead of to one attendee's repositories will
  block packages for the whole room. Lab 02 warns about this prominently, and
  it is worth reinforcing verbally.

## On the day

Attendees need only a browser and a **personal** GitHub account. Nothing is
installed on their laptop. Corporate GitHub accounts often carry policy
restrictions that break forking or Codespaces, so steer people to a personal
account.

## Teardown

Delete the projects, then delete the instance. No per-attendee cleanup, no
reset scripts, nothing in any lab needs to be reversible.

Tell the attendees this at the start. It changes how freely they experiment,
and experimenting freely is how the day is supposed to go.

Note that Curation policies survive project deletion, since they are not owned
by a project. Deleting the instance is what clears them.
