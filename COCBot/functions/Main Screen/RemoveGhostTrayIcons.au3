; #FUNCTION# ====================================================================================================================
; Name ..........: RemoveGhostTrayIcons
; Description ...: Removes Ghost Icons with no attached process from systray, adjusts action based on OS
; Syntax ........: RemoveGhostTrayIcons()
; Parameters ....:
; Return values .: None
; Author ........: wraithdu (AutoIt Forums)
; Modified ......: Knowjack (Aug2015)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://www.autoitscript.com/forum/topic/103871-_systray-udf
; Example .......: No
; ===============================================================================================================================

Func RemoveGhostTrayIcons()

	Local $iGhostCount = 0

	Local $hTrayVisible = ControlGetHandle('[Class:Shell_TrayWnd]', '', '[Class:ToolbarWindow32;Instance:1]')
	If @error Then
		Setlog(getLocaleString("logSysTrayNotFound"), $COLOR_MAROON)
		Return SetError(1, @extended, -1)
	Else
		Setlog("Checking system tray for ghost icons", $COLOR_GREEN)
	EndIf

	Local $hTrayHidden = ControlGetHandle('[Class:NotifyIconOverflowWindow]', '', '[Class:ToolbarWindow32;Instance:1]')
	If @error Then
		Setlog(getLocaleString("logHiddenSysTrayNotFound"), $COLOR_MAROON)
	EndIf

	Local $iTrayVisibleCount = _GUICtrlToolbar_ButtonCount($hTrayVisible)
	If $debugsetlog = 1 Then Setlog("Visible tray Count: " & $iTrayVisibleCount, $COLOR_PURPLE) ; Debug

	If $iTrayVisibleCount > 1 Then
		For $i = $iTrayVisibleCount - 1 To 0 Step -1 ; Loop through the icons and look for ghost with PID = -1
			$IconText = _GUICtrlToolbar_GetButtonText($hTrayVisible, $i)
			If StringInStr($IconText, "Bluestacks") Then
				$bResult = _GUICtrlToolbar_DeleteButton($hTrayVisible, $i)
				If @error Then
					If $debugsetlog = 1 Then Setlog("$bResult = " & $bResult, $COLOR_PURPLE)
					ContinueLoop
				Else
					$iGhostCount += 1 ; Add to ghost count if removed
				EndIf
			EndIf
		Next
	EndIf

	Local $iTrayHiddenCount = _GUICtrlToolbar_ButtonCount($hTrayHidden)
	Setlog(getLocaleString("logHiddenTrayCount") &$iTrayHiddenCount, $COLOR_PURPLE) ; Debug

	If $iTrayHiddenCount > 1 Then
		For $i = $iTrayHiddenCount - 1 To 0 Step -1 ; Loop through the icons and look for ghost with PID = -1
			$IconText = _GUICtrlToolbar_GetButtonText($hTrayHidden, $i)
			If $debugsetlog = 1 Then Setlog("$IconText = " & $IconText, $COLOR_PURPLE)
			If StringInStr($IconText, "Bluestacks") Then
				$bResult = _GUICtrlToolbar_DeleteButton($hTrayHidden, $i)
				If @error Then
					If $debugsetlog = 1 Then Setlog("$bResult = " & $bResult, $COLOR_PURPLE)
					ContinueLoop
				Else
					$iGhostCount += 1 ; Add to ghost count if removed
				EndIf
			EndIf
		Next
	EndIf

	If $iGhostCount > 0 Then Setlog("Removed " & $iGhostCount & " Ghost icon successfully", $COLOR_GREEN)

EndFunc   ;==>RemoveGhostTrayIcons
