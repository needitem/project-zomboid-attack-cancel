#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode("Event")
SetWorkingDir(A_ScriptDir)

configPath := A_ScriptDir "\project-zomboid-attack-cancel.ini"

defaultAppExe := "ProjectZomboid64.exe"
defaultTuneTarget := 1

defaultMeleeEnabled := 1
defaultMeleeMode := "space_only"
defaultMeleeIntervalMs := 110
defaultMeleeTapHoldMs := 18
defaultMeleeAttackLeadMs := 25

defaultChordEnabled := 1
defaultChordTrigger := "XButton1"
defaultChordIntervalMs := 200
defaultChordTapHoldMs := 18

defaultTech5Enabled := 1
defaultTech5IntervalMs := 110
defaultTech5TapHoldMs := 18

toggleKey := "F8"
panicKey := "F9"
fasterKey := "F10"
slowerKey := "F11"
pollMs := 5

enabled := false
lastMeleeCancelAt := 0
meleeSequencePhase := "idle"
meleeSequenceDueAt := 0
lastChordPulseAt := 0
chordPulseActive := false
chordPulseReleaseAt := 0
lastTech5AltAt := 0
tech5AltPulseActive := false
tech5AltPulseReleaseAt := 0
tech5SpaceHeld := false

appExe := IniRead(configPath, "general", "appExe", IniRead(configPath, "macro", "appExe", defaultAppExe))
tuneTarget := ClampInt(ParseWhole(IniRead(configPath, "general", "tuneTarget", defaultTuneTarget), defaultTuneTarget), 1, 3)

meleeEnabled := ParseBool(IniRead(configPath, "melee", "enabled", defaultMeleeEnabled), defaultMeleeEnabled)
meleeMode := IniRead(configPath, "melee", "mode", IniRead(configPath, "macro", "mode", defaultMeleeMode))
meleeIntervalMs := ClampInt(ParseWhole(IniRead(configPath, "melee", "intervalMs", IniRead(configPath, "macro", "cancelIntervalMs", defaultMeleeIntervalMs)), defaultMeleeIntervalMs), 40, 5000)
meleeTapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "melee", "tapHoldMs", IniRead(configPath, "macro", "tapHoldMs", defaultMeleeTapHoldMs)), defaultMeleeTapHoldMs), 5, 200)
meleeAttackLeadMs := ClampInt(ParseWhole(IniRead(configPath, "melee", "attackLeadMs", IniRead(configPath, "macro", "attackLeadMs", defaultMeleeAttackLeadMs)), defaultMeleeAttackLeadMs), 0, 200)

chordEnabled := ParseBool(IniRead(configPath, "chord", "enabled", defaultChordEnabled), defaultChordEnabled)
chordTrigger := IniRead(configPath, "chord", "trigger", defaultChordTrigger)
chordIntervalMs := ClampInt(ParseWhole(IniRead(configPath, "chord", "intervalMs", defaultChordIntervalMs), defaultChordIntervalMs), 20, 5000)
chordTapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "chord", "tapHoldMs", defaultChordTapHoldMs), defaultChordTapHoldMs), 5, 200)

tech5Enabled := ParseBool(IniRead(configPath, "tech5", "enabled", defaultTech5Enabled), defaultTech5Enabled)
tech5IntervalMs := ClampInt(ParseWhole(IniRead(configPath, "tech5", "intervalMs", defaultTech5IntervalMs), defaultTech5IntervalMs), 20, 5000)
tech5TapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "tech5", "tapHoldMs", defaultTech5TapHoldMs), defaultTech5TapHoldMs), 5, 200)

macroGui := Gui("+AlwaysOnTop", "Project Zomboid Attack Cancel")
macroGui.MarginX := 12
macroGui.MarginY := 10
macroGui.SetFont("s9", "Segoe UI")

statusText := macroGui.Add("Text", "xm w440", "")
hintText := macroGui.Add("Text", "xm y+6 w440", "")

macroGui.Add("Text", "xm y+12", "Game exe name")
appExeCtrl := macroGui.Add("Edit", "xm w220", appExe)

macroGui.Add("Text", "x+14 yp", "F10/F11 target")
tuneTargetCtrl := macroGui.Add("DropDownList", "x+6 w170", ["Technique 1", "Technique 3 interval", "Technique 5 interval"])
tuneTargetCtrl.Value := tuneTarget

