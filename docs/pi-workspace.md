# Personal Pi workspace

This fork adds the stable `agent_pi` workspace pill. It is selectable in Settings,
receives `coucou_agent: pi` events from `pi-coucou`, and is the default workspace
for non-App-Store builds. Existing workspace IDs and permission handling are unchanged.
Opening Pi focuses or launches Ghostty; other cards retain their host routing.
Pi itself remains a terminal program: this does not start another Pi session.

## Install on this Mac

Install Xcode from the App Store, accept its license, complete first launch, and
install XcodeGen (`brew install xcodegen`). Then run:

```sh
./scripts/test-pi-workspace.sh
./scripts/install-pi-workspace.sh
```

The installer uses the supported **Debug** configuration, installs into
`/Applications/Coucou.app`, sets the native `mainPill` preference to `agent_pi`,
and opens Coucou. It refuses to replace an app with a different bundle ID.
The original app is retained at `scratchpad/Coucou.previous.app` for rollback.
Build/package caches and logs stay in ignored `scratchpad/`.

This is a local build, not a signed/notarized release. It has no CloudKit/iPhone
link. Do not disable Gatekeeper or copy someone else's development signing team.
Changing signing identity may require granting macOS permissions again.

In **Settings → Agents → Pi Agent** (the first section), use **Install / Repair…** and select the
already-installed `pi-coucou` package folder. This native action registers the Pi
extension and ACP hook, preserves other settings, and refuses malformed settings
or foreign hooks. It runs no shell commands and changes no permission policy.
Package dependencies must already be installed. Run `/reload` in Pi afterward.
**Refresh status** checks the settings, package files and ACP symlink target;
configuration is not proof the running Pi loaded the extension or that macOS
permissions are granted. Live activity in the notch is the separate runtime check.
Hooks forward metadata only. Child and ACP cards keep separate identities.
App Store builds retain their original workspace default.

The Pi card shows `Pi · provider/model-id` when the extension supplies bounded
`coucou_model` metadata. It follows the session that owns the card, not a sibling
session's model. Missing metadata shows only Pi; the app never guesses Claude Code
or Codex from a terminal. Completion uses “Response finished”: this does not claim
the task was validated.

## Session awareness

- A new `UserPromptSubmit` acknowledges a pending completion from that exact
  session. The finished card returns to the overview and its badge is cleared;
  unrelated sessions cannot acknowledge it. No keystrokes are monitored.
- Returning to the completed response's terminal app dismisses its visible success
  notice and clears its badge. This uses macOS app activation, not keyboard monitoring
  or terminal contents; it acknowledges the app, not a particular tab. Unknown hosts,
  stale completions, failures, interruptions, questions and permissions stay untouched.
- A completion is quiet only when the session received a prompt within two minutes
  and its host is still foreground. Foreground alone is insufficient, and unknown
  terminal tabs remain a limitation. Errors, interruptions, questions and permission
  requests are not silenced by this completion policy.
- Delayed completion cleanup is generation-checked: a new turn, a failure or a
  sibling event invalidates the old timer.
- Native Pi children send `coucou_parent_session`. The parent overview summarizes
  leaf workers and those needing attention; individual cards stay addressable.
  Child completion does not create a second completion popup. Failures still alert.
  A parent finishing never implies a child finished. ACP's current hook does not
  supply an owning Pi session, so those cards remain independent, not falsely grouped.
- Settings → Agents → Pi Agent separates configuration checks from runtime metadata:
  last event/time, owning model (or unknown), session suffix and child state. After
  two minutes of silence it says “No recent signal,” not “stalled.” Receipt proves
  delivery at that time, not continued liveness. Data stays in memory, bounded to
  256 sessions; no prompts, answers or tool arguments are added to this health view.
  Permission state is shown only when an explicit permission event is received;
  Pi/ACP permissions continue to be owned by their harness, not Coucou.

To revert, quit Coucou, restore `scratchpad/Coucou.previous.app` to
`/Applications/Coucou.app`, and choose the desired workspace in Settings.
Do not replace this fork with the upstream Homebrew cask when restoring the Pi setup.
