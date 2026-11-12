<#
.SYNOPSIS
    Installs, uninstalls, or shows help for the "helper" scheduled task
    (keeps this machine awake while logged in).

.DESCRIPTION
    Registers a per-user Scheduled Task named "helper" that runs
    helper.ps1 at logon, hidden, under the current user account.
    No administrator rights are required.

.PARAMETER Action
    One of: install, uninstall, help
    Defaults to "install" if omitted.

.EXAMPLE
    .\manage.ps1
    .\manage.ps1 install

.EXAMPLE
    .\manage.ps1 uninstall

.EXAMPLE
    .\manage.ps1 help
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "uninstall", "help", "-h", "--help", "/?")]
    [string]$Action = "install"
)

$ErrorActionPreference = "Stop"

function Show-Help {
    @"
manage.ps1 - install/uninstall the 'helper' keep-awake scheduled task

USAGE:
    .\manage.ps1 [install|uninstall|help]

ACTIONS:
    install     (default) Registers the 'helper' Scheduled Task, which
                runs helper.ps1 at logon under the current user account.
                No administrator rights required. Safe to re-run — any
                existing registration is replaced.

    uninstall   Removes the 'helper' Scheduled Task and stops any
                currently running instance.

    help        Shows this message.

EXAMPLES:
    .\manage.ps1
    .\manage.ps1 install
    .\manage.ps1 uninstall

AFTER INSTALL:
    Start immediately without logging off/on:
        Start-ScheduledTask -TaskName "helper"

    Check status:
        Get-ScheduledTask -TaskName "helper" | Select-Object TaskName, State
        Get-ScheduledTaskInfo -TaskName "helper"
"@ | Write-Host
}

function Install-Helper {
    $scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
    $helperPath = Join-Path $scriptDir "helper.ps1"

    if (-not (Test-Path $helperPath)) {
        throw "helper.ps1 not found next to manage.ps1 (expected at $helperPath)"
    }

    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$helperPath`""

    $trigger = New-ScheduledTaskTrigger -AtLogOn

    # Remove a previous registration if one exists, so re-running is safe.
    Get-ScheduledTask -TaskName "helper" -ErrorAction SilentlyContinue |
        Unregister-ScheduledTask -Confirm:$false

    Register-ScheduledTask -TaskName "helper" -Action $action -Trigger $trigger `
        -Description "Keeps system awake while logged in" -RunLevel Limited | Out-Null

    Write-Host "Scheduled task 'helper' registered."
    Write-Host "It will start automatically at your next logon."
    Write-Host ""
    Write-Host "To start it immediately without logging off/on, run:"
    Write-Host "  Start-ScheduledTask -TaskName 'helper'"
}

function Uninstall-Helper {
    Unregister-ScheduledTask -TaskName "helper" -Confirm:$false -ErrorAction SilentlyContinue

    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*helper.ps1*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

    Write-Host "Scheduled task 'helper' removed and any running instance stopped."
}

switch ($Action) {
    "install"   { Install-Helper }
    "uninstall" { Uninstall-Helper }
    default     { Show-Help }
}
