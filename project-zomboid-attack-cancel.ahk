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

defaultOutlineEnabled := 0
defaultOutlineVariation := 30
defaultOutlinePrimaryColor := 0x68F072
defaultOutlineSecondaryColor := 0x07FF0E
defaultOutlineAttackLeadMs := 30
defaultOutlineTapHoldMs := 1
defaultOutlinePrimaryCooldownMs := 65
defaultOutlineSecondaryCooldownMs := 0

defaultChordEnabled := 1
defaultChordTrigger := "XButton1"
defaultChordIntervalMs := 200
defaultChordTapHoldMs := 18

defaultTech4Enabled := 1
defaultTech4Trigger := "XButton2"
defaultTech4IntervalMs := 200
defaultTech4TapHoldMs := 18
defaultTech4SwapEnabled := 0
defaultTech4SwapSlot := 1

defaultTech5Enabled := 1
defaultTech5Trigger := "XButton3"
defaultTech5IntervalMs := 50
defaultTech5TapHoldMs := 10

toggleKey := "F8"
panicKey := "F9"
pollMs := 5
autoSaveDelayMs := 800

enabled := false
lastMeleeCancelAt := 0
meleeSequencePhase := "idle"
meleeSequenceDueAt := 0
outlineSequenceCooldownMs := 0
outlineSequencePhase := "idle"
outlineSequenceDueAt := 0
lastChordPulseAt := 0
chordPulseActive := false
chordPulseReleaseAt := 0
lastTech4PulseAt := 0
tech4PulseActive := false
tech4PulseReleaseAt := 0
tech4SwapPulseKey := ""
lastTech5AltAt := 0
tech5AltPulseActive := false
tech5AltPulseReleaseAt := 0
tech5SpaceHeld := false
triggerCaptureTarget := ""
triggerCaptureIgnoreMap := Map()

appExe := IniRead(configPath, "general", "appExe", IniRead(configPath, "macro", "appExe", defaultAppExe))

meleeEnabled := ParseBool(IniRead(configPath, "melee", "enabled", defaultMeleeEnabled), defaultMeleeEnabled)
meleeMode := IniRead(configPath, "melee", "mode", IniRead(configPath, "macro", "mode", defaultMeleeMode))
meleeIntervalMs := ClampInt(ParseWhole(IniRead(configPath, "melee", "intervalMs", IniRead(configPath, "macro", "cancelIntervalMs", defaultMeleeIntervalMs)), defaultMeleeIntervalMs), 40, 5000)
meleeTapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "melee", "tapHoldMs", IniRead(configPath, "macro", "tapHoldMs", defaultMeleeTapHoldMs)), defaultMeleeTapHoldMs), 1, 200)
meleeAttackLeadMs := ClampInt(ParseWhole(IniRead(configPath, "melee", "attackLeadMs", IniRead(configPath, "macro", "attackLeadMs", defaultMeleeAttackLeadMs)), defaultMeleeAttackLeadMs), 0, 200)

outlineEnabled := ParseBool(IniRead(configPath, "outline", "enabled", defaultOutlineEnabled), defaultOutlineEnabled)
outlineVariation := ClampInt(ParseWhole(IniRead(configPath, "outline", "variation", defaultOutlineVariation), defaultOutlineVariation), 0, 255)
outlinePrimaryColor := ClampInt(ParseWhole(IniRead(configPath, "outline", "primaryColor", defaultOutlinePrimaryColor), defaultOutlinePrimaryColor), 0, 0xFFFFFF)
outlineSecondaryColor := ClampInt(ParseWhole(IniRead(configPath, "outline", "secondaryColor", defaultOutlineSecondaryColor), defaultOutlineSecondaryColor), 0, 0xFFFFFF)
outlineAttackLeadMs := ClampInt(ParseWhole(IniRead(configPath, "outline", "attackLeadMs", defaultOutlineAttackLeadMs), defaultOutlineAttackLeadMs), 0, 200)
outlineTapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "outline", "tapHoldMs", defaultOutlineTapHoldMs), defaultOutlineTapHoldMs), 1, 200)
outlinePrimaryCooldownMs := ClampInt(ParseWhole(IniRead(configPath, "outline", "primaryCooldownMs", defaultOutlinePrimaryCooldownMs), defaultOutlinePrimaryCooldownMs), 0, 5000)
outlineSecondaryCooldownMs := ClampInt(ParseWhole(IniRead(configPath, "outline", "secondaryCooldownMs", defaultOutlineSecondaryCooldownMs), defaultOutlineSecondaryCooldownMs), 0, 5000)