macroGui.Add("Text", "xm y+16", "Technique 1 - Melee cancel")
meleeEnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 1 (hold RMB + LButton)")
meleeEnabledCtrl.Value := meleeEnabled

macroGui.Add("Text", "xm y+10", "Mode")
meleeModeCtrl := macroGui.Add("DropDownList", "xm w200", ["Space only", "Click + Space"])
meleeModeCtrl.Value := (meleeMode = "click_and_space") ? 2 : 1

macroGui.Add("Text", "xm y+10", "Interval (ms)")
meleeIntervalCtrl := macroGui.Add("Edit", "xm w90 Number", meleeIntervalMs)

macroGui.Add("Text", "x+14 yp", "Tap hold (ms)")
meleeTapHoldCtrl := macroGui.Add("Edit", "x+6 w90 Number", meleeTapHoldMs)

macroGui.Add("Text", "x+14 yp", "Click -> Space delay (ms)")
meleeAttackLeadCtrl := macroGui.Add("Edit", "x+6 w90 Number", meleeAttackLeadMs)

macroGui.Add("Text", "xm y+18", "Technique 3 - Repeating Alt + Space")
chordEnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 3 (hold trigger to repeat Alt + Space)")
chordEnabledCtrl.Value := chordEnabled

macroGui.Add("Text", "xm y+6 w440", "Hold the Technique 3 trigger. The script repeatedly taps Alt + Space.")

macroGui.Add("Text", "xm y+10", "Trigger button")
chordTriggerCtrl := macroGui.Add("DropDownList", "xm w210", ["Thumb 1 (XButton1)", "Thumb 2 (XButton2)"])
chordTriggerCtrl.Value := TriggerButtonIndex(chordTrigger)

macroGui.Add("Text", "xm y+10", "Interval (ms)")
chordIntervalCtrl := macroGui.Add("Edit", "xm w90 Number", chordIntervalMs)

macroGui.Add("Text", "x+14 yp", "Tap hold (ms)")
chordTapHoldCtrl := macroGui.Add("Edit", "x+6 w90 Number", chordTapHoldMs)

macroGui.Add("Text", "xm y+18", "Technique 5 - Hold Space + Tap Alt")
tech5EnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 5 (hold Thumb 2 / XButton2)")
tech5EnabledCtrl.Value := tech5Enabled

macroGui.Add("Text", "xm y+6 w440", "Hold Thumb 2 (XButton2). The script holds Space and taps Alt.")

macroGui.Add("Text", "xm y+10", "Interval (ms)")
tech5IntervalCtrl := macroGui.Add("Edit", "xm w90 Number", tech5IntervalMs)

macroGui.Add("Text", "x+14 yp", "Tap hold (ms)")
tech5TapHoldCtrl := macroGui.Add("Edit", "x+6 w90 Number", tech5TapHoldMs)

toggleButton := macroGui.Add("Button", "xm y+18 w110", "Start (F8)")
saveButton := macroGui.Add("Button", "x+8 w90", "Save")
resetButton := macroGui.Add("Button", "x+8 w110", "Reset Defaults")

helpText := macroGui.Add(
    "Text",
    "xm y+14 w440",
    "F8 start/stop, F10/F11 adjust the selected target, F9 exit. Technique 3 repeats Alt + Space while its trigger is held. Technique 5 holds Space and taps Alt while XButton2 is held."
)

appExeCtrl.OnEvent("Change", OnSettingsChanged)
tuneTargetCtrl.OnEvent("Change", OnSettingsChanged)
meleeEnabledCtrl.OnEvent("Click", OnSettingsChanged)
meleeModeCtrl.OnEvent("Change", OnSettingsChanged)
meleeIntervalCtrl.OnEvent("Change", OnSettingsChanged)
meleeTapHoldCtrl.OnEvent("Change", OnSettingsChanged)
meleeAttackLeadCtrl.OnEvent("Change", OnSettingsChanged)
chordEnabledCtrl.OnEvent("Click", OnSettingsChanged)
chordTriggerCtrl.OnEvent("Change", OnSettingsChanged)
chordIntervalCtrl.OnEvent("Change", OnSettingsChanged)
chordTapHoldCtrl.OnEvent("Change", OnSettingsChanged)
tech5EnabledCtrl.OnEvent("Click", OnSettingsChanged)
tech5IntervalCtrl.OnEvent("Change", OnSettingsChanged)
tech5TapHoldCtrl.OnEvent("Change", OnSettingsChanged)
toggleButton.OnEvent("Click", ToggleMacro)
saveButton.OnEvent("Click", SaveConfig)
resetButton.OnEvent("Click", ResetDefaults)
macroGui.OnEvent("Close", (*) => ExitApp())

