; The base path is relative to Ahk2Exe.exe
;@Ahk2Exe-Base ..\v2\AutoHotkey64.exe
#Requires AutoHotkey v2.0

#SingleInstance force
#WinActivateForce
#UseHook

SetWorkingDir(A_ScriptDir)
ListLines(False)
SetWinDelay(0)
SetControlDelay(0)
ProcessSetPriority("H")

A_HotkeyInterval := 20
A_MaxHotkeysPerInterval := 20000
A_MenuMaskKey := "vk07"

#Include "%A_ScriptDir%\libraries\read-ini.ahk"
#Include "%A_ScriptDir%\libraries\tooltip.ahk"

; ======================================================================
; Set Up Library Hooks
; ======================================================================

; Credits to Ciantic: https://github.com/Ciantic/VirtualDesktopAccessor

; Path to the DLL, relative to the script
VDA_PATH := "libraries\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GetDesktopIdByNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopIdByNumber", "Ptr")
GetDesktopNumberByIdProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopNumberById", "Ptr")
GetWindowDesktopIdProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetWindowDesktopId", "Ptr")
GetWindowDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetWindowDesktopNumber", "Ptr")
IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnCurrentVirtualDesktop", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
SetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "SetDesktopName", "Ptr")
GetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopName", "Ptr")
IsPinnedWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsPinnedWindow", "Ptr")
PinWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "PinWindow", "Ptr")
UnPinWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnPinWindow", "Ptr")
IsPinnedAppProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsPinnedApp", "Ptr")
PinAppProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "PinApp", "Ptr")
UnPinAppProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnPinApp", "Ptr")
IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnDesktopNumber", "Ptr")
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "CreateDesktop", "Ptr")
RemoveDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RemoveDesktop", "Ptr")

; On change listeners
RegisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RegisterPostMessageHook", "Ptr")
UnregisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnregisterPostMessageHook", "Ptr")

VWMess(wParam, lParam, msg, hwnd) {
    OnDesktopSwitch(lParam + 1)
}
OnMessage(0x1400 + 30, VWMess)
DllCall(RegisterPostMessageHookProc, "Ptr", A_ScriptHwnd, "Int", 0x1400 + 30, "Int")

; ======================================================================
; Auto Execute
; ======================================================================

; Set up tray tray menu

A_TrayMenu.Delete()
A_TrayMenu.Add("&Manage Desktops", hOpenDesktopManager)
A_TrayMenu.Add("Reload Settings", hReload)
A_TrayMenu.Add("Exit", hExit)
A_TrayMenu.Default := "&Manage Desktops"
A_TrayMenu.ClickCount := 1

hOpenDesktopManager(ItemName, ItemPos, MyMenu) {
    OpenDesktopManager
}

hReload(ItemName, ItemPos, MyMenu) {
    Reload
}

hExit(ItemName, ItemPos, MyMenu) {
    ExitApp
}

; Read and groom settings

; Initialize some settings (global variables)
; [KeyboardShortcutsCombinations]
KeyboardShortcutsCombinationsPinWindow := ""
KeyboardShortcutsCombinationsUnpinWindow := ""
KeyboardShortcutsCombinationsTogglePinWindow := ""
KeyboardShortcutsCombinationsPinApp := ""
KeyboardShortcutsCombinationsUnpinApp := ""
KeyboardShortcutsCombinationsTogglePinApp := ""
KeyboardShortcutsCombinationsOpenDesktopManager := ""
KeyboardShortcutsCombinationsChangeDesktopName := ""
; [KeyboardShortcutsIdentifiers]
KeyboardShortcutsIdentifiersDesktop := []
KeyboardShortcutsIdentifiersDesktopAlt := []
; [KeyboardShortcutsModifiers]
KeyboardShortcutsModifiersSwitchDesktop := ""
KeyboardShortcutsModifiersMoveWindowToDesktop := ""
KeyboardShortcutsModifiersMoveWindowAndSwitchToDesktop := ""
KeyboardShortcutsModifiersNextTenDesktops := ""
; [KeyboardShortcutsIdentifiers]
KeyboardShortcutsIdentifiersPreviousDesktop := ""
KeyboardShortcutsIdentifiersNextDesktop := ""
; [Wallpapers]
Wallpapers := []
; [DesktopNames]
DesktopNames := []
; [RunProgramWhenSwitchingToDesktop]
RunProgramWhenSwitchingToDesktop := []
; [RunProgramWhenSwitchingFromDesktop]
RunProgramWhenSwitchingFromDesktop := []

