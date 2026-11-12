# helper.ps1
# Keeps the system awake (prevents sleep and screen lock-off) using the
# official Windows API SetThreadExecutionState. No simulated keypresses,
# no UI interaction required, runs silently in the background.
#
# Re-asserts the "stay awake" flag at a random interval between 10 and 15
# minutes, indefinitely.

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Sleep {
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint esFlags);
}
"@

$ES_CONTINUOUS       = [uint32]"0x80000000"
$ES_SYSTEM_REQUIRED  = [uint32]"0x00000001"
$ES_DISPLAY_REQUIRED = [uint32]"0x00000002"

while ($true) {
    [Sleep]::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED)

    $minutes = Get-Random -Minimum 10 -Maximum 16
    Start-Sleep -Seconds ($minutes * 60)
}
