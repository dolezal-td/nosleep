# nosleep for Windows - keep the machine awake even with the lid closed.
# Unlike keep-awake apps, this changes two static power-plan settings
# (lid close action + sleep timeout) and keeps NO process running.
# Original values are saved and restored exactly on "off".
#
# Usage (elevated PowerShell):
#   .\nosleep.ps1            toggle (on <-> off)
#   .\nosleep.ps1 on         disable sleep
#   .\nosleep.ps1 on 3h      disable sleep, auto-restore after 3 hours
#   .\nosleep.ps1 off        restore previous sleep settings
#   .\nosleep.ps1 status     show current state
#
# Duration accepts 3h, 90m or plain seconds (10800).

#Requires -RunAsAdministrator

param(
  [string]$Command = "",
  [string]$Duration = ""
)

$ErrorActionPreference = "Stop"

$StateDir  = Join-Path $env:LOCALAPPDATA "nosleep"
$StateFile = Join-Path $StateDir "state.json"
$TaskName  = "nosleep-auto-restore"

# Reads current AC/DC values of one power setting, locale-independently:
# hex 0x values in `powercfg /query` output are (for range settings)
# minimum, maximum, increment, and always LAST the two current AC/DC
# indexes - so the last two matches are the values we want.
function Get-PowerValue([string]$SubGroup, [string]$Setting) {
  $hex = @(powercfg /query SCHEME_CURRENT $SubGroup $Setting |
    Select-String -Pattern '0x[0-9A-Fa-f]{8}' |
    ForEach-Object { $_.Matches[0].Value })
  if ($hex.Count -lt 2) { throw "Cannot read power setting $Setting." }
  [pscustomobject]@{ AC = [Convert]::ToInt32($hex[-2], 16); DC = [Convert]::ToInt32($hex[-1], 16) }
}

function Set-PowerValue([string]$SubGroup, [string]$Setting, [int]$AC, [int]$DC) {
  powercfg /setacvalueindex SCHEME_CURRENT $SubGroup $Setting $AC | Out-Null
  powercfg /setdcvalueindex SCHEME_CURRENT $SubGroup $Setting $DC | Out-Null
}

function To-Seconds([string]$d) {
  if     ($d -match '^(\d+)h$') { [int]$Matches[1] * 3600 }
  elseif ($d -match '^(\d+)m$') { [int]$Matches[1] * 60 }
  elseif ($d -match '^\d+$')    { [int]$d }
  else { throw "Invalid duration: $d - use e.g. 3h, 90m or 10800 (seconds)." }
}

function Remove-RestoreTask {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
}

function Enable-NoSleep([string]$For) {
  $seconds = if ($For) { To-Seconds $For } else { 0 }

  # Save original values only once - a second "on" must not overwrite
  # the real originals with already-modified values.
  if (-not (Test-Path $StateFile)) {
    New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
    $lid     = Get-PowerValue SUB_BUTTONS LIDACTION
    $standby = Get-PowerValue SUB_SLEEP STANDBYIDLE
    [pscustomobject]@{
      LidAC = $lid.AC; LidDC = $lid.DC
      StandbyAC = $standby.AC; StandbyDC = $standby.DC
    } | ConvertTo-Json | Set-Content -Path $StateFile
  }

  Set-PowerValue SUB_BUTTONS LIDACTION 0 0    # 0 = do nothing on lid close
  Set-PowerValue SUB_SLEEP STANDBYIDLE 0 0    # 0 = never sleep automatically
  powercfg /setactive SCHEME_CURRENT | Out-Null
  Remove-RestoreTask
  Write-Output "[ON]  Sleep DISABLED - the machine stays awake, even with the lid closed."

  if ($seconds -gt 0) {
    # Failsafe timer via Task Scheduler: survives shell exit and reboot,
    # runs elevated, and simply calls this script with "off".
    $action  = New-ScheduledTaskAction -Execute "powershell.exe" `
      -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" off"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($seconds)
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
      -RunLevel Highest -Force | Out-Null
    $at = (Get-Date).AddSeconds($seconds).ToString("HH:mm")
    Write-Output "[TIMER] Failsafe: sleep settings will be restored at $at (in $For)."
  }
}

function Disable-NoSleep {
  if (Test-Path $StateFile) {
    $s = Get-Content $StateFile -Raw | ConvertFrom-Json
    Set-PowerValue SUB_BUTTONS LIDACTION $s.LidAC $s.LidDC
    Set-PowerValue SUB_SLEEP STANDBYIDLE $s.StandbyAC $s.StandbyDC
    Remove-Item $StateFile -Force
    Write-Output "[OFF] Sleep RESTORED - original settings are back."
  } else {
    # No saved state (e.g. state file deleted) - fall back to common defaults:
    # lid close = sleep, auto-sleep 30 min on AC / 15 min on battery.
    Set-PowerValue SUB_BUTTONS LIDACTION 1 1
    Set-PowerValue SUB_SLEEP STANDBYIDLE 1800 900
    Write-Output "[OFF] Sleep RESTORED - original values unknown, applied common defaults (lid = sleep, 30/15 min)."
  }
  powercfg /setactive SCHEME_CURRENT | Out-Null
  Remove-RestoreTask
}

function Show-Status {
  $lid = Get-PowerValue SUB_BUTTONS LIDACTION
  if ($lid.AC -eq 0 -and $lid.DC -eq 0) {
    Write-Output "[ON]  Sleep is disabled (lid close does nothing)."
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
      $at = ($task.Triggers | Select-Object -First 1).StartBoundary
      Write-Output "[TIMER] Failsafe active: restore scheduled for $([datetime]$at)."
    }
  } else {
    Write-Output "[OFF] Sleep is normal (lid close action: AC=$($lid.AC), DC=$($lid.DC); 0=nothing 1=sleep 2=hibernate 3=shutdown)."
  }
}

switch ($Command) {
  "on"      { Enable-NoSleep $Duration }
  "off"     { Disable-NoSleep }
  "status"  { Show-Status }
  "version" { Write-Output "nosleep 2.0.0 (windows)" }
  ""        { if (Test-Path $StateFile) { Disable-NoSleep } else { Enable-NoSleep $Duration } }
  default   { Write-Output "Unknown command: $Command"; Write-Output "Usage: nosleep [on|off|status] or nosleep on 3h"; exit 1 }
}