; Read the settings.ini file
ReadIni("settings.ini")

; Check and parse some settings (global variables)
; [General]
GeneralDefaultDesktop := (GeneralDefaultDesktop != "" and GeneralDefaultDesktop ~= "^[0-9]+$") ? Integer(GeneralDefaultDesktop) : 1
GeneralTaskbarScrollSwitching := (GeneralTaskbarScrollSwitching != "" and GeneralTaskbarScrollSwitching ~= "^[01]$") ? Integer(GeneralTaskbarScrollSwitching) : 1
GeneralUseNativePrevNextDesktopSwitchingIfConflicting := (GeneralUseNativePrevNextDesktopSwitchingIfConflicting ~= "^[01]$" && GeneralUseNativePrevNextDesktopSwitchingIfConflicting == "1" ? true : false)
GeneralDesktopWrapping := (GeneralDesktopWrapping != "" and GeneralDesktopWrapping ~= "^[01]$") ? Integer(GeneralDesktopWrapping) : 1
GeneralTrayTip := (GeneralTrayTip != "" and GeneralTrayTip ~= "^[01]$") ? Integer(GeneralTrayTip) : 1
; [ToolTips]
TooltipsEnabled := (TooltipsEnabled != "" and TooltipsEnabled ~= "^[01]$") ? Integer(TooltipsEnabled) : 1
TooltipsPositionX := (TooltipsPositionX == "LEFT" or TooltipsPositionX == "CENTER" or TooltipsPositionX == "RIGHT") ? TooltipsPositionX : "CENTER"
TooltipsPositionY := (TooltipsPositionY == "TOP" or TooltipsPositionY == "CENTER" or TooltipsPositionY == "BOTTOM") ? TooltipsPositionY : "CENTER"
TooltipsFontSize := (TooltipsFontSize != "" and TooltipsFontSize ~= "^\d+$") ? Integer(TooltipsFontSize) : 11
TooltipsFontColor := (TooltipsFontColor != "" and TooltipsFontColor ~= "^0x[0-9A-Fa-f]{1,6}$") ? TooltipsFontColor : "0xFFFFFF"
TooltipsFontInBold := (TooltipsFontInBold != "" and TooltipsFontInBold ~= "^[01]$") ? (TooltipsFontInBold ? 700 : 400) : 700
TooltipsBackgroundColor := (TooltipsBackgroundColor != "" and TooltipsBackgroundColor ~= "^0x[0-9A-Fa-f]{1,6}$") ? TooltipsBackgroundColor : "0x1F1F1F"
TooltipsLifespan := (TooltipsLifespan != "" and TooltipsLifespan ~= "^\d+$") ? Integer(TooltipsLifespan) : 750
TooltipsFadeOutAnimationDuration := (TooltipsFadeOutAnimationDuration != "" and TooltipsFadeOutAnimationDuration ~= "^\d+$") ? Integer(TooltipsFadeOutAnimationDuration) : 100
TooltipsOnEveryMonitor := (TooltipsOnEveryMonitor != "" and TooltipsOnEveryMonitor ~= "^[01]$") ? Integer(TooltipsOnEveryMonitor) : 1


; Initialize

taskbarPrimaryID := 0
taskbarSecondaryID := 0
previousDesktopNo := 0
doFocusAfterNextSwitch := 0
; hasSwitchedDesktopsBefore := 1

changeDesktopNamesPopupTitle := "Windows 11 Virtual Desktop Enhancer"
changeDesktopNamesPopupText :=  "Change the desktop name of desktop #{:d}"

initialDesktopNo := _GetCurrentDesktopNumber()

