# Agent/manual parity

Both the agent route and a human terminal use `scripts/operate.ps1`.

Examples:

```powershell
pwsh -NoProfile -File scripts/operate.ps1 -Operation list -Workspace C:\repo -Path .
pwsh -NoProfile -File scripts/operate.ps1 -Operation read -Workspace C:\repo -Path README.md
pwsh -NoProfile -File scripts/operate.ps1 -Operation process -Workspace C:\repo -Path scripts\check.ps1
pwsh -NoProfile -File scripts/operate.ps1 -Operation process -Workspace C:\repo -Path scripts\check.ps1 -Apply
```

`process` and `write` dry-run unless `-Apply` is explicit. Agent invocation may not bypass this script with an ad hoc command when this capability is selected.
