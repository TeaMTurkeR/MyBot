; #FUNCTION# ====================================================================================================================
; Name ..........: LocateBarrack
; Description ...:
; Syntax ........: LocateBarrack([$ArmyCamp = False])
; Parameters ....: $ArmyCamp            - [optional] Flag to set if locating army camp and not barrack Default is False.
; Return values .: None
; Author ........: Code Monkey #19
; Modified ......: KnowJack (June 2015) Sardo 2015-08
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Func LocateBarrack($ArmyCamp = False)
	Local $choice = getLocaleString("choiceBarrack")
	Local $stext, $MsgBox, $iCount, $iStupid = 0, $iSilly = 0, $sErrorText = "", $sLocMsg = "", $sInfo, $sArmyInfo
	Local $aGetArmySize[3] = ["", "", ""]
	Local $sArmyInfo = ""

	If $ArmyCamp Then $choice = getLocaleString("choiceArmyCamp")
	SetLog(getLocaleString("logLocatingAC") & $choice & getLocaleString("logLocatingAC2"), $COLOR_BLUE)

	If _GetPixelColor($aTopLeftClient[0], $aTopLeftClient[1], True) <> Hex($aTopLeftClient[2], 6) And _GetPixelColor($aTopRightClient[0], $aTopRightClient[1], True) <> Hex($aTopRightClient[2], 6) Then
		Zoomout()
		Collect()
	EndIf

	While 1
		ClickP($aAway,1,0,"#0361")
		_ExtMsgBoxSet(1 + 64, $SS_CENTER, 0x004080, 0xFFFF00, 12, "Lucida Sans Unicode", 700)
		$stext =  $sErrorText & @CRLF & getLocaleString("msgboxMsg1") & $choice & getLocaleString("msgboxMsg1_2") & @CRLF & @CRLF & _
		getLocaleString("msgboxMsg2")& @CRLF & @CRLF & getLocaleString("msgboxMsg3") & @CRLF
		$MsgBox = _ExtMsgBox(0, getLocaleString("msgboxControlOk"), getLocaleString("msgboxControlLocate") & $choice, $stext, 15, $frmBot)
		If $MsgBox = 1 Then
			WinActivate($HWnD)
			If $ArmyCamp Then
				$ArmyPos[0] = FindPos()[0]
				$ArmyPos[1] = FindPos()[1]
				If _Sleep($iDelayLocateBarrack1) Then Return
				If isInsideDiamond($ArmyPos) = False Then
					$iStupid += 1
					Select
						Case $iStupid = 1
							$sErrorText = $choice & getLocaleString("txtLocationNotValid")&@CRLF
							SetLog(getLocaleString("logStupidCase1"), $COLOR_RED)
							ContinueLoop
						Case $iStupid = 2
							$sErrorText = getLocaleString("txtStupidCase2") & @CRLF
							ContinueLoop
						Case $iStupid = 3
							$sErrorText = getLocaleString("txtStupidCase3") & $ArmyPos[0] & "," & $ArmyPos[1] & getLocaleString("txtStupidCase3_2",1) & @CRLF
							ContinueLoop
						Case $iStupid = 4
							$sErrorText = getLocaleString("txtStupidCase4",1) & @CRLF
							ContinueLoop
						Case $iStupid > 4
							SetLog(getLocaleString("txtOperatorErr") & $choice & getLocaleString("txtOperatorErr2") & "(" & $ArmyPos[0] & "," & $ArmyPos[1] & ")", $COLOR_RED)
							ClickP($aAway,1,0,"#0362")
							Return False
						Case Else
							SetLog(getLocaleString("txtOperatorErr") & $choice & getLocaleString("txtOperatorErr2") & "(" & $ArmyPos[0] & "," & $ArmyPos[1] & ")", $COLOR_RED)
							$ArmyPos[0] = -1
							$ArmyPos[1] = -1
							ClickP($aAway,1,0,"#0363")
							Return False
					EndSelect
				EndIf
				$sArmyInfo = BuildingInfo(242, 520)
				If $sArmyInfo[0] > 1 Or $sArmyInfo[0] = "" Then
					If  StringInStr($sArmyInfo[1], "Army") = 0 Then
						If $sArmyInfo[0] = "" Then
							$sLocMsg = getLocaleString("txtLocMsgNothing")
						Else
							$sLocMsg = $sArmyInfo[1]
						EndIf
						$iSilly += 1
						Select
							Case $iSilly = 1
								$sErrorText = getLocaleString("txtSillyCaseArmyCamp") & $sLocMsg & @CRLF
								ContinueLoop
							Case $iSilly = 2
								$sErrorText = getLocaleString("txtSillyCase2") & $sLocMsg & @CRLF
								ContinueLoop
							Case $iSilly = 3
								$sErrorText = getLocaleString("txtSillyCase3") & $sLocMsg & getLocaleString("txtSillyCase3_2",1) & @CRLF
								ContinueLoop
							Case $iSilly = 4
								$sErrorText = $sLocMsg & " ?!?!?!" & @CRLF & @CRLF & getLocaleString("txtStupidCase4",1) & @CRLF
								ContinueLoop
							Case $iSilly > 4
								SetLog(getLocaleString("txtSillyCase4AC"), $COLOR_RED)
								$ArmyPos[0] = -1
								$ArmyPos[1] = -1
								ClickP($aAway,1,0,"#0364")
								Return False
						EndSelect
					EndIf
				Else
					SetLog(getLocaleString("txtOperatorErr") & $choice & getLocaleString("txtOperatorErr2") & "(" & $ArmyPos[0] & "," & $ArmyPos[1] & ")", $COLOR_RED)
					$ArmyPos[0] = -1
					$ArmyPos[1] = -1
					ClickP($aAway,1,0,"#0365")
					Return False
				EndIf
				SetLog($choice & ": " & "(" & $ArmyPos[0] & "," & $ArmyPos[1] & ")", $COLOR_GREEN)
			Else
				$barrackPos[0][0] = FindPos()[0]
				$barrackPos[0][1] = FindPos()[1]
				If isInsideDiamondXY($barrackPos[0][0],$barrackPos[0][1]) = False Then
					$iStupid += 1
					Select
						Case $iStupid = 1
							$sErrorText = $choice & getLocaleString("txtLocationNotValid")&@CRLF
							SetLog(getLocaleString("logStupidCase1"), $COLOR_RED)
							ContinueLoop
						Case $iStupid = 2
							$sErrorText = getLocaleString("txtStupidCase2") & @CRLF
							ContinueLoop
						Case $iStupid = 3
							$sErrorText = getLocaleString("txtStupidCase3") &$barrackPos[0][0] & "," & $barrackPos[0][1] & getLocaleString("txtStupidCase3_2",1) & @CRLF
							ContinueLoop
						Case $iStupid = 4
							$sErrorText = getLocaleString("txtStupidCase4",1) & @CRLF
							ContinueLoop
						Case $iStupid > 4
							SetLog(getLocaleString("txtOperatorErr") & $choice & getLocaleString("txtOperatorErr2") & "(" & $barrackPos[0][0] & "," & $barrackPos[0][1] & ")", $COLOR_RED)
							ClickP($aAway,1,0,"#0366")
							Return False
						Case Else
							SetLog(getLocaleString("txtOperatorErr") & $choice & getLocaleString("txtOperatorErr2") & "(" & $barrackPos[0][0] & "," & $barrackPos[0][1] & ")", $COLOR_RED)
							$barrackPos[0][0] = -1
							 $barrackPos[0][1] = -1
							ClickP($aAway,1,0,"#0367")
							Return False
					EndSelect
				EndIf
				$sInfo = BuildingInfo(242, 520)
				If $sInfo[0] > 1 Or $sInfo[0] = "" Then
					If  StringInStr($sInfo[1], "Barr") = 0 Then
						If $sInfo[0] = "" Then
							$sLocMsg = getLocaleString("txtLocMsgNothing")
						Else
							$sLocMsg = $sInfo[1]
						EndIf
						$iSilly += 1
						Select
							Case $iSilly = 1
								$sErrorText = getLocaleString("txtSillyCaseBarracks") & $sLocMsg & @CRLF
								ContinueLoop
							Case $iSilly = 2
								$sErrorText = getLocaleString("txtSillyCase2") & $sLocMsg & @CRLF
								ContinueLoop
							Case $iSilly = 3
								$sErrorText = getLocaleString("txtSillyCase3") & $sLocMsg & getLocaleString("txtSillyCase3_2",1) & @CRLF
								ContinueLoop
							Case $iSilly = 4
								$sErrorText = $sLocMsg&" ?!?!?!"&@CRLF&@CRLF&getLocaleString("txtStupidCase4",1) & @CRLF
								ContinueLoop
							Case $iSilly > 4
								SetLog(getLocaleString("txtSillyCase4Barr"), $COLOR_RED)
								 $barrackPos[0][0] = -1
								 $barrackPos[0][1] = -1
								ClickP($aAway,1,0,"#0368")
								Return False
						EndSelect
					EndIf
				Else
					SetLog(getLocaleString("txtOperatorErr") & $choice & getLocaleString("txtOperatorErr2") & "(" & $barrackPos[0][0] & "," & $barrackPos[0][1] & ")", $COLOR_RED)
					 $barrackPos[0][0] = -1
					 $barrackPos[0][1] = -1
					ClickP($aAway,1,0,"#0369")
					Return False
				EndIf
				SetLog(getLocaleString("logLocateSuccess") & $choice & ": " & "(" & $barrackPos[0][0] & "," & $barrackPos[0][1] & ")", $COLOR_GREEN)
			EndIf
		Else
			SetLog(getLocaleString("logLocateCancelled") & $choice & getLocaleString("logLocateCancelled2"), $COLOR_BLUE)
			ClickP($aAway,1,0,"#0370")
			Return
		EndIf
		ExitLoop
	WEnd
	If $ArmyCamp Then
		$TotalCamp = 0 ; reset total camp number to get it updated
		_ExtMsgBoxSet(1 + 64, $SS_CENTER, 0x004080, 0xFFFF00, 12, "Lucida Sans Unicode", 500)
		$stext = getLocaleString("msgboxMsgAC")
		$MsgBox = _ExtMsgBox(48, getLocaleString("msgboxMsgACControls"), getLocaleString("msgboxMsgACTitle"), $stext, 15, $frmBot)
		If _Sleep($iDelayLocateBarrack1) Then Return

		ClickP($aAway,1,0,"#0371") ;Click Away
		If _Sleep($iDelayLocateBarrack3) Then Return

		Click($aArmyTrainButton[0], $aArmyTrainButton[1],1,0,"#0372") ;Click Army Camp
		If _Sleep($iDelayLocateBarrack1) Then Return

		$iCount = 0  ; reset loop counter
		$sArmyInfo = getArmyCampCap(212, 144) ; OCR read army trained and total
		If $debugSetlog = 1 Then Setlog("$sArmyInfo = " & $sArmyInfo, $COLOR_PURPLE)
		While $sArmyInfo = ""  ; In case the CC donations recieved msg are blocking, need to keep checking numbers for 10 seconds
			If _Sleep($iDelayLocateBarrack2) Then Return
			$sArmyInfo = getArmyCampCap(212, 144) ; OCR read army trained and total
			If $debugSetlog = 1 Then Setlog(" $sArmyInfo = " & $sArmyInfo, $COLOR_PURPLE)
			$iCount += 1
			If $iCount > 4 Then ExitLoop
		WEnd

		$aGetArmySize = StringSplit($sArmyInfo, "#") ; split the trained troop number from the total troop number
		If $debugSetlog = 1 Then Setlog("$aGetArmySize[0]= " & $aGetArmySize[0] & "$aGetArmySize[1]= " & $aGetArmySize[1] & "$aGetArmySize[2]= " & $aGetArmySize[2], $COLOR_PURPLE)
		If $aGetArmySize[0] > 1 Then ; check if the OCR was valid and returned both values
			$TotalCamp = Number($aGetArmySize[2])
			Setlog("$TotalCamp = " & $TotalCamp, $COLOR_GREEN)
		Else
			Setlog("Army size read error", $COLOR_RED) ; log if there is read error
		EndIf

		If $TotalCamp = 0 Then ; if Total camp size is still not set
			If $ichkTotalCampForced = 0 Then ; check if forced camp size set in expert tab
				$sInputbox = InputBox(getLocaleString("msgboxMsgForceAcTitle"), getLocaleString("msgboxMsgForceAc"), "200", "", Default, Default, Default, Default, 0, $frmbot)
				$TotalCamp = Number($sInputbox)
				Setlog("Army Camp User input = " & $TotalCamp, $COLOR_RED) ; log if there is read error AND we ask the user to tell us.
			Else
				$TotalCamp = Number($iValueTotalCampForced)
			EndIf
		EndIf
	EndIf
	ClickP($aAway, 1, 0, "#0206")

