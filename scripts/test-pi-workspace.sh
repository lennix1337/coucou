#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p scratchpad
swiftc NotchBuddy/Sources/CoucouKit/AgentIdentity.swift tests/AgentIdentityTests.swift \
  -o scratchpad/agent-identity-tests
scratchpad/agent-identity-tests
swiftc NotchBuddy/Sources/CoucouKit/PillCatalog.swift tests/PiWorkspaceTests.swift \
  -o scratchpad/pi-workspace-tests
scratchpad/pi-workspace-tests
swiftc -D APPSTORE NotchBuddy/Sources/CoucouKit/PillCatalog.swift tests/PiWorkspaceTests.swift \
  -o scratchpad/pi-workspace-appstore-tests
scratchpad/pi-workspace-appstore-tests
swiftc NotchBuddy/Sources/App/TerminalTarget.swift tests/TerminalTargetTests.swift \
  -o scratchpad/terminal-target-tests
scratchpad/terminal-target-tests
