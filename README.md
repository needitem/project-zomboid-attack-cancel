# Project Zomboid Attack Cancel

Standalone AutoHotkey macro for Project Zomboid.

Included:

- `project-zomboid-attack-cancel.ahk`: main GUI macro
- `Run Project Zomboid Attack Cancel.bat`: launches the script with bundled AutoHotkey in the portable package

Main controls:

- `F8`: start/stop
- `F9`: exit

Techniques:

- Technique 1: 평타캔슬
- Technique 1 can also use outline color trigger in windowed mode
- Technique 1 outline colors are `68F072` and `07FF0E`
- Technique 3: 강제 바닥공격
- Technique 3 repeatedly taps `Alt + Space`
- Technique 4: 서있는 좀비 한번에 눕히는거
- Technique 4 can also tap swap slot `1`, `2`, or `3`
- Technique 5: 빈총에서 격발되는거
- Technique 5 default trigger is `XButton3`, or capture another key/button
- Technique 5 holds `Space` and repeatedly taps `Alt` and `LButton`

Notes:

- Settings are saved to `project-zomboid-attack-cancel.ini` next to the script.
- Technique 1 outline trigger is based on PixelSearch and is intended for windowed mode.
- The GitHub release includes a portable zip with `AutoHotkey64.exe` bundled.
- Bundled AutoHotkey binaries remain subject to the AutoHotkey license.
