# Screenshot checklist

Every screenshot the workshop needs, so the whole set can be captured in one
sitting rather than discovered one lab at a time.

Screenshots cannot be produced during the build, so each one is marked in the
lab source as an HTML comment:

```markdown
<!-- SCREENSHOT: labs/00-setup/images/github-fork-dialog.png
     Capture: what the image should show. -->
```

**To capture a set:** work down the list, take the shot, save it at the exact
path given, then replace the comment in the lab with a normal image link and
delete the row here.

```markdown
![Alt text describing the image](images/github-fork-dialog.png)
```

**Status:** build phase 3. Labs 00 to 03. Later phases add to it.

---

## Guidance

**Challenge labs need fewer screenshots than guided labs.** A screenshot of the
destination gives away the answer. In a challenge lab, screenshots belong
inside the collapsible solution block, not in the scenario.

**Crop tightly.** A full 1920-wide browser window shrinks to unreadable in a
markdown page. Crop to the dialog or panel being discussed.

**Redact before saving.** No instance URL in the address bar, no real customer
name, no attendee name beyond `user01`, no token or password anywhere. Blur or
crop them out. Anything committed here is in the history for good.

**Use a provisioned attendee account, not an admin account.** The point of most
of these is to show what the attendee sees, and an admin account sees more.

**Consistent theme.** Pick light or dark and stay with it across the whole set.

---

## Already captured

These three were carried over from an earlier manual draft of the workshop and
are in place. They predate this build, so they are on the
[verification checklist](verification-checklist.md) to be re-checked against
the current UI rather than trusted.

| Path | Shows | Used in |
| --- | --- | --- |
| `labs/00-setup/images/artifactory-sign-in-page.png` | The platform sign-in page | Lab 00 step 5 |
| ~~`labs/00-setup/images/jfrog-platform-trial-welcome-screen.png`~~ | **STALE, no longer referenced.** Verified 2026-08-27: a provisioned attendee lands on an All Projects / Get Started Best Practices page, not this screen. Delete this file once `all-projects-landing.png` below is captured. | none |
| `labs/00-setup/images/projects-selection.png` | The project selector dropdown | Lab 00 step 6. Behavior confirmed 2026-08-27: an attendee sees exactly two entries, All Projects and their own. Worth refreshing so the image matches, but not blocking. |

---

## To capture

### Lab 00: setup

- [ ] `labs/00-setup/images/github-fork-dialog.png`
      **Capture:** the GitHub "Create a new fork" dialog, on the workshop
      repository, with a personal account selected as Owner. Crop to the
      dialog.
      **Referenced at:** lab 00 step 2.

- [ ] `labs/00-setup/images/github-create-codespace.png`
      **Capture:** the green Code button expanded on the Codespaces tab,
      showing the "Create codespace on main" button. Take it on a fork, so the
      repository name in the breadcrumb shows a personal account rather than
      the upstream organization.
      **Referenced at:** lab 00 step 3.

- [ ] `labs/00-setup/images/all-projects-landing.png`
      **Capture:** the page a freshly provisioned attendee lands on at first
      sign-in, showing the **All Projects** context and the **Get Started**
      section in the left-hand navigation. Crop to include enough of the top of
      the page to show that the Administration tab is **absent** at this point,
      because that absence is the thing step 6 explains.
      **Referenced at:** lab 00 step 5. Replaces the stale
      `jfrog-platform-trial-welcome-screen.png`.

- [ ] `labs/00-setup/images/project-selected-tabs.png`
      **Capture:** the top of the page immediately **after** switching into a
      project, showing the **Platform** and **Administration** tabs now present.
      Ideally paired with the shot above so the before and after are obvious.
      **Why it is worth two images:** the appearance of those tabs on entering a
      project is the single most confusing thing in lab 00, and the one an
      attendee is most likely to read as a broken account.
      **Referenced at:** lab 00 step 6. Not yet referenced in the text; add the
      image link when captured.

### Lab 01: Artifactory

- [ ] `labs/01-artifactory/images/create-local-repo.png`
      **Capture:** the local repository creation form, npm package type selected,
      repository key filled in, **with the project key prefix visible**. That
      prefix is the point of the shot: step 2 asks the attendee to notice it.
      **Referenced at:** lab 01 step 2.

- [ ] `labs/01-artifactory/images/create-virtual-repo.png`
      **Capture:** the virtual repository form with both member repositories
      added and **local ordered above remote**. The ordering must be legible,
      because the lab explains it as the dependency confusion mitigation.
      **Referenced at:** lab 01 step 4.

- [ ] `labs/01-artifactory/images/remote-cache-tree.png`
      **Capture:** the Artifacts tree with the `-npm-remote-cache` repository
      expanded, showing the freshly fetched `ms` package. Include enough of the
      tree that the cache repository sits alongside the three the attendee
      created, since the surprise is that there are four.
      **Referenced at:** lab 01 step 8.

### Lab 02: Curation

- [ ] `labs/02-curation/images/allow-list-condition.png`
      **Capture:** the Allow List by License condition form with the five
      permissive licenses entered and the attendee-prefixed name visible.
      **Referenced at:** lab 02 step 3.

- [ ] `labs/02-curation/images/policy-scope-specific.png`
      **Capture:** the policy form with scope set to specific repositories and a
      single attendee remote selected, **with the all-repositories option
      visible but unselected**. Showing the wrong answer next to the right one is
      deliberate: recognizing "all repositories" as wrong is the skill.
      **Referenced at:** lab 02 step 4. **Highest-value shot in Part 1.**

- [ ] `labs/02-curation/images/curation-audit-blocked.png`
      **Capture:** the Curation audit view showing the blocked `highcharts`
      request, with the policy name and the failed condition both visible.
      **Referenced at:** lab 02 step 6.

### Lab 03: Xray

- [ ] `labs/03-xray/images/policy-critical-rule.png`
      **Capture:** the security rule form, minimum severity Critical, the
      **non-applicable findings setting enabled**, and the fail-build action.
      The non-applicable setting must be legible: the lab turns on it.
      **Referenced at:** lab 03 step 2.

- [ ] `labs/03-xray/images/watch-with-policy.png`
      **Capture:** the watch form with the attendee's npm repositories as
      targets, **including the `-cache` repository**, and the policy attached.
      **Referenced at:** lab 03 step 3.

- [ ] `labs/03-xray/images/violation-lodash.png`
      **Capture:** the violations view showing the `lodash` Critical violation,
      with the policy name and the **Not Applicable** verdict in the same view if
      possible. Those two facts side by side are the lab's payoff.
      **Referenced at:** lab 03 step 5.

### Later labs

Added in build phases 4 to 6, as the labs are written.

---

## Nice to have, not blocking

Lower priority. The labs work without these, and they would be worth adding if
there is time.

- [ ] `labs/00-setup/images/codespace-ready.png`
      **Capture:** the Codespace with the welcome banner and a clean
      `scripts/verify.sh` run visible in the terminal. Gives attendees a target
      to compare against, which is useful when they are unsure whether their
      environment is correct.
      **Note:** must be recaptured whenever the banner or the health check
      output changes, which is a real maintenance cost. That is why it is here
      rather than in the required list.

- [ ] `labs/00-setup/images/codespaces-ports-panel.png`
      **Capture:** the Ports panel showing port 3000 forwarded as Private.
      Would support the port forwarding section of
      [codespaces-troubleshooting.md](codespaces-troubleshooting.md).
      **Note:** more useful from lab 07 onward, when the application is
      actually running. Consider capturing it then.
