; Credits to engunneer (http://www.autohotkey.com/board/topic/21510-toaster-popups/#entry140824)

GUIForMonitor := []

; Display a toast popup on each monitor.
Toast(params:=0) {
	global GUIForMonitor

	message := params.message ? params.message : ""
	lifespan := params.lifespan ? params.lifespan : 1500
	fontSize := params.fontSize ? params.fontSize : 11
	fontWeight := params.fontWeight ? params.fontWeight : 700
	fontColor := params.fontColor ? params.fontColor : "0xFFFFFF"
	backgroundColor := params.backgroundColor ? params.backgroundColor : "0x1F1F1F"

	; Destroy existing toasts
	; Delete timer
	SetTimer closePopups, 0
	Loop GUIForMonitor.Length {
		guiHandle := GUIForMonitor[A_Index]
		if (guiHandle) {
			guiHandle.Destroy()
		}
	}
	GUIForMonitor := []

	DetectHiddenWindows "On"

	if (TooltipsOnEveryMonitor == "1") {
		; Get total number of monitors.
		monitorN := SysGet(80)
	} else {
		; Consider just the primary monitor.
		monitorN := 1
	}

	; For each monitor we need to create and draw the GUI of the toast.
	Loop monitorN {
		; Get the workspace of the monitor.
		MonitorGetWorkArea(A_Index, &WorkspaceLeft, &WorkspaceTop, &WorkspaceRight, &WorkspaceBottom)

		; Create the GUI.
		guiHandle := Gui("-Caption +ToolWindow +LastFound +AlwaysOnTop")
		guiHandle.BackColor := backgroundColor
		guiHandle.SetFont(Format("s{} c{} w{}", fontSize, fontColor, fontWeight), "Segoe UI")
		guiHandle.Add("Text", "xp+25 yp+20", message)
		guiHandle.Show("Hide")

		GUIForMonitor.Push(guiHandle)

		OnMessage(0x201, hClosePopups)

		; Position the GUI on the monitor.
		WinGetPos &GUIX, &GUIY, &GUIWidth, &GUIHeight
		GUIWidth += 20
		GUIHeight += 15

		if (ToolTipsPositionX == "LEFT") {
			NewX := WorkSpaceLeft
		} else if (ToolTipsPositionX == "RIGHT") {
			NewX := WorkSpaceRight - GUIWidth
		} else {
			; CENTER or something wrong.
			NewX := (WorkSpaceRight + WorkspaceLeft - GUIWidth) / 2
		}
		if (ToolTipsPositionY == "TOP") {
			NewY := WorkSpaceTop
		} else if (ToolTipsPositionY == "BOTTOM") {
			NewY := WorkSpaceBottom - GUIHeight
		} else {
			; CENTER or something wrong.
			NewY := (WorkSpaceTop + WorkspaceBottom - GUIHeight) / 2
		}

		; Show the GUI
		guiHandle.Show(Format("Hide x{} y{} w{} h{}", NewX, NewY, GUIWidth, GUIHeight))
		DllCall("AnimateWindow", "UInt", guiHandle.Hwnd, "Int", 1, "UInt", "0x00080000")
	}

	; Make all the toasts from all the monitors automatically disappear after a certain time.
	if (lifespan) {
		; Execute closePopups() only one time after lifespan milliseconds.
		SetTimer closePopups, -lifespan
	}

	Return
}

; Close all the toast messages.
; This function is called after a given time (lifespan) or when the text in the toasts is clicked.
hClosePopups(wParam, lParam, msg, hwnd) {
	closePopups()
}
closePopups() {
	global GUIForMonitor
	Loop GUIForMonitor.Length {
		guiHandle := GUIForMonitor[A_Index]
		if (guiHandle) {
			; Fade out each toast window.
			Try DllCall("AnimateWindow", "UInt", guiHandle.Hwnd, "Int", TooltipsFadeOutAnimationDuration, "UInt", "0x00090000")
			; Free the memory used by each toast.
			Try guiHandle.Destroy()
		}
	}
}