Hotkey(toggleKey, ToggleMacro)
Hotkey(panicKey, StopScript)
Hotkey(fasterKey, AdjustInterval.Bind(-5))
Hotkey(slowerKey, AdjustInterval.Bind(5))

ApplyGuiToState(false)
SetTimer(CheckMacros, pollMs)
macroGui.Show("AutoSize")
Notify("Project Zomboid Attack Cancel ready")

OnSettingsChanged(*) {
    ApplyGuiToState(false, false)
}

ParseWhole(value, fallback) {
    value := Trim(String(value))
    if (value = "")
        return fallback

    try parsed := Round(value)
    catch
        return fallback

    return parsed
}

ParseBool(value, fallback := 0) {
    value := Trim(String(value))
    if (value = "")
        return fallback
    return value != "0"
}

ClampInt(value, min, max) {
    if (value < min)
        return min
    if (value > max)
        return max
    return value
}

TriggerButtonIndex(buttonName) {
    return (buttonName = "XButton2") ? 2 : 1
}

TriggerButtonName(index) {
    return (index = 2) ? "XButton2" : "XButton1"
}

ApplyGuiToState(showNotice := true, syncControls := true) {
    global appExe
    global appExeCtrl
    global chordEnabled
    global chordEnabledCtrl
    global chordIntervalCtrl
    global chordIntervalMs
    global chordTapHoldCtrl
    global chordTapHoldMs
    global chordTrigger
    global chordTriggerCtrl
    global meleeAttackLeadCtrl
    global meleeAttackLeadMs
    global meleeEnabled
    global meleeEnabledCtrl
    global meleeIntervalCtrl
    global meleeIntervalMs
    global meleeMode
    global meleeModeCtrl
    global meleeTapHoldCtrl
    global meleeTapHoldMs
    global tech5Enabled
    global tech5EnabledCtrl
    global tech5IntervalCtrl
    global tech5IntervalMs
    global tech5TapHoldCtrl
    global tech5TapHoldMs
    global tuneTarget
    global tuneTargetCtrl

    appExe := Trim(appExeCtrl.Value)
    if (appExe = "") {
        appExe := defaultAppExe
        if syncControls
            appExeCtrl.Value := appExe
    }

    tuneTarget := ClampInt(tuneTargetCtrl.Value, 1, 3)

    meleeEnabled := meleeEnabledCtrl.Value
    meleeMode := (meleeModeCtrl.Value = 2) ? "click_and_space" : "space_only"
    meleeIntervalMs := ClampInt(ParseWhole(meleeIntervalCtrl.Value, defaultMeleeIntervalMs), 40, 5000)
    meleeTapHoldMs := ClampInt(ParseWhole(meleeTapHoldCtrl.Value, defaultMeleeTapHoldMs), 5, 200)
    meleeAttackLeadMs := ClampInt(ParseWhole(meleeAttackLeadCtrl.Value, defaultMeleeAttackLeadMs), 0, 200)

    chordEnabled := chordEnabledCtrl.Value
    chordTrigger := TriggerButtonName(chordTriggerCtrl.Value)
    chordIntervalMs := ClampInt(ParseWhole(chordIntervalCtrl.Value, defaultChordIntervalMs), 20, 5000)
    chordTapHoldMs := ClampInt(ParseWhole(chordTapHoldCtrl.Value, defaultChordTapHoldMs), 5, 200)

    tech5Enabled := tech5EnabledCtrl.Value
    tech5IntervalMs := ClampInt(ParseWhole(tech5IntervalCtrl.Value, defaultTech5IntervalMs), 20, 5000)
    tech5TapHoldMs := ClampInt(ParseWhole(tech5TapHoldCtrl.Value, defaultTech5TapHoldMs), 5, 200)

    if syncControls {
        meleeIntervalCtrl.Value := meleeIntervalMs
        meleeTapHoldCtrl.Value := meleeTapHoldMs
        meleeAttackLeadCtrl.Value := meleeAttackLeadMs
        chordIntervalCtrl.Value := chordIntervalMs
        chordTapHoldCtrl.Value := chordTapHoldMs
        tech5IntervalCtrl.Value := tech5IntervalMs
        tech5TapHoldCtrl.Value := tech5TapHoldMs
    }
    meleeAttackLeadCtrl.Enabled := (meleeMode = "click_and_space")

    UpdateGuiState()

    if showNotice
        Notify("Settings applied")
}