SwitchToDesktop(GeneralDefaultDesktop)
; Call "OnDesktopSwitch" since it wouldn't be called otherwise, if the default desktop matches the current one
if (GeneralDefaultDesktop == initialDesktopNo) {
    OnDesktopSwitch(GeneralDefaultDesktop)
}

; ======================================================================
; Set Up Key Bindings
; ======================================================================

; Translate the modifier keys strings

hkModifiersSwitch          := KeyboardShortcutsModifiersSwitchDesktop
hkModifiersMove            := KeyboardShortcutsModifiersMoveWindowToDesktop
hkModifiersMoveAndSwitch   := KeyboardShortcutsModifiersMoveWindowAndSwitchToDesktop
hkModifiersPlusTen         := KeyboardShortcutsModifiersNextTenDesktops
hkIdentifierPrevious       := KeyboardShortcutsIdentifiersPreviousDesktop
hkIdentifierNext           := KeyboardShortcutsIdentifiersNextDesktop
hkComboPinWin              := KeyboardShortcutsCombinationsPinWindow
hkComboUnpinWin            := KeyboardShortcutsCombinationsUnpinWindow
hkComboTogglePinWin        := KeyboardShortcutsCombinationsTogglePinWindow
hkComboPinApp              := KeyboardShortcutsCombinationsPinApp
hkComboUnpinApp            := KeyboardShortcutsCombinationsUnpinApp
hkComboTogglePinApp        := KeyboardShortcutsCombinationsTogglePinApp
hkComboOpenDesktopManager  := KeyboardShortcutsCombinationsOpenDesktopManager
hkComboChangeDesktopName   := KeyboardShortcutsCombinationsChangeDesktopName

arrayS := Array(),                    arrayR := Array()
arrayS.Push("\s*|,"),                 arrayR.Push("")
arrayS.Push("L(Ctrl|Shift|Alt|Win)"), arrayR.Push("<$1")
arrayS.Push("R(Ctrl|Shift|Alt|Win)"), arrayR.Push(">$1")
arrayS.Push("Ctrl"),                  arrayR.Push("^")
arrayS.Push("Shift"),                 arrayR.Push("+")
arrayS.Push("Alt"),                   arrayR.Push("!")
arrayS.Push("Win"),                   arrayR.Push("#")

Loop arrayS.Length {
    hkModifiersSwitch         := RegExReplace(hkModifiersSwitch, arrayS[A_Index], arrayR[A_Index])
    hkModifiersMove           := RegExReplace(hkModifiersMove, arrayS[A_Index], arrayR[A_Index])
    hkModifiersMoveAndSwitch  := RegExReplace(hkModifiersMoveAndSwitch, arrayS[A_Index], arrayR[A_Index])
    hkModifiersPlusTen        := RegExReplace(hkModifiersPlusTen, arrayS[A_Index], arrayR[A_Index])
    hkComboPinWin             := RegExReplace(hkComboPinWin, arrayS[A_Index], arrayR[A_Index])
    hkComboUnpinWin           := RegExReplace(hkComboUnpinWin, arrayS[A_Index], arrayR[A_Index])
    hkComboTogglePinWin       := RegExReplace(hkComboTogglePinWin, arrayS[A_Index], arrayR[A_Index])
    hkComboPinApp             := RegExReplace(hkComboPinApp, arrayS[A_Index], arrayR[A_Index])
    hkComboUnpinApp           := RegExReplace(hkComboUnpinApp, arrayS[A_Index], arrayR[A_Index])
    hkComboTogglePinApp       := RegExReplace(hkComboTogglePinApp, arrayS[A_Index], arrayR[A_Index])
    hkComboOpenDesktopManager := RegExReplace(hkComboOpenDesktopManager, arrayS[A_Index], arrayR[A_Index])
    hkComboChangeDesktopName  := RegExReplace(hkComboChangeDesktopName, arrayS[A_Index], arrayR[A_Index])    
}

; Setup key bindings dynamically
;  If they are set incorrectly in the settings, an error will be thrown.

setUpHotkey(hk, handler, settingPaths) {
    try
        Hotkey hk, handler
    catch as ex
    {
        MsgBox "One or more keyboard shortcut settings have been defined incorrectly in the settings file: `n" . settingPaths . ". `n`nPlease read the README for instructions.`n`n" . ex.Message, "Error"
        Exit()
    }
}

