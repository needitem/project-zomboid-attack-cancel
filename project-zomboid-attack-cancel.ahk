#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SendMode("Event")
SetWorkingDir(A_ScriptDir)

configPath := A_ScriptDir "\project-zomboid-attack-cancel.ini"

defaultAppExe := "ProjectZomboid64.exe"

defaultMeleeEnabled := 1
defaultMeleeMode := "space_only"
defaultMeleeIntervalMs := 110
defaultMeleeTapHoldMs := 15
defaultMeleeAttackLeadMs := 30

defaultChordEnabled := 1
defaultChordTrigger := "XButton1"
defaultChordIntervalMs := 200
defaultChordTapHoldMs := 18

defaultTech4Enabled := 1
defaultTech4Trigger := "XButton2"
tech4PulseHoldMs := 18

defaultTech5Enabled := 1
defaultTech5Trigger := "XButton3"
defaultTech5IntervalMs := 20
defaultTech5TapHoldMs := 50

toggleKey := "F8"
panicKey := "F9"
pollMs := 5
autoSaveDelayMs := 800

enabled := false
lastMeleeCancelAt := 0
meleeSequencePhase := "idle"
meleeSequenceDueAt := 0
lastChordPulseAt := 0
chordPulseActive := false
chordPulseReleaseAt := 0
tech4PulseActive := false
tech4PulseReleaseAt := 0
tech4Latched := false
lastTech5AltAt := 0
tech5AltPulseActive := false
tech5AltPulseReleaseAt := 0
tech5SpaceHeld := false
triggerCaptureTarget := ""
triggerCaptureIgnoreMap := Map()
activeTriggerReleaseHotkeys := Map()

appExe := IniRead(configPath, "general", "appExe", IniRead(configPath, "macro", "appExe", defaultAppExe))

meleeEnabled := ParseBool(IniRead(configPath, "melee", "enabled", defaultMeleeEnabled), defaultMeleeEnabled)
meleeMode := IniRead(configPath, "melee", "mode", IniRead(configPath, "macro", "mode", defaultMeleeMode))
meleeIntervalMs := ClampInt(ParseWhole(IniRead(configPath, "melee", "intervalMs", IniRead(configPath, "macro", "cancelIntervalMs", defaultMeleeIntervalMs)), defaultMeleeIntervalMs), 40, 5000)
meleeTapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "melee", "tapHoldMs", IniRead(configPath, "macro", "tapHoldMs", defaultMeleeTapHoldMs)), defaultMeleeTapHoldMs), 1, 200)
meleeAttackLeadMs := ClampInt(ParseWhole(IniRead(configPath, "melee", "attackLeadMs", IniRead(configPath, "macro", "attackLeadMs", defaultMeleeAttackLeadMs)), defaultMeleeAttackLeadMs), 0, 200)

chordEnabled := ParseBool(IniRead(configPath, "chord", "enabled", defaultChordEnabled), defaultChordEnabled)
chordTrigger := IniRead(configPath, "chord", "trigger", defaultChordTrigger)
chordIntervalMs := ClampInt(ParseWhole(IniRead(configPath, "chord", "intervalMs", defaultChordIntervalMs), defaultChordIntervalMs), 20, 5000)
chordTapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "chord", "tapHoldMs", defaultChordTapHoldMs), defaultChordTapHoldMs), 1, 200)

tech4Enabled := ParseBool(IniRead(configPath, "tech4", "enabled", defaultTech4Enabled), defaultTech4Enabled)
tech4Trigger := IniRead(configPath, "tech4", "trigger", defaultTech4Trigger)

tech5Enabled := ParseBool(IniRead(configPath, "tech5", "enabled", defaultTech5Enabled), defaultTech5Enabled)
tech5Trigger := IniRead(configPath, "tech5", "trigger", defaultTech5Trigger)
tech5IntervalMs := ClampInt(ParseWhole(IniRead(configPath, "tech5", "intervalMs", defaultTech5IntervalMs), defaultTech5IntervalMs), 20, 5000)
tech5TapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "tech5", "tapHoldMs", defaultTech5TapHoldMs), defaultTech5TapHoldMs), 1, 200)

macroGui := Gui("+AlwaysOnTop", "Project Zomboid Attack Cancel")
macroGui.MarginX := 12
macroGui.MarginY := 10
macroGui.SetFont("s9", "Segoe UI")

statusText := macroGui.Add("Text", "xm w440", "")
hintText := macroGui.Add("Text", "xm y+6 w440", "")

macroGui.Add("Text", "xm y+16", "Technique 1 - Melee Cancel")
meleeEnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 1")
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