UpdateGuiState() {
    global chordEnabled
    global chordIntervalMs
    global chordTapHoldMs
    global chordTrigger
    global enabled
    global hintText
    global meleeEnabled
    global meleeIntervalMs
    global meleeMode
    global statusText
    global tech5Enabled
    global tech5IntervalMs
    global toggleButton
    global tuneTarget

    statusText.Text := "Status: " (enabled ? "ON" : "OFF")
        . " | T1: " (meleeEnabled ? "ON" : "OFF") " " meleeIntervalMs " ms " ModeLabel(meleeMode)
        . " | T3: " (chordEnabled ? "ON" : "OFF") " " chordTrigger
        . " => " chordIntervalMs " ms"
        . " | T5: " (tech5Enabled ? "ON" : "OFF") " XButton2 => " tech5IntervalMs " ms"

    hintText.Text := "Hotkey target: " TuneTargetLabel(tuneTarget)
        . " | T3 interval = " chordIntervalMs " ms | T3 hold = " chordTapHoldMs " ms | T5 interval = " tech5IntervalMs " ms"

    toggleButton.Text := enabled ? "Stop (F8)" : "Start (F8)"
}

ModeLabel(value) {
    return (value = "click_and_space") ? "Click + Space" : "Space only"
}

TuneTargetLabel(value) {
    switch value {
        case 2:
            return "Technique 3 interval"
        case 3:
            return "Technique 5 interval"
        default:
            return "Technique 1"
    }
}

Notify(message) {
    ToolTip(message)
    SetTimer(HideToolTip, -900)
}

HideToolTip() {
    ToolTip()
}

StartTechnique3Pulse(holdMs) {
    global chordPulseActive
    global chordPulseReleaseAt

    SendEvent("{Blind}{LAlt down}")
    SendEvent("{Blind}{Space down}")
    chordPulseActive := true
    chordPulseReleaseAt := A_TickCount + holdMs
}

StopTechnique3Pulse() {
    global chordPulseActive
    global chordPulseReleaseAt

    if !chordPulseActive {
        chordPulseReleaseAt := 0
        return
    }

    SendEvent("{Blind}{Space up}")
    SendEvent("{Blind}{LAlt up}")
    chordPulseActive := false
    chordPulseReleaseAt := 0
}

ResetTechnique3Pulse() {
    global lastChordPulseAt

    StopTechnique3Pulse()
    lastChordPulseAt := 0
}

StartTechnique5AltPulse(holdMs) {
    global tech5AltPulseActive
    global tech5AltPulseReleaseAt

    SendEvent("{Blind}{LAlt down}")
    tech5AltPulseActive := true
    tech5AltPulseReleaseAt := A_TickCount + holdMs
}

StopTechnique5AltPulse() {
    global tech5AltPulseActive
    global tech5AltPulseReleaseAt

    if !tech5AltPulseActive {
        tech5AltPulseReleaseAt := 0
        return
    }

    SendEvent("{Blind}{LAlt up}")
    tech5AltPulseActive := false
    tech5AltPulseReleaseAt := 0
}

HoldTechnique5Space() {
    global tech5SpaceHeld

    if tech5SpaceHeld
        return

    SendEvent("{Blind}{Space down}")
    tech5SpaceHeld := true
}

ReleaseTechnique5Space() {
    global tech5SpaceHeld

    if !tech5SpaceHeld
        return

    SendEvent("{Blind}{Space up}")
    tech5SpaceHeld := false
}

ResetTechnique5() {
    global lastTech5AltAt

    StopTechnique5AltPulse()
    ReleaseTechnique5Space()
    lastTech5AltAt := 0
}

AltDown() {
    return GetKeyState("LAlt", "P") || GetKeyState("RAlt", "P")
}

ResetMeleeSequence() {
    global meleeSequenceDueAt
    global meleeSequencePhase

    switch meleeSequencePhase {
        case "click_down":
            SendEvent("{LButton up}")
        case "space_down":
            SendEvent("{Space up}")
    }

    meleeSequencePhase := "idle"
    meleeSequenceDueAt := 0
}