setUpHotkeyWithOneSetOfModifiersAndIdentifier(modifiers, identifier, handler, settingPaths) {
    (modifiers != "" && identifier != "") ? setUpHotkey(modifiers . identifier, handler, settingPaths) : ""
}

setUpHotkeyWithTwoSetOfModifiersAndIdentifier(modifiersA, modifiersB, identifier, handler, settingPaths) {
    (modifiersA != "" && modifiersB != "" && identifier != "") ? setUpHotkey(modifiersA . modifiersB . identifier, handler, settingPaths) : ""
}

setUpHotkeyWithCombo(combo, handler, settingPaths) {
    (combo != "") ? setUpHotkey(combo, handler, settingPaths) : ""
}

hkDesktopId := ["", ""]
i := 1
while (i <= KeyboardShortcutsIdentifiersDesktop.Length) {
    hkDesktopId[1] := KeyboardShortcutsIdentifiersDesktop[i]
    hkDesktopId[2] := KeyboardShortcutsIdentifiersDesktopAlt[i]
    j := 1
    while (j <= 2) {
        hkDesktopI := hkDesktopId[j]
        setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitch, hkDesktopI, OnShiftNumberedPress, "[KeyboardShortcutsModifiers] SwitchDesktop")
        setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMove, hkDesktopI, OnMoveNumberedPress, "[KeyboardShortcutsModifiers] MoveWindowToDesktop")
        setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitch, hkDesktopI, OnMoveAndShiftNumberedPress, "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktop")
        setUpHotkeyWithTwoSetOfModifiersAndIdentifier(hkModifiersSwitch, hkModifiersPlusTen, hkDesktopI, OnShiftNumberedPressNextTen, "[KeyboardShortcutsModifiers] SwitchDesktop, [KeyboardShortcutsModifiers] NextTenDesktops")
        setUpHotkeyWithTwoSetOfModifiersAndIdentifier(hkModifiersMove, hkModifiersPlusTen, hkDesktopI, OnMoveNumberedPressNextTen, "[KeyboardShortcutsModifiers] MoveWindowToDesktop, [KeyboardShortcutsModifiers] NextTenDesktops")
        setUpHotkeyWithTwoSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitch, hkModifiersPlusTen, hkDesktopI, OnMoveAndShiftNumberedPressNextTen, "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktop, [KeyboardShortcutsModifiers] NextTenDesktops")
        j++
    }
    i++
}

if (!(GeneralUseNativePrevNextDesktopSwitchingIfConflicting && _IsPrevNextDesktopSwitchingKeyboardShortcutConflicting(hkModifiersSwitch, hkIdentifierPrevious))) {
    setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitch, hkIdentifierPrevious, OnShiftLeftPress, "[KeyboardShortcutsModifiers] SwitchDesktop, [KeyboardShortcutsIdentifiers] PreviousDesktop")
}
if (!(GeneralUseNativePrevNextDesktopSwitchingIfConflicting && _IsPrevNextDesktopSwitchingKeyboardShortcutConflicting(hkModifiersSwitch, hkIdentifierNext))) {
    setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitch, hkIdentifierNext, OnShiftRightPress, "[KeyboardShortcutsModifiers] SwitchDesktop, [KeyboardShortcutsIdentifiers] NextDesktop")
}

setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMove, hkIdentifierPrevious, OnMoveLeftPress, "[KeyboardShortcutsModifiers] MoveWindowToDesktop, [KeyboardShortcutsIdentifiers] PreviousDesktop")
setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMove, hkIdentifierNext, OnMoveRightPress, "[KeyboardShortcutsModifiers] MoveWindowToDesktop, [KeyboardShortcutsIdentifiers] NextDesktop")

setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitch, hkIdentifierPrevious, OnMoveAndShiftLeftPress, "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktop, [KeyboardShortcutsIdentifiers] PreviousDesktop")
setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitch, hkIdentifierNext, OnMoveAndShiftRightPress, "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktop, [KeyboardShortcutsIdentifiers] NextDesktop")

