# Project Zomboid Attack Cancel

Standalone AutoHotkey macro for Project Zomboid.

Included:

- `project-zomboid-attack-cancel.ahk`: main GUI macro
- `Run Project Zomboid Attack Cancel.bat`: launches the script with bundled AutoHotkey in the portable package

Main controls:

- `F8`: start/stop
- `F9`: exit

Techniques:

- Technique 1: Melee Cancel
- Technique 1 can also use outline color trigger in windowed mode
- Technique 1 outline colors are `68F072` and `07FF0E`
- Technique 3: Forced Ground Attack
- Technique 3 holds `Alt + Space`
- Technique 4: Standing Knockdown
- Technique 4 fires once per trigger press
- Technique 4 can also double-tap swap slot `1`, `2`, or `3` with fixed `10/50/10` timing
- Technique 5: Dry Fire Loop
- Technique 5 default trigger is `XButton3`, or capture another key/button
- Technique 5 holds `Space` and repeatedly taps `Alt + A`

Notes:

- Settings are saved to `project-zomboid-attack-cancel.ini` next to the script.
- Technique 1 outline trigger is based on PixelSearch and is intended for windowed mode.
- The GitHub release includes a portable zip with `AutoHotkey64.exe` bundled.
- Bundled AutoHotkey binaries remain subject to the AutoHotkey license.