chordEnabled := ParseBool(IniRead(configPath, "chord", "enabled", defaultChordEnabled), defaultChordEnabled)
chordTrigger := IniRead(configPath, "chord", "trigger", defaultChordTrigger)
chordIntervalMs := ClampInt(ParseWhole(IniRead(configPath, "chord", "intervalMs", defaultChordIntervalMs), defaultChordIntervalMs), 20, 5000)
chordTapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "chord", "tapHoldMs", defaultChordTapHoldMs), defaultChordTapHoldMs), 1, 200)

tech4Enabled := ParseBool(IniRead(configPath, "tech4", "enabled", defaultTech4Enabled), defaultTech4Enabled)
tech4Trigger := IniRead(configPath, "tech4", "trigger", defaultTech4Trigger)
tech4IntervalMs := ClampInt(ParseWhole(IniRead(configPath, "tech4", "intervalMs", defaultTech4IntervalMs), defaultTech4IntervalMs), 20, 5000)
tech4TapHoldMs := ClampInt(ParseWhole(IniRead(configPath, "tech4", "tapHoldMs", defaultTech4TapHoldMs), defaultTech4TapHoldMs), 1, 200)
tech4SwapEnabled := ParseBool(IniRead(configPath, "tech4", "swapEnabled", defaultTech4SwapEnabled), defaultTech4SwapEnabled)
tech4SwapSlot := ClampInt(ParseWhole(IniRead(configPath, "tech4", "swapSlot", defaultTech4SwapSlot), defaultTech4SwapSlot), 1, 3)

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

outlineEnabledCtrl := macroGui.Add("Checkbox", "xm y+10", "Outline color trigger (hold RMB in windowed mode)")
outlineEnabledCtrl.Value := outlineEnabled

macroGui.Add("Text", "xm y+6 w440", "Aim Outline must be AnyWeapon. Colors: 68F072 and 07FF0E.")

macroGui.Add("Text", "xm y+18", "Technique 3 - Repeating Alt + Space")
chordEnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 3 (hold trigger to repeat Alt + Space)")
chordEnabledCtrl.Value := chordEnabled

macroGui.Add("Text", "xm y+6 w440", "Hold the Technique 3 trigger. The script repeatedly taps Alt + Space.")

macroGui.Add("Text", "xm y+10", "Trigger button")
chordTriggerCtrl := macroGui.Add("Edit", "xm w150 ReadOnly", chordTrigger)
chordSetTriggerButton := macroGui.Add("Button", "x+8 w95", "Set Trigger")

macroGui.Add("Text", "xm y+10", "Interval (ms)")
chordIntervalCtrl := macroGui.Add("Edit", "xm w90 Number", chordIntervalMs)

macroGui.Add("Text", "x+14 yp", "Tap hold (ms)")
chordTapHoldCtrl := macroGui.Add("Edit", "x+6 w90 Number", chordTapHoldMs)

macroGui.Add("Text", "xm y+18", "Technique 4 - Repeat Alt + Space")
tech4EnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 4")
tech4EnabledCtrl.Value := tech4Enabled

macroGui.Add("Text", "xm y+6 w440", "Hold the Technique 4 trigger. The script repeatedly taps Alt + Space. Swap can also tap 1, 2, or 3.")

macroGui.Add("Text", "xm y+10", "Trigger button")
tech4TriggerCtrl := macroGui.Add("Edit", "xm w150 ReadOnly", tech4Trigger)
tech4SetTriggerButton := macroGui.Add("Button", "x+8 w95", "Set Trigger")

tech4SwapEnabledCtrl := macroGui.Add("Checkbox", "x+14 yp+2", "Swap")
tech4SwapEnabledCtrl.Value := tech4SwapEnabled

macroGui.Add("Text", "xm y+10", "Interval (ms)")
tech4IntervalCtrl := macroGui.Add("Edit", "xm w90 Number", tech4IntervalMs)