setUpHotkeyWithCombo(hkComboPinWin, OnPinWindowPress, "[KeyboardShortcutsCombinations] PinWindow")
setUpHotkeyWithCombo(hkComboUnpinWin, OnUnpinWindowPress, "[KeyboardShortcutsCombinations] UnpinWindow")
setUpHotkeyWithCombo(hkComboTogglePinWin, OnTogglePinWindowPress, "[KeyboardShortcutsCombinations] TogglePinWindow")

setUpHotkeyWithCombo(hkComboPinApp, OnPinAppPress, "[KeyboardShortcutsCombinations] PinApp")
setUpHotkeyWithCombo(hkComboUnpinApp, OnUnpinAppPress, "[KeyboardShortcutsCombinations] UnpinApp")
setUpHotkeyWithCombo(hkComboTogglePinApp, OnTogglePinAppPress, "[KeyboardShortcutsCombinations] TogglePinApp")

setUpHotkeyWithCombo(hkComboOpenDesktopManager, OpenDesktopManager, "[KeyboardShortcutsCombinations] OpenDesktopManager")

setUpHotkeyWithCombo(hkComboChangeDesktopName, ChangeDesktopName, "[KeyboardShortcutsCombinations] ChangeDesktopName")

if (GeneralTaskbarScrollSwitching) {
    Hotkey "~WheelUp", OnTaskbarScrollUp
    Hotkey "~WheelDown", OnTaskbarScrollDown
}

; ======================================================================
; Event Handlers
; ======================================================================

OnShiftNumberedPress(hk:="") {
    SwitchToDesktop(substr(hk, -1, 1))
}

OnShiftNumberedPressNextTen(hk:="") {
    SwitchToDesktop("1" . substr(hk, -1, 1))
}

OnMoveNumberedPress(hk:="") {
    MoveToDesktop(substr(hk, -1, 1))
}

OnMoveNumberedPressNextTen(hk:="") {
    MoveToDesktop("1" . substr(hk, -1, 1))
}

OnMoveAndShiftNumberedPress(hk:="") {
    MoveAndSwitchToDesktop(substr(hk, -1, 1))
}

OnMoveAndShiftNumberedPressNextTen(hk:="") {
    MoveAndSwitchToDesktop("1" . substr(hk, -1, 1))
}

OnShiftLeftPress(hk:="") {
    SwitchToDesktop(_GetPreviousDesktopNumber())
}

OnShiftRightPress(hk:="") {
    SwitchToDesktop(_GetNextDesktopNumber())
}

OnMoveLeftPress(hk:="") {
    MoveToDesktop(_GetPreviousDesktopNumber())
}

OnMoveRightPress(hk:="") {
    MoveToDesktop(_GetNextDesktopNumber())
}

OnMoveAndShiftLeftPress(hk:="") {
    MoveAndSwitchToDesktop(_GetPreviousDesktopNumber())
}

OnMoveAndShiftRightPress(hk:="") {
    MoveAndSwitchToDesktop(_GetNextDesktopNumber())
}

OnTaskbarScrollUp(hk:="") {
    if (_IsCursorHoveringTaskbar()) {
        OnShiftLeftPress(hk)
    }
}

OnTaskbarScrollDown(hk:="") {
    if (_IsCursorHoveringTaskbar()) {
        OnShiftRightPress(hk)
    }
}

OnPinWindowPress(hk:="") {
    windowID := _GetCurrentWindowID()
    windowTitle := _GetCurrentWindowTitle()
    _PinWindow(windowID)
    _ShowTooltipForPinnedWindow(windowTitle)
}

OnUnpinWindowPress(hk:="") {
    windowID := _GetCurrentWindowID()
    windowTitle := _GetCurrentWindowTitle()
    _UnpinWindow(windowID)
    _ShowTooltipForUnpinnedWindow(windowTitle)
}

OnTogglePinWindowPress(hk:="") {
    windowID := _GetCurrentWindowID()
    windowTitle := _GetCurrentWindowTitle()
    if (_GetIsWindowPinned(windowID)) {
        _UnpinWindow(windowID)
        _ShowTooltipForUnpinnedWindow(windowTitle)
    }
    else {
        _PinWindow(windowID)
        _ShowTooltipForPinnedWindow(windowTitle)
    }
}