EndFunc   ;==>LocateBarrack


Func LocateBarrack2()
	Local $errorPositon = 0
	Local $barrackNum = ""
	Local $x

	If _GetPixelColor($aTopLeftClient[0], $aTopLeftClient[1], True) <> Hex($aTopLeftClient[2], 6) And _GetPixelColor($aTopRightClient[0], $aTopRightClient[1], True) <> Hex($aTopRightClient[2], 6) Then
		Zoomout()
		Collect()
	EndIf

	Click($aArmyTrainButton[0], $aArmyTrainButton[1], 1, 0, "#0293") ;Click Army Camp

	If WaitforPixel(715, 124, 718, 125, Hex(0xD80408, 6), 5, 10) Then
	    BarracksStatus(False) ; $numBarracksAvaiables
	Else
		SetLog ("Error open the ArmyOverView Windows!..")
	EndiF

	If _Sleep($iDelaycheckArmyCamp1) Then Return
	ClickP($aAway, 1, 0, "#0295") ;Click Away

	If $barrackPos[$numBarracksAvaiables - 1][0] = "" Then
		Local $PixelBarrackHere = GetLocationItem("getLocationBarrack")
		$barrackNum = UBound($PixelBarrackHere)
		SetLog("Total No. of Barracks: " & $barrackNum, $COLOR_PURPLE)
		If UBound($PixelBarrackHere) > 0 Then
			For $i = 0 To UBound($PixelBarrackHere) - 1
				$pixel = $PixelBarrackHere[$i]
				If $debugSetlog = 1 Then Setlog("click " & $pixel[0] & "/" & $pixel[1] )
				If isInsideDiamond($pixel) Then
					Click($pixel[0], $pixel[1])
					If _Sleep(1000) Then Return
					Local $TrainPos = _PixelSearch(512, 585, 641, 588, Hex(0x7895C2, 6), 10)  ;Finds Train Troops button
					Click($TrainPos[0], $TrainPos[1]) ;Click Train Troops button
					If WaitforPixel(715, 124, 718, 125, Hex(0xD80408, 6), 5, 10) Then ;wait until finds red Cross button in new Training popup window, max of 5 senconds / return True
						For $x = 0 To 3
							If _Sleep(100) Then Return
							If _ColorCheck(_GetPixelColor(254 + (60 * $x), 540, True), Hex(0xE8E8E0, 6), 20) Then ; slot position 60 * $x
								$barrackPos[$x][0] = $pixel[0]
								$barrackPos[$x][1] = $pixel[1]
								SetLog("- Barrack " & $x + 1 & ": (" & $barrackPos[$x][0] & "," & $barrackPos[$x][1] & ")", $COLOR_PURPLE)
								ExitLoop
							EndIf
						Next
					Else
						SetLog("- Barrack " & $i + 1 & " Error open the ArmyOverView Window!", $COLOR_PURPLE)
					EndIf
				Else
					SetLog("- Barrack " & $i + 1 & " is not inside the field, position: (" & $pixel[0] & "," & $pixel[1] & ")", $COLOR_PURPLE)
					$errorPositon = 1
				EndIf
				ClickP($aAway, 2, 50, "#0206")
			Next
		EndIf


		If $errorPositon = 1 Or $barrackNum < $numBarracksAvaiables Then
			Local $TEMPbarrackPos[4][2]

			For $i = 0 To ($numBarracksAvaiables - 1)
				Setlog("Click in Barrack n� " & $i + 1 & " and wait please...")
				$TEMPbarrackPos[$i][0] = FindPos()[0]
				$TEMPbarrackPos[$i][1] = FindPos()[1]
				If isInsideDiamondXY($TEMPbarrackPos[$i][0], $TEMPbarrackPos[$i][1]) Then
					If _Sleep($iDelayLocateBarrack2) Then Return
					Local $TrainPos = _PixelSearch(512, 585, 641, 588, Hex(0x7895C2, 6), 10) ;Finds Train Troops button
					Click($TrainPos[0], $TrainPos[1]) ;Click Train Troops button
					If WaitforPixel(715, 124, 718, 125, Hex(0xD80408, 6), 5, 10) Then ;wait until finds red Cross button in new Training popup window, max of 5 senconds / return True
						For $x = 0 To 3
							If _Sleep($iDelayLocateBarrack2) Then Return
							If _ColorCheck(_GetPixelColor(254 + (60 * $x), 540, True), Hex(0xE8E8E0, 6), 20) Then ; slot position 60 * $x
								$barrackPos[$x][0] = $TEMPbarrackPos[$i][0]
								$barrackPos[$x][1] = $TEMPbarrackPos[$i][1]
								SetLog("- Barrack " & $i + 1 & ": (" & $barrackPos[$x][0] & "," & $barrackPos[$x][1] & ")", $COLOR_PURPLE)
							;Else
								;SetLog("- Barrack " & $i + 1 & " error , position: (" & $TEMPbarrackPos[$i][0] & "," & $TEMPbarrackPos[$i][1] & ")", $COLOR_PURPLE)
							EndIf
						Next
					Else
						SetLog("- Barrack " & $i + 1 & " Error open the ArmyOverView Window!", $COLOR_PURPLE)
					EndIf
				Else
					SetLog("Quit joking, Click the Barracks, or restart bot and try again", $COLOR_RED)
				EndIf
				If _Sleep(1000) Then Return
				ClickP($aAway, 1, 0, "#0206")
			Next
		EndIf

	EndIf
	If _Sleep($iDelayBotDetectFirstTime3) Then Return

EndFunc   ;==>LocateBarrack2