macroGui.Add("Text", "xm y+18", "Technique 3 - Forced Ground Attack")
chordEnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 3")
chordEnabledCtrl.Value := chordEnabled

macroGui.Add("Text", "xm y+10", "Trigger button")
chordTriggerCtrl := macroGui.Add("Edit", "xm w150 ReadOnly", chordTrigger)
chordSetTriggerButton := macroGui.Add("Button", "x+8 w95", "Set Trigger")

macroGui.Add("Text", "xm y+18", "Technique 4 - Standing Knockdown")
tech4EnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 4")
tech4EnabledCtrl.Value := tech4Enabled

macroGui.Add("Text", "xm y+10", "Trigger button")
tech4TriggerCtrl := macroGui.Add("Edit", "xm w150 ReadOnly", tech4Trigger)
tech4SetTriggerButton := macroGui.Add("Button", "x+8 w95", "Set Trigger")

macroGui.Add("Text", "xm y+18", "Technique 5 - Dry Fire Loop")
tech5EnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 5")
tech5EnabledCtrl.Value := tech5Enabled

macroGui.Add("Text", "xm y+10", "Trigger button")
tech5TriggerCtrl := macroGui.Add("Edit", "xm w150 ReadOnly", tech5Trigger)
tech5SetTriggerButton := macroGui.Add("Button", "x+8 w95", "Set Trigger")

macroGui.Add("Text", "xm y+10", "Interval (ms)")
tech5IntervalCtrl := macroGui.Add("Edit", "xm w90 Number", tech5IntervalMs)

macroGui.Add("Text", "x+14 yp", "Tap hold (ms)")
tech5TapHoldCtrl := macroGui.Add("Edit", "x+6 w90 Number", tech5TapHoldMs)

toggleButton := macroGui.Add("Button", "xm y+18 w110", "Start (F8)")
saveButton := macroGui.Add("Button", "x+8 w90", "Save")
resetButton := macroGui.Add("Button", "x+8 w110", "Reset Defaults")

meleeEnabledCtrl.OnEvent("Click", OnSettingsChanged)
meleeModeCtrl.OnEvent("Change", OnSettingsChanged)
meleeIntervalCtrl.OnEvent("Change", OnSettingsChanged)
meleeTapHoldCtrl.OnEvent("Change", OnSettingsChanged)
meleeAttackLeadCtrl.OnEvent("Change", OnSettingsChanged)
chordEnabledCtrl.OnEvent("Click", OnSettingsChanged)
chordSetTriggerButton.OnEvent("Click", BeginTriggerCapture.Bind("chord"))
tech4EnabledCtrl.OnEvent("Click", OnSettingsChanged)
tech4SetTriggerButton.OnEvent("Click", BeginTriggerCapture.Bind("tech4"))
tech5EnabledCtrl.OnEvent("Click", OnSettingsChanged)
tech5SetTriggerButton.OnEvent("Click", BeginTriggerCapture.Bind("tech5"))
tech5IntervalCtrl.OnEvent("Change", OnSettingsChanged)
tech5TapHoldCtrl.OnEvent("Change", OnSettingsChanged)
toggleButton.OnEvent("Click", ToggleMacro)
saveButton.OnEvent("Click", SaveConfig)
resetButton.OnEvent("Click", ResetDefaults)
macroGui.OnEvent("Close", (*) => ExitApp())

Hotkey(toggleKey, ToggleMacro)
Hotkey(panicKey, StopScript)

ApplyGuiToState(false)
SetTimer(CheckMacros, pollMs)
macroGui.Show("AutoSize")
Notify("Project Zomboid Attack Cancel ready")