OnPinAppPress(hk:="") {
    windowID := _GetCurrentWindowID()
    windowTitle := _GetCurrentWindowTitle()
    _PinApp()
    _ShowTooltipForPinnedApp(windowTitle)
}

OnUnpinAppPress(hk:="") {
    windowID := _GetCurrentWindowID()
    windowTitle := _GetCurrentWindowTitle()
    _UnpinApp()
    _ShowTooltipForUnpinnedApp(windowTitle)
}

OnTogglePinAppPress(hk:="") {
    windowID := _GetCurrentWindowID()
    windowTitle := _GetCurrentWindowTitle()
    if (_GetIsAppPinned(windowID)) {
        _UnpinApp(windowID)
        _ShowTooltipForUnpinnedApp(windowTitle)
    }
    else {
        _PinApp(windowID)
        _ShowTooltipForPinnedApp(windowTitle)
    }
}

OnDesktopSwitch(n:=1) {
    ; Give focus first, then display the popup, otherwise the popup could
    ; steal the focus from the legitimate window until it disappears.
    global previousDesktopNo
    _FocusIfRequested()
    if (TooltipsEnabled) {
        _ShowTooltipForDesktopSwitch(n)
    }
    _ChangeAppearance(n)
    _ChangeBackground(n)

    if (previousDesktopNo) {
        _RunProgramWhenSwitchingFromDesktop(previousDesktopNo)
    }
    _RunProgramWhenSwitchingToDesktop(n)
    previousDesktopNo := n
}

; ======================================================================
; Functions
; ======================================================================

SwitchToDesktop(n:=1) {
    global doFocusAfterNextSwitch
    doFocusAfterNextSwitch := 1
    _ChangeDesktop(n)
}

MoveToDesktop(n:=1) {
    _MoveCurrentWindowToDesktop(n)
    _Focus()
}

MoveAndSwitchToDesktop(n:=1) {
    global doFocusAfterNextSwitch
    doFocusAfterNextSwitch := 1
    _MoveCurrentWindowToDesktop(n)
    _ChangeDesktop(n)
}

OpenDesktopManager(hk:="") {
    Send "{LWin down}{Tab}{LWin up}"
}

