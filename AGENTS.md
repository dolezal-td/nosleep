# nosleep — instructions for coding agents

You are probably reading this because a user asked you to "install nosleep"
from this repository. This file is the canonical install/uninstall procedure.
Follow it step by step.

## What this tool is

A tiny script that keeps a computer awake even with the laptop lid closed,
by flipping static power settings. It runs **no background process**.

- macOS: `nosleep` (zsh) — toggles the system flag `pmset disablesleep`.
- Windows: `windows/nosleep.ps1` (PowerShell) — sets lid-close action to
  "do nothing" and sleep timeout to "never", saving the original values
  for exact restore.

Both need elevated rights (sudo / administrator) because they change
system power settings. Nothing else is touched.

## Ground rules (do not skip)

1. **Read the script before installing it** and give the user a one-paragraph
   summary of what it does and that it requires sudo/admin.
2. **Change nothing beyond what the script itself changes.** Do not touch
   hibernation, display sleep, or any other power setting.
3. **Never leave the machine with sleep disabled without telling the user.**
   After any test that enables it, run `off` again unless the user wants it on.
4. The macOS sudoers rule (below) is **optional** and needs explicit user
   consent — never add it silently.
5. Warn the user: a closed, awake laptop in a bag gets hot, and on macOS
   `disablesleep` also applies on battery. On macOS the flag even survives
   a reboot — `nosleep off` is the only way back.

## Install — macOS

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/dolezal-td/nosleep/main/nosleep -o ~/.local/bin/nosleep
chmod +x ~/.local/bin/nosleep
```

If `~/.local/bin` is not in the user's `PATH`, add it to their shell rc file
(ask first, show the line): `export PATH="$HOME/.local/bin:$PATH"`

Verify (no sudo needed): `nosleep status` → prints one line about sleep state.

Optional, only if the user wants passwordless remote use (SSH / phone-driven
agent): create a narrow sudoers rule allowing exactly the two commands the
script runs. Use visudo so a syntax error cannot break sudo:

```bash
sudo visudo -f /etc/sudoers.d/pmset
```

and insert (replace USERNAME):

```
USERNAME ALL=(ALL) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0
```

## Install — Windows

```powershell
New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\nosleep" -Force
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dolezal-td/nosleep/main/windows/nosleep.ps1" -OutFile "$env:LOCALAPPDATA\nosleep\nosleep.ps1"
```

Then add a `nosleep` command to the user's PowerShell profile (create the
profile file if it does not exist):

```powershell
function nosleep { & "$env:LOCALAPPDATA\nosleep\nosleep.ps1" @args }
```

Verify from an **elevated** PowerShell: `nosleep status`. The script refuses
to run without elevation (`#Requires -RunAsAdministrator`) — that is expected,
tell the user to use an admin shell for on/off.

## Usage (both platforms)

```
nosleep            toggle
nosleep on         disable sleep
nosleep on 3h      disable sleep, auto-restore after 3h (also 90m / seconds)
nosleep off        restore normal sleep
nosleep status     show current state
```

## Uninstall

macOS:
1. `nosleep off` (never uninstall while sleep is disabled)
2. `rm ~/.local/bin/nosleep`
3. If the sudoers rule was created: `sudo rm /etc/sudoers.d/pmset`

Windows (elevated):
1. `nosleep off`
2. `Unregister-ScheduledTask -TaskName nosleep-auto-restore -Confirm:$false -ErrorAction SilentlyContinue`
3. `Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nosleep"`
4. Remove the `nosleep` function from the PowerShell profile.

## Troubleshooting

- macOS "Sleep is disabled but I never ran it": check `pmset -g | grep SleepDisabled`;
  `nosleep off` resets it. The flag persists across reboots by design.
- macOS failsafe timer: cleared by any `nosleep on`/`off` and by reboot.
  The flag itself is NOT cleared by reboot.
- Windows: settings are per power plan (the active one). If the user switches
  power plans while `on`, run `off` and `on` again.
