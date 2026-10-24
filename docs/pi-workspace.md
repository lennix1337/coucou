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

Install the personal `pi-coucou` package through Pi settings (once only), then
run `npm run install:acp-hook` in that checkout and `/reload` in Pi. Hooks forward
metadata only and do not grant permissions. Child and ACP cards keep their
separate identities. App Store builds retain their original workspace default.

The Pi card shows `Pi · provider/model-id` when the extension supplies bounded
`coucou_model` metadata. It follows the session that owns the card, not a sibling
session's model. Missing metadata shows only Pi; the app never guesses Claude Code
or Codex from a terminal. Completion uses the neutral “Session finished” label.

To revert, quit Coucou, restore `scratchpad/Coucou.previous.app` to
`/Applications/Coucou.app`, and choose the desired workspace in Settings.
Do not replace this fork with the upstream Homebrew cask when restoring the Pi setup.