; Let the user change desktop names with a prompt, without having to edit the 'settings.ini'
; file and reload the program.
; The changes are temprorary (names will be overwritten by the default values of
; 'settings.ini' when the program will be restarted.
ChangeDesktopName(hk:="") {
    currentDesktopNumber := _GetCurrentDesktopNumber()
    currentDesktopName := _GetDesktopName(currentDesktopNumber)
    newDesktopName := InputBox(Format(changeDesktopNamesPopupText, _GetCurrentDesktopNumber()), changeDesktopNamesPopupTitle, "", currentDesktopName)
    if (newDesktopName.Result == "OK") {
        _SetDesktopName(currentDesktopNumber, newDesktopName.Value)
    }
    _ChangeAppearance(currentDesktopNumber)
}

_IsPrevNextDesktopSwitchingKeyboardShortcutConflicting(hkModifiersSwitch, hkIdentifierNextOrPrevious) {
    return ((hkModifiersSwitch == "<#<^" || hkModifiersSwitch == ">#<^" || hkModifiersSwitch == "#<^" || hkModifiersSwitch == "<#>^" || hkModifiersSwitch == ">#>^" || hkModifiersSwitch == "#>^" || hkModifiersSwitch == "<#^" || hkModifiersSwitch == ">#^" || hkModifiersSwitch == "#^") && (hkIdentifierNextOrPrevious == "Left" || hkIdentifierNextOrPrevious == "Right"))
}

_IsCursorHoveringTaskbar() {
    global taskbarPrimaryID, taskbarSecondaryID
    MouseGetPos(,, &mouseHoveringID)
    if (!taskbarPrimaryID) {
        taskbarPrimaryID := WinGetID("ahk_class Shell_TrayWnd")
    }
    if (!taskbarSecondaryID) {
        taskbarSecondaryID := WinGetID("ahk_class Shell_SecondaryTrayWnd")
    }
    return (mouseHoveringID == taskbarPrimaryID || mouseHoveringID == taskbarSecondaryID)
}

_GetCurrentWindowID() {
    activeHwnd := WinGetID("A")
    return activeHwnd
}

_GetCurrentWindowTitle() {
    activeHwnd := WinGetTitle("A")
    return activeHwnd
}

_TruncateString(string:="", n:=10) {
    return (StrLen(string) > n ? SubStr(string, 1, n-3) . "..." : string)
}

_GetDesktopName(n:=1) {
    if (n == 0) {
        n := 10
    }
    name := DesktopNames[n]
    if (!name) {
        name := "Desktop " . n
    }
    return name
}

; Set the name of the nth desktop to the value of a given string.
_SetDesktopName(n:=1, name:=0) {
    if (n == 0) {
        n := 10
    }
    if (!name) {
        ; Default value: "Desktop N".
        name := "Desktop " . n
    }
    DesktopNames[n] := name
}

_GetNextDesktopNumber() {
    i := _GetCurrentDesktopNumber()
	if (GeneralDesktopWrapping == 1) {
		i := (i == _GetNumberOfDesktops() ? 1 : i + 1)
	} else {
		i := (i == _GetNumberOfDesktops() ? i : i + 1)
	}

    return i
}

_GetPreviousDesktopNumber() {
    i := _GetCurrentDesktopNumber()
	if (GeneralDesktopWrapping == 1) {
		i := (i == 1 ? _GetNumberOfDesktops() : i - 1)
	} else {
		i := (i == 1 ? i : i - 1)
	}

    return i
}

_GetCurrentDesktopNumber() {
    return DllCall(GetCurrentDesktopNumberProc, "Int") + 1
}

_GetNumberOfDesktops() {
    return DllCall(GetDesktopCountProc, "Int")
}

_MoveCurrentWindowToDesktop(n:=1) {
    activeHwnd := _GetCurrentWindowID()
    DllCall(MoveWindowToDesktopNumberProc, "UInt", activeHwnd, "UInt", n-1)
}

_ChangeDesktop(n:=1) {
    if (n == 0) {
        n := 10
    }
    DllCall(GoToDesktopNumberProc, "Int", n-1)
}

_CallWindowProc(proc, window:="") {
    if (window == "") {
        window := _GetCurrentWindowID()
    }
    return DllCall(proc, "UInt", window)
}

_PinWindow(windowID:="") {
    _CallWindowProc(PinWindowProc, windowID)
}

_UnpinWindow(windowID:="") {
    _CallWindowProc(UnpinWindowProc, windowID)
}

_GetIsWindowPinned(windowID:="") {
    return _CallWindowProc(IsPinnedWindowProc, windowID)
}

_PinApp(windowID:="") {
    _CallWindowProc(PinAppProc, windowID)
}

_UnpinApp(windowID:="") {
    _CallWindowProc(UnpinAppProc, windowID)
}

_GetIsAppPinned(windowID:="") {
    return _CallWindowProc(IsPinnedAppProc, windowID)
}

_RunProgram(program:="", settingName:="") {
    if (program != "") {
        if (FileExist(program)) {
            Run program
        }
        else {
            MsgBox 16, Error, "The program `"" . program . "`" is not valid. `nPlease reconfigure the `"" . settingName . "`" setting. `n`nPlease read the README for instructions."
        }
    }
}

_RunProgramWhenSwitchingToDesktop(n:=1) {
    if (n == 0) {
        n := 10
    }
    _RunProgram(RunProgramWhenSwitchingToDesktop[n], "[RunProgramWhenSwitchingToDesktop] " . n)
}

_RunProgramWhenSwitchingFromDesktop(n:=1) {
    if (n == 0) {
        n := 10
    }
    _RunProgram(RunProgramWhenSwitchingFromDesktop[n], "[RunProgramWhenSwitchingFromDesktop] " . n)
}

_ChangeBackground(n:=1) {
    line := Wallpapers[n]
    isHex := RegExMatch(line, "^0x([0-9A-Fa-f]{1,6})", &hexMatchTotal)
    if (isHex) {
        hexColorReversed := SubStr("00000" . hexMatchTotal[1], -5)

        RegExMatch(hexColorReversed, "^([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})", &match)
        hexColor := "0x" . match[3] . match[2] . match[1], hexColor += 0

        DllCall("SystemParametersInfo", "UInt", 0x14, "UInt", 0, "Str", "", "UInt", 1)
        DllCall("SetSysColors", "Int", 1, "Int*", 1, "UInt*", hexColor)
    }
    else {
        filePath := line

        isRelative := (substr(filePath, 1, 1) == ".")
        if (isRelative) {
            filePath := (A_WorkingDir . substr(filePath, 2))
        }
        if (filePath and FileExist(filePath)) {
            DllCall("SystemParametersInfo", "UInt", 0x14, "UInt", 0, "Str", filePath, "UInt", 1)
        }
    }
}

_ChangeAppearance(n:=1) {
    if (GeneralTrayTip) {
        ; Hide any previous TrayTip if we switch desktops in rapid succession
        HideTrayTip
        TrayTip _GetDesktopName(n), , "0x10"
    }
    if (FileExist("./icons/" . n . ".ico")) {
        TraySetIcon  "icons/" . n . ".ico"
    }
    else {
        TraySetIcon  "icons/+.ico"
    }
}

HideTrayTip() {
    TrayTip  ; Attempt to hide it the normal way.
    ; if SubStr(A_OSVersion,1,3) = "10." {
    ;     A_IconHidden := true
    ;     Sleep 200  ; It may be necessary to adjust this sleep.
    ;     A_IconHidden := false
    ; }
}

; Only give focus to the foremost window if it has been requested.
_FocusIfRequested() {
    global doFocusAfterNextSwitch
    if (doFocusAfterNextSwitch) {
        _Focus()
        doFocusAfterNextSwitch := 0
    }
}

; Give focus to the foremost window on the desktop.
_Focus() {
    foremostWindowId := _GetForemostWindowIdOnDesktop(_GetCurrentDesktopNumber())
    Try WinActivate(foremostWindowId)
}

; Select the ahk_id of the foremost window in a given virtual desktop.
_GetForemostWindowIdOnDesktop(n) {
    if (n == 0) {
        n := 10
    }
    ; Desktop count starts at 1 for this script, but at 0 for Windows.
    n--

    ; winIDList contains a list of windows IDs ordered from the top to the bottom for each desktop.
    winIDList := WinGetList()
    for windowID in winIDList {
        windowIsOnDesktop := DllCall(IsWindowOnDesktopNumberProc, "UInt", windowID, "UInt", n, "Int")
        ; Select the first (and foremost) window which is in the specified desktop.
        if (windowIsOnDesktop == 1) {
            return windowID
        }
    }
}

_ShowTooltip(message:="") {
    params := {}
    params.message := message
    params.lifespan := TooltipsLifespan
    params.fontSize := TooltipsFontSize
    params.fontWeight := TooltipsFontInBold
    params.fontColor := TooltipsFontColor
    params.backgroundColor := TooltipsBackgroundColor
    Toast(params)
}

_ShowTooltipForDesktopSwitch(n:=1) {
    if (n == 0) {
        n := 10
    }
    _ShowTooltip(_GetDesktopName(n))
}

_ShowTooltipForPinnedWindow(windowTitle) {
    _ShowTooltip("Window `"" . _TruncateString(windowTitle, 30) . "`" pinned.")
}

_ShowTooltipForUnpinnedWindow(windowTitle) {
    _ShowTooltip("Window `"" . _TruncateString(windowTitle, 30) . "`" unpinned.")
}

_ShowTooltipForPinnedApp(windowTitle) {
    _ShowTooltip("App `"" . _TruncateString(windowTitle, 30) . "`" pinned.")
}

_ShowTooltipForUnpinnedApp(windowTitle) {
    _ShowTooltip("App `"" . _TruncateString(windowTitle, 30) . "`" unpinned.")
}