MeleeCancelHeld() {
    global appExe
    global enabled
    global meleeEnabled

    if !enabled || !meleeEnabled
        return false

    if !WinActive("ahk_exe " appExe)
        return false

    if AltDown()
        return false

    return GetKeyState("RButton", "P") && GetKeyState("LButton", "P")
}

Technique3Held() {
    global appExe
    global chordEnabled
    global chordTrigger
    global enabled

    if !enabled || !chordEnabled || !WinActive("ahk_exe " appExe)
        return false

    if !GetKeyState(chordTrigger, "P")
        return false

    return true
}

Technique5Held() {
    global appExe
    global enabled
    global tech5Enabled

    if !enabled || !tech5Enabled || !WinActive("ahk_exe " appExe)
        return false

    return GetKeyState("XButton2", "P")
}

CheckMacros() {
    CheckTechnique3()
    CheckTechnique5()
    CheckMeleeCancel()
}

CheckTechnique3() {
    global chordIntervalMs
    global chordPulseActive
    global chordPulseReleaseAt
    global chordTapHoldMs
    global lastChordPulseAt

    if !Technique3Held() {
        ResetTechnique3Pulse()
        return
    }

    if chordPulseActive {
        if (A_TickCount >= chordPulseReleaseAt)
            StopTechnique3Pulse()
        return
    }

    if (A_TickCount - lastChordPulseAt < chordIntervalMs)
        return

    StartTechnique3Pulse(chordTapHoldMs)
    lastChordPulseAt := A_TickCount
}

CheckTechnique5() {
    global lastTech5AltAt
    global tech5AltPulseActive
    global tech5AltPulseReleaseAt
    global tech5IntervalMs
    global tech5TapHoldMs

    if !Technique5Held() {
        ResetTechnique5()
        return
    }

    HoldTechnique5Space()

    if tech5AltPulseActive {
        if (A_TickCount >= tech5AltPulseReleaseAt)
            StopTechnique5AltPulse()
        return
    }

    if (A_TickCount - lastTech5AltAt < tech5IntervalMs)
        return

    StartTechnique5AltPulse(tech5TapHoldMs)
    lastTech5AltAt := A_TickCount
}

CheckMeleeCancel() {
    global lastMeleeCancelAt
    global meleeAttackLeadMs
    global meleeIntervalMs
    global meleeMode
    global meleeSequenceDueAt
    global meleeSequencePhase
    global meleeTapHoldMs

    if !MeleeCancelHeld() {
        ResetMeleeSequence()
        return
    }

    if (meleeSequencePhase = "click_down") {
        if (A_TickCount < meleeSequenceDueAt)
            return

        SendEvent("{LButton up}")
        meleeSequencePhase := "wait_space"
        meleeSequenceDueAt := A_TickCount + meleeAttackLeadMs
        return
    }

    if (meleeSequencePhase = "wait_space") {
        if (A_TickCount < meleeSequenceDueAt)
            return

        SendEvent("{Space down}")
        meleeSequencePhase := "space_down"
        meleeSequenceDueAt := A_TickCount + meleeTapHoldMs
        return
    }

    if (meleeSequencePhase = "space_down") {
        if (A_TickCount < meleeSequenceDueAt)
            return

        SendEvent("{Space up}")
        meleeSequencePhase := "idle"
        meleeSequenceDueAt := 0
        return
    }

    if (A_TickCount - lastMeleeCancelAt < meleeIntervalMs)
        return

    lastMeleeCancelAt := A_TickCount

    if (meleeMode = "space_only") {
        SendEvent("{Space down}")
        meleeSequencePhase := "space_down"
        meleeSequenceDueAt := A_TickCount + meleeTapHoldMs
        return
    }

    SendEvent("{LButton down}")
    meleeSequencePhase := "click_down"
    meleeSequenceDueAt := A_TickCount + meleeTapHoldMs
}

ToggleMacro(*) {
    global enabled
    global lastMeleeCancelAt

    ApplyGuiToState(false)
    enabled := !enabled
    lastMeleeCancelAt := 0
    ResetMeleeSequence()
    ResetTechnique3Pulse()
    ResetTechnique5()
    UpdateGuiState()
    Notify("Attack cancel: " (enabled ? "ON" : "OFF"))
}