OnSettingsChanged(*) {
    ApplyGuiToState(false, false)
    QueueAutoSave()
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

ParseFloat(value, fallback) {
    value := Trim(String(value))
    if (value = "")
        return fallback

    try parsed := value + 0.0
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

ClampFloat(value, min, max) {
    if (value < min)
        return min
    if (value > max)
        return max
    return value
}

FormatDelaySec(value) {
    return Format("{:.2f}", value)
}

TriggerIsPressed(keyName) {
    if (keyName = "")
        return false
    try
        return GetKeyState(keyName, "P")
    catch
        return false
}

CaptureKeyList() {
    keys := ["LButton", "RButton", "MButton", "XButton1", "XButton2", "XButton3"]
    Loop 254 {
        vkName := Format("vk{:02X}", A_Index)
        keys.Push(vkName)
    }
    return keys
}

BeginTriggerCapture(target, *) {
    global triggerCaptureIgnoreMap
    global triggerCaptureTarget

    triggerCaptureTarget := target
    triggerCaptureIgnoreMap := Map()

    for keyName in CaptureKeyList() {
        if TriggerIsPressed(keyName)
            triggerCaptureIgnoreMap[keyName] := true
    }

    Notify("Press a key or mouse button for Technique " ((target = "chord") ? "3" : (target = "tech4") ? "4" : "5"))
    SetTimer(CaptureTriggerInput, 30)
}

CaptureTriggerInput() {
    global triggerCaptureIgnoreMap
    global triggerCaptureTarget

    if (triggerCaptureTarget = "") {
        SetTimer(CaptureTriggerInput, 0)
        return
    }

    for keyName in CaptureKeyList() {
        pressed := TriggerIsPressed(keyName)
        known := triggerCaptureIgnoreMap.Has(keyName)

        if pressed && !known {
            SaveCapturedTrigger(triggerCaptureTarget, keyName)
            return
        }

        if !pressed && known
            triggerCaptureIgnoreMap.Delete(keyName)
    }
}

SaveCapturedTrigger(target, keyName) {
    global chordTrigger
    global chordTriggerCtrl
    global tech4Trigger
    global tech4TriggerCtrl
    global tech5Trigger
    global tech5TriggerCtrl
    global triggerCaptureIgnoreMap
    global triggerCaptureTarget

    switch target {
        case "chord":
            chordTrigger := keyName
            chordTriggerCtrl.Value := keyName
        case "tech4":
            tech4Trigger := keyName
            tech4TriggerCtrl.Value := keyName
        case "tech5":
            tech5Trigger := keyName
            tech5TriggerCtrl.Value := keyName
    }

    triggerCaptureTarget := ""
    triggerCaptureIgnoreMap := Map()
    SetTimer(CaptureTriggerInput, 0)
    UpdateTriggerReleaseHotkeys()
    Notify("Trigger set: " keyName)
    QueueAutoSave()
}

QueueAutoSave() {
    global autoSaveDelayMs

    SetTimer(SaveConfigSilently, 0)
    SetTimer(SaveConfigSilently, -autoSaveDelayMs)
}

SaveConfigSilently() {
    WriteConfig(false, false)
}

TriggerReleaseHotkeyName(keyName) {
    return "*" keyName " Up"
}

OnConfiguredTriggerReleased(*) {
    ResetTechnique3Pulse()
    ResetTechnique4Pulse()
    ResetTechnique5()
}

UpdateTriggerReleaseHotkeys() {
    global activeTriggerReleaseHotkeys
    global chordTrigger
    global tech4Trigger
    global tech5Trigger

    next := Map()
    for _, keyName in [Trim(chordTrigger), Trim(tech4Trigger), Trim(tech5Trigger)] {
        if (keyName != "")
            next[keyName] := true
    }

    for keyName, _ in activeTriggerReleaseHotkeys {
        if !next.Has(keyName) {
            try Hotkey(TriggerReleaseHotkeyName(keyName), OnConfiguredTriggerReleased, "Off")
        }
    }

    for keyName, _ in next {
        if !activeTriggerReleaseHotkeys.Has(keyName) {
            try Hotkey(TriggerReleaseHotkeyName(keyName), OnConfiguredTriggerReleased, "On")
        }
    }

    activeTriggerReleaseHotkeys := next
}

ApplyGuiToState(showNotice := true, syncControls := true) {
    global appExe
    global chordEnabled
    global chordEnabledCtrl
    global chordIntervalMs
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
    global tech4Enabled
    global tech4EnabledCtrl
    global tech4Trigger
    global tech4TriggerCtrl
    global tech5Enabled
    global tech5EnabledCtrl
    global tech5IntervalCtrl
    global tech5IntervalMs
    global tech5TapHoldCtrl
    global tech5TapHoldMs
    global tech5Trigger
    global tech5TriggerCtrl

    appExe := Trim(appExe)
    if (appExe = "") {
        appExe := defaultAppExe
    }

    meleeEnabled := meleeEnabledCtrl.Value
    meleeMode := (meleeModeCtrl.Value = 2) ? "click_and_space" : "space_only"
    meleeIntervalMs := ClampInt(ParseWhole(meleeIntervalCtrl.Value, defaultMeleeIntervalMs), 40, 5000)
    meleeTapHoldMs := ClampInt(ParseWhole(meleeTapHoldCtrl.Value, defaultMeleeTapHoldMs), 1, 200)
    meleeAttackLeadMs := ClampInt(ParseWhole(meleeAttackLeadCtrl.Value, defaultMeleeAttackLeadMs), 0, 200)

    chordEnabled := chordEnabledCtrl.Value

    tech4Enabled := tech4EnabledCtrl.Value

    tech5Enabled := tech5EnabledCtrl.Value
    tech5Trigger := Trim(tech5TriggerCtrl.Value)
    tech5IntervalMs := ClampInt(ParseWhole(tech5IntervalCtrl.Value, defaultTech5IntervalMs), 20, 5000)
    tech5TapHoldMs := ClampInt(ParseWhole(tech5TapHoldCtrl.Value, defaultTech5TapHoldMs), 1, 200)

    if syncControls {
        meleeIntervalCtrl.Value := meleeIntervalMs
        meleeTapHoldCtrl.Value := meleeTapHoldMs
        meleeAttackLeadCtrl.Value := meleeAttackLeadMs
        chordTriggerCtrl.Value := chordTrigger
        tech4TriggerCtrl.Value := tech4Trigger
        tech5TriggerCtrl.Value := tech5Trigger
        tech5IntervalCtrl.Value := tech5IntervalMs
        tech5TapHoldCtrl.Value := tech5TapHoldMs
    }
    meleeAttackLeadCtrl.Enabled := (meleeMode = "click_and_space")
    UpdateTriggerReleaseHotkeys()

    UpdateGuiState()

    if showNotice
        Notify("Settings applied")
}

UpdateGuiState() {
    global chordEnabled
    global chordTrigger
    global enabled
    global hintText
    global meleeEnabled
    global meleeIntervalMs
    global meleeMode
    global statusText
    global tech4Enabled
    global tech4Trigger
    global tech5Enabled
    global tech5IntervalMs
    global tech5Trigger
    global toggleButton

    statusText.Text := "Status: " (enabled ? "ON" : "OFF")
        . " | T1: " (meleeEnabled ? "ON" : "OFF") " " meleeIntervalMs " ms " ModeLabel(meleeMode)
        . " | T3: " (chordEnabled ? "ON" : "OFF") " " chordTrigger " hold"
        . " | T4: " (tech4Enabled ? "ON" : "OFF") " " tech4Trigger " one-shot"
        . " | T5: " (tech5Enabled ? "ON" : "OFF") " " tech5Trigger " => " tech5IntervalMs " ms"

    hintText.Text := "T1 interval = " meleeIntervalMs " ms | T1 hold = " meleeTapHoldMs " ms"
        . " | T3 = hold Alt + Space"
        . " | T4 = one-shot Alt + Space"
        . " | T5 interval = " tech5IntervalMs " ms"

    toggleButton.Text := enabled ? "Stop (F8)" : "Start (F8)"
}

ModeLabel(value) {
    return (value = "click_and_space") ? "Click + Space" : "Space only"
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

    SendEvent("{Blind}{LAlt down}")
    SendEvent("{Blind}{Space down}")
    chordPulseActive := true
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
    StopTechnique3Pulse()
}

StartTechnique4Pulse(holdMs) {
    global tech4PulseActive
    global tech4PulseReleaseAt

    SendEvent("{Blind}{LAlt down}")
    SendEvent("{Blind}{Space down}")
    tech4PulseActive := true
    global tech4PulseReleaseAt
    tech4PulseReleaseAt := A_TickCount + holdMs
}

StopTechnique4Pulse() {
    global tech4PulseActive
    global tech4PulseReleaseAt

    if !tech4PulseActive {
        tech4PulseReleaseAt := 0
        return
    }

    SendEvent("{Blind}{Space up}")
    SendEvent("{Blind}{LAlt up}")
    tech4PulseActive := false
    tech4PulseReleaseAt := 0
}

ResetTechnique4Pulse() {
    global tech4Latched

    StopTechnique4Pulse()
    tech4Latched := false
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
    global lastTech5AltAt

    if !tech5AltPulseActive {
        tech5AltPulseReleaseAt := 0
        return
    }

    SendEvent("{Blind}{LAlt up}")
    tech5AltPulseActive := false
    tech5AltPulseReleaseAt := 0
    lastTech5AltAt := A_TickCount
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

    if !TriggerIsPressed(chordTrigger)
        return false

    return true
}

Technique4Held() {
    global appExe
    global enabled
    global tech4Enabled
    global tech4Trigger

    if !enabled || !tech4Enabled || !WinActive("ahk_exe " appExe)
        return false

    return TriggerIsPressed(tech4Trigger)
}

Technique5Held() {
    global appExe
    global enabled
    global tech5Enabled
    global tech5Trigger

    if !enabled || !tech5Enabled || !WinActive("ahk_exe " appExe)
        return false

    return TriggerIsPressed(tech5Trigger)
}

CheckMacros() {
    CheckTechnique3()
    CheckTechnique4()
    CheckTechnique5()
    CheckMeleeCancel()
}

CheckTechnique3() {
    global chordPulseActive

    if !Technique3Held() {
        ResetTechnique3Pulse()
        return
    }

    if Technique4Held() {
        ResetTechnique3Pulse()
        return
    }

    if chordPulseActive
        return

    StartTechnique3Pulse(0)
}

CheckTechnique4() {
    global tech4Latched
    global tech4PulseActive
    global tech4PulseReleaseAt

    if !Technique4Held() {
        ResetTechnique4Pulse()
        return
    }

    if tech4PulseActive {
        if (A_TickCount >= tech4PulseReleaseAt)
            StopTechnique4Pulse()
        return
    }

    if tech4Latched
        return

    StartTechnique4Pulse(tech4PulseHoldMs)
    tech4Latched := true
}

CheckTechnique5() {
    global tech5AltPulseActive
    global tech5AltPulseReleaseAt
    global tech5IntervalMs
    global lastTech5AltAt
    global tech5TapHoldMs

    if !Technique5Held() || Technique4Held() {
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
    ResetTechnique4Pulse()
    ResetTechnique5()
    UpdateGuiState()
    Notify("Attack cancel: " (enabled ? "ON" : "OFF"))
}

SaveConfig(*) {
    WriteConfig(true, true)
}

WriteConfig(showNotice := true, syncControls := true) {
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
    global tech4Enabled
    global tech4Trigger
    global tech5Enabled
    global tech5IntervalMs
    global tech5TapHoldMs
    global tech5Trigger

    ApplyGuiToState(false, syncControls)

    IniWrite(appExe, configPath, "general", "appExe")

    IniWrite(meleeEnabled, configPath, "melee", "enabled")
    IniWrite(meleeMode, configPath, "melee", "mode")
    IniWrite(meleeIntervalMs, configPath, "melee", "intervalMs")
    IniWrite(meleeTapHoldMs, configPath, "melee", "tapHoldMs")
    IniWrite(meleeAttackLeadMs, configPath, "melee", "attackLeadMs")

    IniWrite(chordEnabled, configPath, "chord", "enabled")
    IniWrite(chordTrigger, configPath, "chord", "trigger")
    IniWrite(chordIntervalMs, configPath, "chord", "intervalMs")
    IniWrite(chordTapHoldMs, configPath, "chord", "tapHoldMs")

    IniWrite(tech4Enabled, configPath, "tech4", "enabled")
    IniWrite(tech4Trigger, configPath, "tech4", "trigger")

    IniWrite(tech5Enabled, configPath, "tech5", "enabled")
    IniWrite(tech5Trigger, configPath, "tech5", "trigger")
    IniWrite(tech5IntervalMs, configPath, "tech5", "intervalMs")
    IniWrite(tech5TapHoldMs, configPath, "tech5", "tapHoldMs")

    if showNotice
        Notify("Saved to project-zomboid-attack-cancel.ini")
}

ResetDefaults(*) {
    global chordEnabledCtrl
    global chordTriggerCtrl
    global meleeAttackLeadCtrl
    global meleeEnabledCtrl
    global meleeIntervalCtrl
    global meleeModeCtrl
    global meleeTapHoldCtrl
    global tech4EnabledCtrl
    global tech4TriggerCtrl
    global tech5EnabledCtrl
    global tech5IntervalCtrl
    global tech5TapHoldCtrl
    global tech5TriggerCtrl

    meleeEnabledCtrl.Value := defaultMeleeEnabled
    meleeModeCtrl.Value := 1
    meleeIntervalCtrl.Value := defaultMeleeIntervalMs
    meleeTapHoldCtrl.Value := defaultMeleeTapHoldMs
    meleeAttackLeadCtrl.Value := defaultMeleeAttackLeadMs

    chordEnabledCtrl.Value := defaultChordEnabled
    chordTriggerCtrl.Value := defaultChordTrigger

    tech4EnabledCtrl.Value := defaultTech4Enabled
    tech4TriggerCtrl.Value := defaultTech4Trigger

    tech5EnabledCtrl.Value := defaultTech5Enabled
    tech5TriggerCtrl.Value := defaultTech5Trigger
    tech5IntervalCtrl.Value := defaultTech5IntervalMs
    tech5TapHoldCtrl.Value := defaultTech5TapHoldMs

    ApplyGuiToState(false)
    QueueAutoSave()
    Notify("Defaults restored")
}

StopScript(*) {
    ResetMeleeSequence()
    ResetTechnique3Pulse()
    ResetTechnique4Pulse()
    ResetTechnique5()
    ExitApp()
}
