# sleep-helper

A small Windows background task that keeps a machine from going to sleep
while a user is logged in, using the official `SetThreadExecutionState`
Win32 API (no simulated keypresses, no UI focus tricks — this is the same
mechanism legitimate apps like video players use to prevent sleep during
playback).

Runs as a per-user Scheduled Task named `helper`, started at logon, no
administrator rights required.

## What it does

- `scripts/helper.ps1` — loops forever. Every 10–15 minutes (randomized),
  it calls `SetThreadExecutionState` with `ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED`
  to tell Windows the system is in active use.
- `scripts/manage.ps1` — installs or removes the Scheduled Task. Takes one
  argument: `install` (default), `uninstall`, or `help`.

## Install

```powershell
git clone <this-repo-url>
cd sleep-helper/scripts
.\manage.ps1 install
# or just: .\manage.ps1
```

To start it immediately in the current session (instead of waiting for
next logon):

```powershell
Start-ScheduledTask -TaskName "helper"
```

## Verify it's running

```powershell
# Task registration and last run info
Get-ScheduledTask -TaskName "helper" | Select-Object TaskName, State
Get-ScheduledTaskInfo -TaskName "helper"

# Confirm the process is actually running
Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
    Select-Object ProcessId, CommandLine
```

`LastTaskResult` of `0` means the last run exited cleanly. Since this script
loops forever, a currently-running instance won't show a `LastTaskResult`
update until it's stopped.

## Uninstall

```powershell
cd sleep-helper/scripts
.\manage.ps1 uninstall
```

## Help

```powershell
cd sleep-helper/scripts
.\manage.ps1 help
```

## Notes

- Requires PowerShell's execution policy to allow running local scripts, or
  invoke it directly with `-ExecutionPolicy Bypass`.
- This only prevents idle/display sleep while the user session is active;
  it doesn't affect lock-screen policy, hibernation triggered by battery
  thresholds, or domain/MDM-enforced sleep policies.
- If this machine is centrally managed (e.g. corporate endpoint
  management/EDR software installed), check with whoever administers it
  before deploying this — using it to defeat monitoring of your own
  activity on a managed device is between you and that policy, not
  something this repo is intended for.