AdjustInterval(delta, *) {
    global chordIntervalCtrl
    global chordIntervalMs
    global meleeIntervalCtrl
    global meleeIntervalMs
    global tech5IntervalCtrl
    global tech5IntervalMs
    global tuneTarget

    ApplyGuiToState(false)

    if (tuneTarget = 2) {
        chordIntervalMs := ClampInt(chordIntervalMs + delta, 20, 5000)
        chordIntervalCtrl.Value := chordIntervalMs
        Notify("Technique 3 interval = " chordIntervalMs " ms")
    } else if (tuneTarget = 3) {
        tech5IntervalMs := ClampInt(tech5IntervalMs + delta, 20, 5000)
        tech5IntervalCtrl.Value := tech5IntervalMs
        Notify("Technique 5 interval = " tech5IntervalMs " ms")
    } else {
        meleeIntervalMs := ClampInt(meleeIntervalMs + delta, 40, 5000)
        meleeIntervalCtrl.Value := meleeIntervalMs
        Notify("Technique 1 interval = " meleeIntervalMs)
    }

    UpdateGuiState()
}

SaveConfig(*) {
    global appExe
    global chordEnabled
    global chordIntervalMs
    global chordTapHoldMs
    global chordTrigger
    global meleeAttackLeadMs
    global meleeEnabled
    global meleeIntervalMs
    global meleeMode
    global meleeTapHoldMs
    global tech5Enabled
    global tech5IntervalMs
    global tech5TapHoldMs
    global tuneTarget

    ApplyGuiToState(false)

    IniWrite(appExe, configPath, "general", "appExe")
    IniWrite(tuneTarget, configPath, "general", "tuneTarget")

    IniWrite(meleeEnabled, configPath, "melee", "enabled")
    IniWrite(meleeMode, configPath, "melee", "mode")
    IniWrite(meleeIntervalMs, configPath, "melee", "intervalMs")
    IniWrite(meleeTapHoldMs, configPath, "melee", "tapHoldMs")
    IniWrite(meleeAttackLeadMs, configPath, "melee", "attackLeadMs")

    IniWrite(chordEnabled, configPath, "chord", "enabled")
    IniWrite(chordTrigger, configPath, "chord", "trigger")
    IniWrite(chordIntervalMs, configPath, "chord", "intervalMs")
    IniWrite(chordTapHoldMs, configPath, "chord", "tapHoldMs")

    IniWrite(tech5Enabled, configPath, "tech5", "enabled")
    IniWrite(tech5IntervalMs, configPath, "tech5", "intervalMs")
    IniWrite(tech5TapHoldMs, configPath, "tech5", "tapHoldMs")

    Notify("Saved to project-zomboid-attack-cancel.ini")
}

ResetDefaults(*) {
    global appExeCtrl
    global chordEnabledCtrl
    global chordIntervalCtrl
    global chordTapHoldCtrl
    global chordTriggerCtrl
    global meleeAttackLeadCtrl
    global meleeEnabledCtrl
    global meleeIntervalCtrl
    global meleeModeCtrl
    global meleeTapHoldCtrl
    global tech5EnabledCtrl
    global tech5IntervalCtrl
    global tech5TapHoldCtrl
    global tuneTargetCtrl

    appExeCtrl.Value := defaultAppExe
    tuneTargetCtrl.Value := defaultTuneTarget

    meleeEnabledCtrl.Value := defaultMeleeEnabled
    meleeModeCtrl.Value := 1
    meleeIntervalCtrl.Value := defaultMeleeIntervalMs
    meleeTapHoldCtrl.Value := defaultMeleeTapHoldMs
    meleeAttackLeadCtrl.Value := defaultMeleeAttackLeadMs

    chordEnabledCtrl.Value := defaultChordEnabled
    chordTriggerCtrl.Value := TriggerButtonIndex(defaultChordTrigger)
    chordIntervalCtrl.Value := defaultChordIntervalMs
    chordTapHoldCtrl.Value := defaultChordTapHoldMs

    tech5EnabledCtrl.Value := defaultTech5Enabled
    tech5IntervalCtrl.Value := defaultTech5IntervalMs
    tech5TapHoldCtrl.Value := defaultTech5TapHoldMs

    ApplyGuiToState(false)
    Notify("Defaults restored")
}

StopScript(*) {
    ResetMeleeSequence()
    ResetTechnique3Pulse()
    ResetTechnique5()
    ExitApp()
}
