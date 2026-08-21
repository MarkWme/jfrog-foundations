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

**Status:** build phase 1. Lab 00 only. Later phases add to it.

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
| `labs/00-setup/images/jfrog-platform-trial-welcome-screen.png` | The welcome page after signing in | Lab 00 step 5 |
| `labs/00-setup/images/projects-selection.png` | The project selector dropdown | Lab 00 step 6 |

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

### Later labs

Added in build phases 3 to 6, as the labs are written.

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