macroGui.Add("Text", "x+14 yp", "Tap hold (ms)")
tech4TapHoldCtrl := macroGui.Add("Edit", "x+6 w90 Number", tech4TapHoldMs)

macroGui.Add("Text", "x+14 yp", "Swap slot")
tech4SwapCtrl := macroGui.Add("Edit", "x+6 w60 Number Limit1", tech4SwapSlot)

macroGui.Add("Text", "xm y+18", "Technique 5 - Hold Space + Tap Alt")
tech5EnabledCtrl := macroGui.Add("Checkbox", "xm y+4", "Enable Technique 5")
tech5EnabledCtrl.Value := tech5Enabled

macroGui.Add("Text", "xm y+6 w440", "Default trigger is XButton3. If your mouse does not expose it, use Set Trigger and press another key or button.")

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

helpText := macroGui.Add(
    "Text",
    "xm y+14 w440",
    "F8 start/stop, F9 exit. Technique 1 can use outline colors in windowed mode. Technique 3/4/5 triggers can be captured from the next key or mouse button you press."
)

meleeEnabledCtrl.OnEvent("Click", OnSettingsChanged)
meleeModeCtrl.OnEvent("Change", OnSettingsChanged)
meleeIntervalCtrl.OnEvent("Change", OnSettingsChanged)
meleeTapHoldCtrl.OnEvent("Change", OnSettingsChanged)
meleeAttackLeadCtrl.OnEvent("Change", OnSettingsChanged)
outlineEnabledCtrl.OnEvent("Click", OnSettingsChanged)
chordEnabledCtrl.OnEvent("Click", OnSettingsChanged)
chordSetTriggerButton.OnEvent("Click", BeginTriggerCapture.Bind("chord"))
chordIntervalCtrl.OnEvent("Change", OnSettingsChanged)
chordTapHoldCtrl.OnEvent("Change", OnSettingsChanged)
tech4EnabledCtrl.OnEvent("Click", OnSettingsChanged)
tech4SetTriggerButton.OnEvent("Click", BeginTriggerCapture.Bind("tech4"))
tech4SwapEnabledCtrl.OnEvent("Click", OnSettingsChanged)
tech4IntervalCtrl.OnEvent("Change", OnSettingsChanged)
tech4TapHoldCtrl.OnEvent("Change", OnSettingsChanged)
tech4SwapCtrl.OnEvent("Change", OnSettingsChanged)
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

ApplyGuiToState(showNotice := true, syncControls := true) {
    global appExe
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
    global outlineEnabled
    global outlineEnabledCtrl
    global meleeTapHoldCtrl
    global meleeTapHoldMs
    global tech4Enabled
    global tech4EnabledCtrl
    global tech4IntervalCtrl
    global tech4IntervalMs
    global tech4SwapCtrl
    global tech4SwapEnabled
    global tech4SwapEnabledCtrl
    global tech4SwapSlot
    global tech4TapHoldCtrl
    global tech4TapHoldMs
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
    outlineEnabled := outlineEnabledCtrl.Value

    chordEnabled := chordEnabledCtrl.Value
    chordIntervalMs := ClampInt(ParseWhole(chordIntervalCtrl.Value, defaultChordIntervalMs), 20, 5000)
    chordTapHoldMs := ClampInt(ParseWhole(chordTapHoldCtrl.Value, defaultChordTapHoldMs), 1, 200)

    tech4Enabled := tech4EnabledCtrl.Value
    tech4IntervalMs := ClampInt(ParseWhole(tech4IntervalCtrl.Value, defaultTech4IntervalMs), 20, 5000)
    tech4TapHoldMs := ClampInt(ParseWhole(tech4TapHoldCtrl.Value, defaultTech4TapHoldMs), 1, 200)
    tech4SwapEnabled := tech4SwapEnabledCtrl.Value
    tech4SwapSlot := ClampInt(ParseWhole(tech4SwapCtrl.Value, defaultTech4SwapSlot), 1, 3)

    tech5Enabled := tech5EnabledCtrl.Value
    tech5Trigger := Trim(tech5TriggerCtrl.Value)
    tech5IntervalMs := ClampInt(ParseWhole(tech5IntervalCtrl.Value, defaultTech5IntervalMs), 20, 5000)
    tech5TapHoldMs := ClampInt(ParseWhole(tech5TapHoldCtrl.Value, defaultTech5TapHoldMs), 1, 200)

    if syncControls {
        meleeIntervalCtrl.Value := meleeIntervalMs
        meleeTapHoldCtrl.Value := meleeTapHoldMs
        meleeAttackLeadCtrl.Value := meleeAttackLeadMs
        chordTriggerCtrl.Value := chordTrigger
        chordIntervalCtrl.Value := chordIntervalMs
        chordTapHoldCtrl.Value := chordTapHoldMs
        tech4TriggerCtrl.Value := tech4Trigger
        tech4IntervalCtrl.Value := tech4IntervalMs
        tech4TapHoldCtrl.Value := tech4TapHoldMs
        tech4SwapCtrl.Value := tech4SwapSlot
        tech5TriggerCtrl.Value := tech5Trigger
        tech5IntervalCtrl.Value := tech5IntervalMs
        tech5TapHoldCtrl.Value := tech5TapHoldMs
    }
    meleeAttackLeadCtrl.Enabled := (meleeMode = "click_and_space")
    tech4SwapCtrl.Enabled := tech4SwapEnabled

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
    global outlineEnabled
    global statusText
    global tech4Enabled
    global tech4IntervalMs
    global tech4SwapEnabled
    global tech4SwapSlot
    global tech4TapHoldMs
    global tech4Trigger
    global tech5Enabled
    global tech5IntervalMs
    global tech5Trigger
    global toggleButton

    statusText.Text := "Status: " (enabled ? "ON" : "OFF")
        . " | T1: " (meleeEnabled ? "ON" : "OFF") " " meleeIntervalMs " ms " ModeLabel(meleeMode)
        . (outlineEnabled ? " outline" : "")
        . " | T3: " (chordEnabled ? "ON" : "OFF") " " chordTrigger
        . " => " chordIntervalMs " ms"
        . " | T4: " (tech4Enabled ? "ON" : "OFF") " " tech4Trigger " => " tech4IntervalMs " ms"
        . (tech4SwapEnabled ? " swap" tech4SwapSlot : "")
        . " | T5: " (tech5Enabled ? "ON" : "OFF") " " tech5Trigger " => " tech5IntervalMs " ms"

    hintText.Text := "T1 interval = " meleeIntervalMs " ms | T1 hold = " meleeTapHoldMs " ms"
        . " | T1 outline colors = 68F072 / 07FF0E"
        . " | T3 interval = " chordIntervalMs " ms | T3 hold = " chordTapHoldMs " ms"
        . " | T4 interval = " tech4IntervalMs " ms | T4 hold = " tech4TapHoldMs " ms"
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

StartTechnique4Pulse(holdMs, swapEnabled, swapSlot) {
    global tech4PulseActive
    global tech4PulseReleaseAt
    global tech4SwapPulseKey

    SendEvent("{Blind}{LAlt down}")
    SendEvent("{Blind}{Space down}")
    tech4SwapPulseKey := ""
    if swapEnabled {
        tech4SwapPulseKey := String(swapSlot)
        SendEvent("{Blind}{" tech4SwapPulseKey " down}")
    }
    tech4PulseActive := true
    tech4PulseReleaseAt := A_TickCount + holdMs
}

StopTechnique4Pulse() {
    global tech4PulseActive
    global tech4PulseReleaseAt
    global tech4SwapPulseKey

    if !tech4PulseActive {
        tech4PulseReleaseAt := 0
        tech4SwapPulseKey := ""
        return
    }

    if (tech4SwapPulseKey != "")
        SendEvent("{Blind}{" tech4SwapPulseKey " up}")
    SendEvent("{Blind}{Space up}")
    SendEvent("{Blind}{LAlt up}")
    tech4PulseActive := false
    tech4PulseReleaseAt := 0
    tech4SwapPulseKey := ""
}

ResetTechnique4Pulse() {
    global lastTech4PulseAt

    StopTechnique4Pulse()
    lastTech4PulseAt := 0
}

StartTechnique5AltPulse(holdMs) {
    global tech5AltPulseActive
    global tech5AltPulseReleaseAt

    SendEvent("{Blind}{LButton down}")
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
    SendEvent("{Blind}{LButton up}")
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

ResetOutlineSequence() {
    global outlineSequenceCooldownMs
    global outlineSequenceDueAt
    global outlineSequencePhase

    switch outlineSequencePhase {
        case "click_down":
            SendEvent("{LButton up}")
        case "space_down":
            SendEvent("{Space up}")
            SendEvent("{LButton up}")
        case "wait_release":
            SendEvent("{LButton up}")
    }

    outlineSequencePhase := "idle"
    outlineSequenceDueAt := 0
    outlineSequenceCooldownMs := 0
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

OutlineTriggerHeld() {
    global appExe
    global enabled
    global outlineEnabled

    if !enabled || !outlineEnabled || !WinActive("ahk_exe " appExe)
        return false

    if AltDown()
        return false

    return GetKeyState("RButton", "P") && !GetKeyState("LButton", "P")
}

OutlineTriggerCooldownMs() {
    global outlinePrimaryColor
    global outlinePrimaryCooldownMs
    global outlineSecondaryColor
    global outlineSecondaryCooldownMs
    global outlineVariation

    local px := 0
    local py := 0
    local x2 := A_ScreenWidth - 1
    local y2 := A_ScreenHeight - 1

    if PixelSearch(&px, &py, 0, 0, x2, y2, outlinePrimaryColor, outlineVariation)
        return outlinePrimaryCooldownMs

    if PixelSearch(&px, &py, 0, 0, x2, y2, outlineSecondaryColor, outlineVariation)
        return outlineSecondaryCooldownMs

    return 0
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
    CheckOutlineTrigger()
    CheckTechnique3()
    CheckTechnique4()
    CheckTechnique5()
    CheckMeleeCancel()
}

CheckOutlineTrigger() {
    global outlineAttackLeadMs
    global outlineSequenceCooldownMs
    global outlineSequenceDueAt
    global outlineSequencePhase
    global outlineTapHoldMs

    if !OutlineTriggerHeld() {
        ResetOutlineSequence()
        return
    }

    if (outlineSequencePhase = "click_down") {
        if (A_TickCount < outlineSequenceDueAt)
            return

        SendEvent("{Space down}")
        outlineSequencePhase := "space_down"
        outlineSequenceDueAt := A_TickCount + outlineTapHoldMs
        return
    }

    if (outlineSequencePhase = "space_down") {
        if (A_TickCount < outlineSequenceDueAt)
            return

        SendEvent("{Space up}")
        outlineSequencePhase := "wait_release"
        outlineSequenceDueAt := A_TickCount + outlineAttackLeadMs
        return
    }

    if (outlineSequencePhase = "wait_release") {
        if (A_TickCount < outlineSequenceDueAt)
            return

        SendEvent("{LButton up}")
        outlineSequencePhase := "cooldown"
        outlineSequenceDueAt := A_TickCount + outlineSequenceCooldownMs
        return
    }

    if (outlineSequencePhase = "cooldown") {
        if (A_TickCount < outlineSequenceDueAt)
            return

        outlineSequencePhase := "idle"
        outlineSequenceDueAt := 0
        outlineSequenceCooldownMs := 0
        return
    }

    outlineSequenceCooldownMs := OutlineTriggerCooldownMs()
    if (outlineSequenceCooldownMs <= 0)
        return

    SendEvent("{LButton down}")
    outlineSequencePhase := "click_down"
    outlineSequenceDueAt := A_TickCount + outlineAttackLeadMs
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

    if Technique4Held() {
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

CheckTechnique4() {
    global lastTech4PulseAt
    global tech4IntervalMs
    global tech4PulseActive
    global tech4PulseReleaseAt
    global tech4SwapEnabled
    global tech4SwapSlot
    global tech4TapHoldMs

    if !Technique4Held() {
        ResetTechnique4Pulse()
        return
    }

    if tech4PulseActive {
        if (A_TickCount >= tech4PulseReleaseAt)
            StopTechnique4Pulse()
        return
    }

    if (A_TickCount - lastTech4PulseAt < tech4IntervalMs)
        return

    StartTechnique4Pulse(tech4TapHoldMs, tech4SwapEnabled, tech4SwapSlot)
    lastTech4PulseAt := A_TickCount
}

CheckTechnique5() {
    global lastTech5AltAt
    global tech5AltPulseActive
    global tech5AltPulseReleaseAt
    global tech5IntervalMs
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
    ResetOutlineSequence()
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
    global outlineAttackLeadMs
    global outlineEnabled
    global outlinePrimaryColor
    global outlinePrimaryCooldownMs
    global outlineSecondaryColor
    global outlineSecondaryCooldownMs
    global outlineTapHoldMs
    global outlineVariation
    global tech4Enabled
    global tech4IntervalMs
    global tech4SwapEnabled
    global tech4SwapSlot
    global tech4TapHoldMs
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

    IniWrite(outlineEnabled, configPath, "outline", "enabled")
    IniWrite(outlineVariation, configPath, "outline", "variation")
    IniWrite(outlinePrimaryColor, configPath, "outline", "primaryColor")
    IniWrite(outlineSecondaryColor, configPath, "outline", "secondaryColor")
    IniWrite(outlineAttackLeadMs, configPath, "outline", "attackLeadMs")
    IniWrite(outlineTapHoldMs, configPath, "outline", "tapHoldMs")
    IniWrite(outlinePrimaryCooldownMs, configPath, "outline", "primaryCooldownMs")
    IniWrite(outlineSecondaryCooldownMs, configPath, "outline", "secondaryCooldownMs")

    IniWrite(chordEnabled, configPath, "chord", "enabled")
    IniWrite(chordTrigger, configPath, "chord", "trigger")
    IniWrite(chordIntervalMs, configPath, "chord", "intervalMs")
    IniWrite(chordTapHoldMs, configPath, "chord", "tapHoldMs")

    IniWrite(tech4Enabled, configPath, "tech4", "enabled")
    IniWrite(tech4Trigger, configPath, "tech4", "trigger")
    IniWrite(tech4IntervalMs, configPath, "tech4", "intervalMs")
    IniWrite(tech4TapHoldMs, configPath, "tech4", "tapHoldMs")
    IniWrite(tech4SwapEnabled, configPath, "tech4", "swapEnabled")
    IniWrite(tech4SwapSlot, configPath, "tech4", "swapSlot")

    IniWrite(tech5Enabled, configPath, "tech5", "enabled")
    IniWrite(tech5Trigger, configPath, "tech5", "trigger")
    IniWrite(tech5IntervalMs, configPath, "tech5", "intervalMs")
    IniWrite(tech5TapHoldMs, configPath, "tech5", "tapHoldMs")

    if showNotice
        Notify("Saved to project-zomboid-attack-cancel.ini")
}

ResetDefaults(*) {
    global chordEnabledCtrl
    global chordIntervalCtrl
    global chordTapHoldCtrl
    global chordTriggerCtrl
    global meleeAttackLeadCtrl
    global meleeEnabledCtrl
    global meleeIntervalCtrl
    global meleeModeCtrl
    global meleeTapHoldCtrl
    global outlineEnabledCtrl
    global tech4EnabledCtrl
    global tech4IntervalCtrl
    global tech4SwapCtrl
    global tech4SwapEnabledCtrl
    global tech4TapHoldCtrl
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

    outlineEnabledCtrl.Value := defaultOutlineEnabled

    chordEnabledCtrl.Value := defaultChordEnabled
    chordTriggerCtrl.Value := defaultChordTrigger
    chordIntervalCtrl.Value := defaultChordIntervalMs
    chordTapHoldCtrl.Value := defaultChordTapHoldMs

    tech4EnabledCtrl.Value := defaultTech4Enabled
    tech4TriggerCtrl.Value := defaultTech4Trigger
    tech4IntervalCtrl.Value := defaultTech4IntervalMs
    tech4TapHoldCtrl.Value := defaultTech4TapHoldMs
    tech4SwapEnabledCtrl.Value := defaultTech4SwapEnabled
    tech4SwapCtrl.Value := defaultTech4SwapSlot

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
    ResetOutlineSequence()
    ResetTechnique3Pulse()
    ResetTechnique4Pulse()
    ResetTechnique5()
    ExitApp()
}
