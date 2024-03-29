; #FUNCTION# ====================================================================================================================
; Name ..........: Train
; Description ...: Train the troops (Fill the barracks), Uses the location of manually set Barracks to train specified troops
; Syntax ........: Train()
; Parameters ....:
; Return values .: None
; Author ........: Hungle
; Modified ......: ProMac(2015), Sardo(2015), KnowJack(Jul/Aug 2105), barracoda (July/Aug 2015), Sardo(2015-08, kaganus(Aug 2015) ,TheMaster 2015-10
; Remarks .......:
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func Train()

	Local $anotherTroops
	Local $tempCounter = 0
	Local $tempElixir = ""
	Local $tempDElixir = ""
	Local $tempElixirSpent = 0
	Local $tempDElixirSpent = 0

	If $debugSetlog = 1 Then SetLog("Func Train ", $COLOR_PURPLE)
	If $bTrainEnabled = False Then Return

	; Read Resource Values For army cost Stats
	VillageReport(True, True)
	$tempCounter = 0
	While ($iElixirCurrent = "" Or ($iDarkCurrent = "" And $iDarkStart <> "")) And $tempCounter < 5
		$tempCounter += 1
		If _Sleep(100) Then Return
		VillageReport(True, True)
	WEnd
	$tempElixir = $iElixirCurrent
	$tempDElixir = $iDarkCurrent
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; in halt attack mode Make sure army reach 100% regardless of user Percentage of full army
	If ($CommandStop = 3 Or $CommandStop = 0) Then
		CheckOverviewFullArmy(True)
		If $debugSetlog = 1 Then SetLog("Halt enabled, $TotalTrainedTroops= " & $TotalTrainedTroops & ", TotalCamp = " & $TotalCamp, $COLOR_PURPLE)
		If $fullarmy = True Then
			If $debugSetlog = 1 Then SetLog("FullArmy & TotalTrained = skip training", $COLOR_PURPLE)
			Return
		EndIf
	EndIf

	; ###########################################  1st Stage : Prepare training & Variables & Values ##############################################

	; Reset variables $Cur+TroopName ( used to assign the quantity of troops to train )
	; Only reset if the FullArmy , Last attacks was a TH Snipes or First Start.
	; Global $Cur+TroopName = 0

	If $FirstStart Or $iMatchMode == $TS Then
		For $i = 0 To UBound($TroopName) - 1
			If $debugSetlog = 1 Then SetLog("RESET AT 0 " & "Cur" & $TroopName[$i], $COLOR_PURPLE)
			Assign("Cur" & $TroopName[$i], 0)
		Next

		For $i = 0 To UBound($TroopDarkName) - 1
			If $debugSetlog = 1 Then SetLog("RESET AT 0 " & "Cur" & $TroopDarkName[$i], $COLOR_PURPLE)
			Assign("Cur" & $TroopDarkName[$i], 0)
		Next
	EndIf

	For $i = 0 To UBound($TroopName) - 1
		Assign(("tooMany" & $TroopName[$i]), 0)
		Assign(("tooFew" & $TroopName[$i]), 0)
	Next

	For $i = 0 To UBound($TroopDarkName) - 1
		Assign(("tooMany" & $TroopDarkName[$i]), 0)
		Assign(("tooFew" & $TroopDarkName[$i]), 0)
	Next



	If $FirstStart And $OptTrophyMode = 1 And $icmbTroopComp <> 8 Then
		$ArmyComp = $CurCamp
	EndIf

	; Is necessary Check Total Army Camp and existent troops inside of ArmyCamp
	; $icmbTroopComp - variable used to differentiate the Troops Composition selected in GUI
	; Inside of checkArmyCamp exists:
	; $CurCamp - quantity of troops existing in ArmyCamp  / $TotalCamp - your total troops capacity
	; BarracksStatus() - Verifying how many barracks / spells factory exists and if are available to use.
	; $numBarracksAvaiables returns to be used as the divisor to assign the amount of kind troops each barracks | $TroopName+EBarrack
	;

	checkArmyCamp()

	SetLog(getLocaleString("logTrainingTroops"), $COLOR_BLUE)
	If _Sleep($iDelayTrain1) Then Return


	ClickP($aAway, 1, 0, "#0268") ;Click Away to clear open windows in case user interupted
	If _Sleep($iDelayTrain4) Then Return

	;OPEN ARMY OVERVIEW WITH NEW BUTTON
	Click($aArmyTrainButton[0], $aArmyTrainButton[1], 1, 0, "#0293") ; Button Army Overview
	If _Sleep($iDelayTrain1) Then Return ; wait for window to open

	; exit if I'm not in train page
	If Not (IsTrainPage()) Then Return

	checkAttackDisable($iTaBChkIdle) ; Check for Take-A-Break after opening train page
	If _Sleep($iDelayTrain1) Then Return

	_CaptureRegion()
	Local $NextPos = _PixelSearch(749, 311, 787, 322, Hex(0xF08C40, 6), 5)
	Local $PrevPos = _PixelSearch(70, 311, 110, 322, Hex(0xF08C40, 6), 5)

	; CHECK IF NEED TO MAKE TROOPS
	; Verify the Global variable $TroopName+Comp and return the GUI selected troops by user
	;
	If $isNormalBuild = "" Then
		For $i = 0 To UBound($TroopName) - 1
			If Eval($TroopName[$i] & "Comp") <> "0" Then
				$isNormalBuild = True
			EndIf
		Next
	EndIf
	If $isNormalBuild = "" Then
		$isNormalBuild = False
	EndIf
	If $debugSetlog = 1 Then SetLog("Train: need to make normal troops: " & $isNormalBuild, $COLOR_PURPLE)

	; CHECK IF NEED TO MAKE DARK TROOPS
	; Verify the Global variable $TroopDarkName+Comp and return the GUI selected troops by user
	;
	If $isDarkBuild = "" Then
		For $i = 0 To UBound($TroopDarkName) - 1
			If Eval($TroopDarkName[$i] & "Comp") <> "0" Then
				$isDarkBuild = True
			EndIf
		Next
	EndIf
	If $isDarkBuild = "" Then
		$isDarkBuild = False
	EndIf
	If $debugSetlog = 1 Then SetLog("Train: need to make dark troops: " & $isDarkBuild, $COLOR_PURPLE)

	;GO TO LAST NORMAL BARRACK
	; find last barrack $i
	Local $lastbarrack = 0, $i = 4
	While $lastbarrack = 0 And $i > 1
		If $Trainavailable[$i] = 1 Then $lastbarrack = $i
		$i -= 1
	WEnd


	If $lastbarrack = 0 Then
		Setlog(getLocaleString("logNoBarrackAvailable"))
		Return ;exit from train
	Else
		If $debugSetlog = 1 Then Setlog("LAST BARRACK = " & $lastbarrack, $COLOR_PURPLE)
		;GO TO LAST BARRACK
		Local $j = 0
		While Not _ColorCheck(_GetPixelColor($btnpos[0][0], $btnpos[0][1], True), Hex(0xE8E8E0, 6), 20)
			If $debugSetlog = 1 Then Setlog("OverView TabColor=" & _GetPixelColor($btnpos[0][0], $btnpos[0][1], True), $COLOR_PURPLE)
			If _Sleep($iDelayTrain1) Then Return ; wait for Train Window to be ready.
			$j += 1
			If $j > 15 Then ExitLoop
		WEnd
		If $j > 15 Then
			SetLog(getLocaleString("logTrainingOverviewWindow"), $COLOR_RED)
			Return
		EndIf
		If Not (IsTrainPage()) Then Return ;exit if no train page
		Click($btnpos[$lastbarrack][0], $btnpos[$lastbarrack][1], 1, $iDelayTrain5, "#0336") ; Click on tab and go to last barrack
		Local $j = 0
		While Not _ColorCheck(_GetPixelColor($btnpos[$lastbarrack][0], $btnpos[$lastbarrack][1], True), Hex(0xE8E8E0, 6), 20)
			If $debugSetlog = 1 Then Setlog("Last Barrack TabColor=" & _GetPixelColor($btnpos[$lastbarrack][0], $btnpos[$lastbarrack][1], True), $COLOR_PURPLE)
			If _Sleep($iDelayTrain1) Then Return
			$j += 1
			If $j > 15 Then ExitLoop
		WEnd
		If $j > 15 Then
			SetLog(getLocaleString("logCannotOpenBarrack"), $COLOR_RED)
		EndIf
	EndIf


	; PREPARE TROOPS IF FULL ARMY
	; Baracks status to false , after the first loop and train Selected Troops composition = True
	;
	If $fullarmy Then
		$BarrackStatus[0] = False
		$BarrackStatus[1] = False
		$BarrackStatus[2] = False
		$BarrackStatus[3] = False
		$BarrackDarkStatus[0] = False
		$BarrackDarkStatus[1] = False
		SetLog(getLocaleString("logArmyCampsFull"), $COLOR_RED)
		If $pEnabled = 1 And $ichkAlertPBCampFull = 1 Then PushMsg("CampFull")
	Else
	EndIf

	; ########################################  2nd Stage : Calculating of Troops to Make ##############################################

	If $debugSetlog = 1 Then SetLog("Total ArmyCamp :" & $TotalCamp)

	If $fullarmy Then
		$ArmyComp = 0
		$anotherTroops = 0
		$TotalTrainedTroops = 0
		If $debugSetlog = 1 Then SetLog("--------- Calculating Troops / FullArmy true ---------")

		; Balance Elixir troops but not archers ,barb and goblins
		For $i = 0 To UBound($TroopName) - 1
			If $TroopName[$i] <> "Barb" And $TroopName[$i] <> "Arch" And $TroopName[$i] <> "Gobl" And Number(Eval($TroopName[$i] & "Comp")) <> 0 Then
				If $debugSetlog = 1 Then SetLog("GUI ASSIGN to $Cur" & $TroopName[$i] & ":" & Eval($TroopName[$i] & "Comp") & " Units")

				If $OptTrophyMode = 1 And $icmbTroopComp <> 8 And Eval("Cur" & $TroopName[$i]) * -1 >= Eval($TroopName[$i] & "Comp") * 2.0 Then ; 200% way too many
					SetLog("Way Too many " & $TroopName[$i] & ", Dont Train.")
					Assign(("Cur" & $TroopName[$i]), 0)
				Else
					If $OptTrophyMode = 1 And $icmbTroopComp <> 8 And Eval("Cur" & $TroopName[$i]) * -1 > Eval($TroopName[$i] & "Comp") * 1.10 Then ; 110% too many
						SetLog("Too many " & $TroopName[$i] & ", train last.")
						Assign(("Cur" & $TroopName[$i]), 0)
						Assign(("tooMany" & $TroopName[$i]), 1)
					ElseIf $OptTrophyMode = 1 And $icmbTroopComp <> 8 And (Eval("Cur" & $TroopName[$i]) * -1 < Eval($TroopName[$i] & "Comp") * .90) Then ; 90% too few
						SetLog("Too few " & $TroopName[$i] & ", train first.")
						Assign(("Cur" & $TroopName[$i]), 0)
						Assign(("tooFew" & $TroopName[$i]), 1)
					Else
						Assign(("Cur" & $TroopName[$i]), Eval($TroopName[$i] & "Comp"))
					EndIf
					If $debugSetlog = 1 And Eval($TroopName[$i] & "Comp") > 0 Then SetLog("-- AnotherTroops to train:" & $anotherTroops & " + " & Eval($TroopName[$i] & "Comp") & "*" & $TroopHeight[$i], $COLOR_PURPLE)
					$anotherTroops += Eval($TroopName[$i] & "Comp") * $TroopHeight[$i]
				EndIf

			EndIf
		Next

		If $anotherTroops > 0 Then
			If $debugSetlog = 1 Then SetLog("~Total/Space occupied after assign Normal Troops to train:" & $anotherTroops & "/" & $TotalCamp)
		EndIf

		; Balance Dark elixir troops
		For $i = 0 To UBound($TroopDarkName) - 1
			If Number(Eval($TroopDarkName[$i] & "Comp")) <> 0 Then
				If $debugSetlog = 1 Then SetLog("Need to train ASSIGN.... Cur" & $TroopDarkName[$i] & ":" & Eval($TroopDarkName[$i] & "Comp"), $COLOR_PURPLE)

				If $OptTrophyMode = 1 And $icmbTroopComp <> 8 And Eval("Cur" & $TroopDarkName[$i]) * -1 >= Eval($TroopDarkName[$i] & "Comp") * 2.0 Then ; 200% way too many
					SetLog("Way Too many " & $TroopDarkName[$i] & ", Dont Train.")
					Assign(("Cur" & $TroopDarkName[$i]), 0)
				Else
					If $OptTrophyMode = 1 And $icmbTroopComp <> 8 And Eval("Cur" & $TroopDarkName[$i]) * -1 > Eval($TroopDarkName[$i] & "Comp") * 1.10 Then ; 110% too many
						SetLog("Too many " & $TroopDarkName[$i] & ", train last.")
						Assign(("Cur" & $TroopDarkName[$i]), 0)
						Assign(("tooMany" & $TroopDarkName[$i]), 1)
					ElseIf $OptTrophyMode = 1 And $icmbTroopComp <> 8 And (Eval("Cur" & $TroopDarkName[$i]) * -1 < Eval($TroopDarkName[$i] & "Comp") * .90) Then ; 90% too few
						SetLog("Too few " & $TroopDarkName[$i] & ", train first.")
						Assign(("Cur" & $TroopDarkName[$i]), 0)
						Assign(("tooFew" & $TroopDarkName[$i]), 1)
					Else
						Assign(("Cur" & $TroopDarkName[$i]), Eval($TroopDarkName[$i] & "Comp"))
					EndIf
					If $debugSetlog = 1 And Number(Eval($TroopDarkName[$i] & "Comp")) <> 0 Then SetLog("-- AnotherTroops dark to train:" & $anotherTroops & " + " & Eval($TroopDarkName[$i] & "Comp") & "*" & $TroopDarkHeight[$i], $COLOR_PURPLE)
					$anotherTroops += Eval($TroopDarkName[$i] & "Comp") * $TroopDarkHeight[$i]
				EndIf
			EndIf
		Next

		If $anotherTroops > 0 Then
			If $debugSetlog = 1 Then SetLog("~Total/Space occupied after assign Normal+Dark Troops to train:" & $anotherTroops & "/" & $TotalCamp)
		EndIf

		If $debugSetlog = 1 Then SetLog("------- Calculating TOTAL of Units: Arch/Barbs/Gobl ------")

		; Balance Archers ,Barbs and goblins
		If $OptTrophyMode = 1 And $icmbTroopComp <> 8 Then

			For $i = 0 To UBound($TroopName) - 1
				If Number(Eval($TroopName[$i] & "Comp")) <> 0 Then
					If $TroopName[$i] = "Barb" Or $TroopName[$i] = "Arch" Or $TroopName[$i] = "Gobl" Then
						If Eval("Cur" & $TroopName[$i]) * -1 > ($TotalCamp - $anotherTroops) * Eval($TroopName[$i] & "Comp") / 100 * 1.1 Then ; 110% too many troops
							SetLog("Too many " & $TroopName[$i] & ", train last.")
							Assign("Cur" & $TroopName[$i], 0)
							Assign(("tooMany" & $TroopName[$i]), 1)
						ElseIf (Eval("Cur" & $TroopName[$i]) * -1 < ($TotalCamp - $anotherTroops) * Eval($TroopName[$i] & "Comp") / 100 * .90) Then ; 90% too few troops
							SetLog("Too few " & $TroopName[$i] & ", train first.")
							Assign("Cur" & $TroopName[$i], 0)
							Assign(("tooFew" & $TroopName[$i]), 1)
						Else
							Assign("Cur" & $TroopName[$i], Round(($TotalCamp - $anotherTroops) * Eval($TroopName[$i] & "Comp") / 100))
						EndIf
					EndIf
				EndIf
			Next
		Else
			$CurGobl = ($TotalCamp - $anotherTroops) * Eval("GoblComp") / 100
			$CurGobl = Round($CurGobl)
			$CurBarb = ($TotalCamp - $anotherTroops) * Eval("BarbComp") / 100
			$CurBarb = Round($CurBarb)
			$CurArch = ($TotalCamp - $anotherTroops) * Eval("ArchComp") / 100
			$CurArch = Round($CurArch)
		EndIf

		If $debugSetlog = 1 Then SetLog("Need to train GOBL:" & $CurGobl & " /BARB: " & $CurBarb & " /ARCH: " & $CurArch & " /Total Space: " & $CurBarb + $CurArch + $CurGobl + $anotherTroops & "/" & $TotalCamp)
		If $debugSetlog = 1 Then SetLog("--------- End Calculating Troops / FullArmy true ---------")

		;  The $Cur+TroopName will be the diference bewtween -($Cur+TroopName) returned from ChechArmycamp() and what was selected by user GUI
		;  $Cur+TroopName = Trained - needed  (-20+25 = 5)
		;  $anotherTroops = quantity unit troops x $TroopHeight
		;
	ElseIf ($ArmyComp = 0 And $icmbTroopComp <> 8) Or $FirstStart Then
		$anotherTroops = 0
		For $i = 0 To UBound($TroopName) - 1
			If $TroopName[$i] <> "Barb" And $TroopName[$i] <> "Arch" And $TroopName[$i] <> "Gobl" Then
				Assign(("Cur" & $TroopName[$i]), Eval("Cur" & $TroopName[$i]) + Eval($TroopName[$i] & "Comp"))
				If $debugSetlog = 1 And Number($anotherTroops + Eval($TroopName[$i] & "Comp")) <> 0 Then SetLog("-- AnotherTroops to train:" & $anotherTroops & " + " & Eval($TroopName[$i] & "Comp") & "*" & $TroopHeight[$i], $COLOR_PURPLE)
				$anotherTroops += Eval($TroopName[$i] & "Comp") * $TroopHeight[$i]
				If $debugSetlog = 1 And Number(Eval($TroopName[$i] & "Comp")) <> 0 Then SetLog("Need to train " & $TroopName[$i] & ":" & Eval($TroopName[$i] & "Comp"), $COLOR_PURPLE)
			EndIf
		Next
		For $i = 0 To UBound($TroopDarkName) - 1
			Assign(("Cur" & $TroopDarkName[$i]), Eval("Cur" & $TroopDarkName[$i]) + Eval($TroopDarkName[$i] & "Comp"))
			If $debugSetlog = 1 And Number($anotherTroops + Eval($TroopDarkName[$i] & "Comp")) <> 0 Then SetLog("-- AnotherTroops dark to train:" & $anotherTroops & " + " & Eval($TroopDarkName[$i] & "Comp") & "*" & $TroopDarkHeight[$i], $COLOR_PURPLE)
			$anotherTroops += Eval($TroopDarkName[$i] & "Comp") * $TroopDarkHeight[$i]
			If $debugSetlog = 1 And Number(Eval($TroopDarkName[$i] & "Comp")) <> 0 Then SetLog("Need to train " & $TroopDarkName[$i] & ":" & Eval($TroopDarkName[$i] & "Comp"), $COLOR_PURPLE)
		Next
		If $debugSetlog = 1 Then SetLog("--------------AnotherTroops TOTAL to train:" & $anotherTroops, $COLOR_PURPLE)
		$CurGobl += ($TotalCamp - $anotherTroops) * Eval("GoblComp") / 100
		$CurGobl = Round($CurGobl)
		$CurBarb += ($TotalCamp - $anotherTroops) * Eval("BarbComp") / 100
		$CurBarb = Round($CurBarb)
		$CurArch += ($TotalCamp - $anotherTroops) * Eval("ArchComp") / 100
		$CurArch = Round($CurArch)
		If $debugSetlog = 1 Then SetLog("Need to train (height) GOBL:" & $CurGobl & "% BARB: " & $CurBarb & "% ARCH: " & $CurArch & "% AND " & $anotherTroops & " other troops space", $COLOR_PURPLE)
	EndIf

	$TotalTrainedTroops += $anotherTroops + $CurGobl + $CurBarb + $CurArch ; Count of all troops required for training
	If $debugSetlog = 1 Then SetLog("Total Troops to be Trained= " & $TotalTrainedTroops, $COLOR_PURPLE)

	;Local $GiantEBarrack ,$WallEBarrack ,$ArchEBarrack ,$BarbEBarrack ,$GoblinEBarrack,$HogEBarrack,$MinionEBarrack, $WizardEBarrack
	If $debugSetlog = 1 Then SetLog("BARRACKNUM: " & $numBarracksAvaiables, $COLOR_PURPLE)
	If $numBarracksAvaiables <> 0 Then
		For $i = 0 To UBound($TroopName) - 1
			If $debugSetlog = 1 And Number(Floor(Eval("Cur" & $TroopName[$i]) / $numBarracksAvaiables)) <> 0 Then SetLog($TroopName[$i] & "EBarrack" & ": " & Floor(Eval("Cur" & $TroopName[$i]) / $numBarracksAvaiables), $COLOR_PURPLE)
			Assign(($TroopName[$i] & "EBarrack"), Floor(Eval("Cur" & $TroopName[$i]) / $numBarracksAvaiables))
		Next
	Else
		For $i = 0 To UBound($TroopName) - 1
			If $debugSetlog = 1 And Floor(Eval("Cur" & $TroopName[$i]) / 4) <> 0 Then SetLog($TroopName[$i] & "EBarrack" & ": " & Floor(Eval("Cur" & $TroopName[$i]) / 4), $COLOR_PURPLE)
			Assign(($TroopName[$i] & "EBarrack"), Floor(Eval("Cur" & $TroopName[$i]) / 4))
		Next
	EndIf
	If $debugSetlog = 1 Then SetLog("DARKBARRACKNUM: " & $numDarkBarracksAvaiables, $COLOR_PURPLE)
	If $numDarkBarracksAvaiables <> 0 Then
		For $i = 0 To UBound($TroopDarkName) - 1
			If $debugSetlog = 1 And Number(Floor(Eval("Cur" & $TroopDarkName[$i]) / $numBarracksAvaiables)) <> 0 Then SetLog($TroopDarkName[$i] & "EBarrack" & ": " & Floor(Eval("Cur" & $TroopDarkName[$i]) / $numBarracksAvaiables), $COLOR_PURPLE)
			Assign(($TroopDarkName[$i] & "EBarrack"), Floor(Eval("Cur" & $TroopDarkName[$i]) / $numDarkBarracksAvaiables))
		Next
	Else
		For $i = 0 To UBound($TroopDarkName) - 1
			If $debugSetlog = 1 And Number(Floor(Eval("Cur" & $TroopDarkName[$i]) / 2)) <> 0 Then SetLog($TroopDarkName[$i] & "EBarrack" & ": " & Floor(Eval("Cur" & $TroopDarkName[$i]) / 2), $COLOR_PURPLE)
			Assign(($TroopDarkName[$i] & "EBarrack"), Floor(Eval("Cur" & $TroopDarkName[$i]) / 2))
		Next
	EndIf

	;RESET TROOPFIRST AND TROOPSECOND
	For $i = 0 To UBound($TroopName) - 1
		;If $debugSetlog = 1 Then SetLog("troopFirst" & $TroopName[$i] & ": 0", $COLOR_PURPLE)
		Assign(("troopFirst" & $TroopName[$i]), 0)
		;If $debugSetlog = 1 Then SetLog("troopSecond" & $TroopName[$i] & ": 0", $COLOR_PURPLE)
		Assign(("troopSecond" & $TroopName[$i]), 0)
	Next
	For $i = 0 To UBound($TroopDarkName) - 1
		;If $debugSetlog = 1 Then SetLog("troopFirst" & $TroopDarkName[$i] & ": 0", $COLOR_PURPLE)
		Assign(("troopFirst" & $TroopDarkName[$i]), 0)
		;If $debugSetlog = 1 Then SetLog("troopSecond" & $TroopDarkName[$i] & ": 0", $COLOR_PURPLE)
		Assign(("troopSecond" & $TroopDarkName[$i]), 0)
	Next

	If $debugSetlog = 1 Then SetLog("---------END COMPUTE TROOPS TO MAKE--------------------", $COLOR_PURPLE)


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;############################################################# 3rd Stage: Training Troops ############################################################################
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	$brrNum = 0
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Train Barrack Mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	If $icmbTroopComp = 8 Then
		If $debugSetlog = 1 Then
			Setlog("", $COLOR_PURPLE)
			SetLog("---------TRAIN BARRACK MODE------------------------", $COLOR_PURPLE)
		EndIf
		If _Sleep($iDelayTrain2) Then Return
		;USE BARRACK
		While isBarrack()
			_CaptureRegion()
			If $FirstStart Then
				If _Sleep($iDelayTrain2) Then ExitLoop
				$icount = 0
				While Not _ColorCheck(_GetPixelColor(565, 205, True), Hex(0xE8E8DE, 6), 20) ; while not disappears  green arrow
					If Not (IsTrainPage()) Then Return
					Click(496, 197, 10, 0, "#0273") ; Remove Troops in training
					$icount += 1
					If $icount = 100 Then ExitLoop
				WEnd
				If $debugSetlog = 1 And $icount = 100 Then SetLog("Train warning 6")
			EndIf
			If _Sleep($iDelayTrain2) Then ExitLoop
			$brrNum += 1
			If Not (IsTrainPage()) Then Return ; exit from train if no train page
			Switch $barrackTroop[$brrNum - 1]
				Case 0
					TrainClick(220, 320, 75, 10, $FullBarb, $GemBarb, "#0274") ;Barbarian
				Case 1
					TrainClick(331, 320, 75, 10, $FullArch, $GemArch, "#0275") ;Archer
				Case 2
					TrainClick(432, 320, 15, 10, $FullGiant, $GemGiant, "#0276") ;Giant
				Case 3
					TrainClick(546, 320, 75, 10, $FullGobl, $GemGobl, "#0277") ;Goblin
				Case 4
					TrainClick(647, 320, 37, 10, $FullWall, $GemWall, "#0278") ;Wall Breaker
				Case 5
					TrainClick(220, 425, 15, 10, $FullBall, $GemBall, "#0279") ;Balloon
				Case 6
					TrainClick(331, 425, 18, 10, $FullWiza, $GemWiza, "#0280") ;Wizard
				Case 7
					TrainClick(432, 425, 5, 10, $FullHeal, $GemHeal, "#0281") ;Healer
				Case 8
					TrainClick(546, 425, 3, 10, $FullDrag, $GemDrag, "#0282") ;;Dragon
				Case 9
					TrainClick(647, 425, 3, 10, $FullPekk, $GemPekk, "#0283") ; Pekka
			EndSwitch
			If $OutOfElixir = 1 Then
				Setlog(getLocaleString("logTrainOutOfElixir"), $COLOR_RED)
				Setlog(getLocaleString("logTrainOutOfElixirHalt"), $COLOR_RED)
				$ichkBotStop = 1 ; set halt attack variable
				$icmbBotCond = 16 ; set stay online
				If CheckFullBarrack() Then $Restart = True ;If the army camp is full, use it to refill storages
				Return ; We are out of Elixir stop training.
			EndIf
			If _Sleep($iDelayTrain2) Then ExitLoop
			If Not (IsTrainPage()) Then Return
			_TrainMoveBtn(-1) ;click prev button
			If $brrNum >= $numBarracksAvaiables Then ExitLoop ; make sure no more infiniti loop
			If _Sleep($iDelayTrain3) Then ExitLoop
			;endif
		WEnd
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End Train Barrack Mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	Else
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Train Custom Army Mode For Elixir Troops ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		If $debugSetlog = 1 Then SetLog("---------TRAIN NEW BARRACK MODE------------------------")

		While isBarrack() And $isNormalBuild
			$brrNum += 1
			If $fullarmy Or $FirstStart Then
				;CLICK REMOVE TROOPS
				If _Sleep($iDelayTrain2) Then Return
				$icount = 0
				While Not _ColorCheck(_GetPixelColor(565, 205, True), Hex(0xE8E8DE, 6), 20) ; while not disappears  green arrow
					If Not (IsTrainPage()) Then Return ;exit if no train page
					Click(496, 197, 10, 0, "#0284") ; Remove Troops in training
					$icount += 1
					If $icount = 100 Then ExitLoop
				WEnd
				If $debugSetlog = 1 And $icount = 100 Then SetLog("Train warning 7", $COLOR_PURPLE)
			EndIf
			If _Sleep($iDelayTrain1) Then ExitLoop
			For $i = 0 To UBound($TroopName) - 1
				If Eval($TroopName[$i] & "Comp") <> "0" Then
					$heightTroop = 296
					$positionTroop = $TroopNamePosition[$i]
					If $TroopNamePosition[$i] > 4 Then
						$heightTroop = 404
						$positionTroop = $TroopNamePosition[$i] - 5
					EndIf
					If $debugSetlog = 1 And Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)) <> 0 Then SetLog("ASSIGN TroopFirst." & $TroopName[$i] & ": " & Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)), $COLOR_PURPLE)
					Assign(("troopFirst" & $TroopName[$i]), Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)))
					If Eval("troopFirst" & $TroopName[$i]) = 0 Then
						If _Sleep($iDelayTrain1) Then ExitLoop
						If $debugSetlog = 1 And Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)) <> 0 Then SetLog("ASSIGN TroopFirst." & $TroopName[$i] & ": " & Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)), $COLOR_PURPLE)
						Assign(("troopFirst" & $TroopName[$i]), Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)))
					EndIf
				EndIf
			Next

			;Too few troops, train first
			For $i = 0 To UBound($TroopName) - 1
				If Eval("tooFew" & $TroopName[$i]) = 1 Then
					If Not (IsTrainPage()) Then Return ;exit from train

					If $TroopName[$i] <> "Barb" And $TroopName[$i] <> "Arch" And $TroopName[$i] <> "Gobl" Then
						If Number(Eval($TroopName[$i] & "Comp")) >= 4 Then
							TrainIt(Eval("e" & $TroopName[$i]), Round(Eval($TroopName[$i] & "Comp") / $numBarracksAvaiables))
							$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
						ElseIf $brrNum <= Number(Eval($TroopName[$i] & "Comp")) Then
							TrainIt(Eval("e" & $TroopName[$i]), Ceiling(Eval($TroopName[$i] & "Comp") / $numBarracksAvaiables))
							$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
						EndIf
					Else
						TrainIt(Eval("e" & $TroopName[$i]), Round(($TotalCamp - $anotherTroops) * Eval($TroopName[$i] & "Comp") / 100 / $numBarracksAvaiables))
						$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
					EndIf

				EndIf
			Next
			;Balanced troops train in normal order
			For $i = 0 To UBound($TroopName) - 1
				If Eval($TroopName[$i] & "Comp") <> 0 And Eval("Cur" & $TroopName[$i]) > 0 Then
					If Not (IsTrainPage()) Then Return ;exit from train

					If Eval($TroopName[$i] & "EBarrack") = 0 Then
						If $debugSetlog = 1 Then SetLog("Call Func TrainIt for " & $TroopName[$i], $COLOR_PURPLE)
						TrainIt(Eval("e" & $TroopName[$i]), 1)
						$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
					ElseIf Eval($TroopName[$i] & "EBarrack") >= Eval("Cur" & $TroopName[$i]) Then
						If $debugSetlog = 1 Then SetLog("Call Func TrainIt for " & $TroopName[$i], $COLOR_PURPLE)
						TrainIt(Eval("e" & $TroopName[$i]), Eval("Cur" & $TroopName[$i]))
						$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
					Else
						If $debugSetlog = 1 Then SetLog("Call Func TrainIt for " & $TroopName[$i], $COLOR_PURPLE)
						TrainIt(Eval("e" & $TroopName[$i]), Eval($TroopName[$i] & "EBarrack"))
						$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
					EndIf
				EndIf
			Next
			;Too Many troops, train Last
			For $i = 0 To UBound($TroopName) - 1 ; put troops at end of queue if there are too many
				If Eval("tooMany" & $TroopName[$i]) = 1 Then
					If Not (IsTrainPage()) Then Return ;exit from train

					If $TroopName[$i] <> "Barb" And $TroopName[$i] <> "Arch" And $TroopName[$i] <> "Gobl" Then
						If Number(Eval($TroopName[$i] & "Comp")) >= 4 Then
							TrainIt(Eval("e" & $TroopName[$i]), Round(Eval($TroopName[$i] & "Comp") / $numBarracksAvaiables))
							$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
						ElseIf $brrNum <= Number(Eval($TroopName[$i] & "Comp")) Then
							TrainIt(Eval("e" & $TroopName[$i]), Round(Eval($TroopName[$i] & "Comp") / $numBarracksAvaiables))
							$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
						EndIf
					Else
						TrainIt(Eval("e" & $TroopName[$i]), Round(($TotalCamp - $anotherTroops) * Eval($TroopName[$i] & "Comp") / 100 / $numBarracksAvaiables))
						$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
					EndIf

				EndIf
			Next

			If _Sleep($iDelayTrain1) Then ExitLoop
			For $i = 0 To UBound($TroopName) - 1
				If Eval($TroopName[$i] & "Comp") <> "0" Then
					$heightTroop = 296
					$positionTroop = $TroopNamePosition[$i]
					If $TroopNamePosition[$i] > 4 Then
						$heightTroop = 404
						$positionTroop = $TroopNamePosition[$i] - 5
					EndIf
					If $debugSetlog = 1 And Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)) <> 0 Then SetLog(("troopSecond" & $TroopName[$i] & ": " & Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop))), $COLOR_PURPLE)
					Assign(("troopSecond" & $TroopName[$i]), Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)))
					If Eval("troopSecond" & $TroopName[$i]) = 0 Then
						If _Sleep($iDelayTrain1) Then ExitLoop
						If $debugSetlog = 1 And Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)) <> 0 Then SetLog("ASSIGN troopSecond" & $TroopName[$i] & ": " & Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)), $COLOR_PURPLE)
						Assign(("troopSecond" & $TroopName[$i]), Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)))
					EndIf
				EndIf
			Next

			$troopNameCooking = ""
			For $i = 0 To UBound($TroopName) - 1
				If Eval("troopSecond" & $TroopName[$i]) > Eval("troopFirst" & $TroopName[$i]) And Eval($TroopName[$i] & "Comp") <> "0" Then
					$ArmyComp += (Eval("troopSecond" & $TroopName[$i]) - Eval("troopFirst" & $TroopName[$i])) * $TroopHeight[$i]
					If $debugSetlog = 1 Then SetLog(("###Cur" & $TroopName[$i]) & " = " & Eval("Cur" & $TroopName[$i]) & " - (" & Eval("troopSecond" & $TroopName[$i]) & " - " & Eval("troopFirst" & $TroopName[$i]) & ")", $COLOR_PURPLE)
					Assign(("Cur" & $TroopName[$i]), Eval("Cur" & $TroopName[$i]) - (Eval("troopSecond" & $TroopName[$i]) - Eval("troopFirst" & $TroopName[$i])))
				EndIf
				If Eval("troopSecond" & $TroopName[$i]) > 0 Then
					$troopNameCooking = $troopNameCooking & $i & ";"
				EndIf
			Next

			;;;;;;; Train archers to reach full army if trained troops not enough to reach full army or remaining capacity is lower than housing space of trained troop ;;;;;;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			If $icmbTroopComp <> 8 And $fullarmy == False And $FirstStart == False Then

				; Checks if there is Troops being trained in this barrack
				If _ColorCheck(_GetPixelColor(565, 205, True), Hex(0xa8d070, 6), 20) == False Then ;if no green arrow
					$BarrackStatus[$brrNum - 1] = False ; No troop is being trained in this barrack
				Else
					$BarrackStatus[$brrNum - 1] = True ; Troops are being trained in this barrack
				EndIf
				If $debugSetlog = 1 Then SetLog("BARRACK " & $brrNum - 1 & " STATUS: " & $BarrackStatus[$brrNum - 1], $COLOR_PURPLE)

				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				;Setlog (_GetPixelColor($aBarrackFull[0], $aBarrackFull[1], True))
				; Checks if the barrack is full ( stopped )
				If CheckFullBarrack() Then
					$BarrackFull[$brrNum - 1] = True ; Barrack is full
				Else
					$BarrackFull[$brrNum - 1] = False ; Barrack isn't full
				EndIf
				If $debugSetlog = 1 Then SetLog("BARRACK " & $brrNum - 1 & " Full: " & $BarrackFull[$brrNum - 1], $COLOR_PURPLE)

				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

				; If The remaining capacity is lower than the Housing Space of training troop and its not full army or first start then delete the training troop and train 20 archer
				; If no troops are being trained in all barracks and its not full army or first start then train 20 archer to reach full army
				If ($BarrackFull[0] = True Or $BarrackStatus[0] = False) And ($BarrackFull[1] = True Or $BarrackStatus[1] = False) And ($BarrackFull[2] = True Or $BarrackStatus[2] = False) And ($BarrackFull[3] = True Or $BarrackStatus[3] = False) Then
					If (Not $isDarkBuild) Or (($BarrackDarkFull[0] = True Or $BarrackDarkStatus[0] = False) And ($BarrackDarkFull[1] = True Or $BarrackDarkStatus[1] = False)) Then
						If _Sleep($iDelayTrain1) Then Return
						ClickP($aAway, 2, $iDelayTrain5, "#0291"); Click away twice with 250ms delay
						If _Sleep($iDelayTrain4) Then Return
						Click($aArmyTrainButton[0], $aArmyTrainButton[1], 1, 0, "#0293") ; Button Army Overview
						If _Sleep($iDelayTrain1) Then Return ; wait for window to open
						If Not (IsTrainPage()) Then Return
						_CaptureRegion()
						Local $NextPos = _PixelSearch(749, 311, 787, 322, Hex(0xF08C40, 6), 5)
						Local $PrevPos = _PixelSearch(70, 311, 110, 322, Hex(0xF08C40, 6), 5)
						_TrainMoveBtn(+1)
						If _Sleep($iDelayTrain2) Then Return
						$brrNum = $numBarracksAvaiables
						While isBarrack()
							$brrNum -= 1

							If _Sleep($iDelayTrain1) Then ExitLoop
							$icount = 0
							While _ColorCheck(_GetPixelColor(565, 205, True), Hex(0xa8d070, 6), 20) ; while green arrow is there, delete
								Click(496, 197, 5, 0, "#0285") ; Remove Troops in training
								$icount += 1
								If $icount = 100 Then ExitLoop
							WEnd

							If _Sleep($iDelayTrain1) Then ExitLoop
							If $debugSetlog = 1 Then SetLog("Call Func TrainIt Arch", $COLOR_PURPLE)
							If Not (IsTrainPage()) Then Return ;exit from train
							TrainIt($eArch, 20)
							_TrainMoveBtn(+1)
							If _Sleep($iDelayTrain2) Then ExitLoop
							$BarrackFull[$brrNum] = False
							$BarrackStatus[$brrNum] = True
							If $brrNum <= 0 Then ExitLoop ; make sure no more infiniti loop
						WEnd
						If _Sleep($iDelayTrain4) Then Return
	                    ClickP($aAway, 2, $iDelayTrain5, "#0291"); Click away twice with 250ms delay
						If _Sleep($iDelayTrain4) Then Return
						Return
					EndIf
				EndIf

			EndIf
			;;;;;; End Training archers to Reach Full army ;;;;;;;;

			If Not (IsTrainPage()) Then Return
			_TrainMoveBtn(-1) ;click prev button
			If _Sleep($iDelayTrain2) Then ExitLoop
			$icount = 0
			If $debugSetlog = 1 And $icount = 10 Then SetLog("Train warning 9", $COLOR_PURPLE)
			If $brrNum >= $numBarracksAvaiables Then ExitLoop ; make sure no more infiniti loop
		WEnd
	EndIf
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;; End Train Custom Army Mode For Elixir troops ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;; Training Dark Elixir Troops here ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	If $isDarkBuild Then
		$iBarrHere = 0
		$brrDarkNum = 0
		While 1
			If Not (IsTrainPage()) Then Return
			_TrainMoveBtn(-1) ;click prev button
			$iBarrHere += 1
			If _Sleep($iDelayTrain3) Then ExitLoop
			If (isDarkBarrack() Or $iBarrHere = 5) Then ExitLoop
		WEnd
		While isDarkBarrack()
			$brrDarkNum += 1
			If $debugSetlog = 1 Then SetLog("====== Check Dark Barrack: " & $brrDarkNum & " ======", $COLOR_PURPLE)
			If StringInStr($sBotDll, "MBRPlugin.dll") < 1 Then
				ExitLoop
			EndIf
			If $fullarmy Or $FirstStart Then ; Delete Troops That is being trained
				$icount = 0
				While Not _ColorCheck(_GetPixelColor(565, 205, True), Hex(0xE8E8DE, 6), 20) ; while not disappears  green arrow
					If Not (IsTrainPage()) Then Return ;exit if no train page
					Click(496, 197, 10, 0, "#0287") ; Remove Troops in training
					$icount += 1
					If $icount = 100 Then ExitLoop
				WEnd
				If $debugSetlog = 1 And $icount = 100 Then SetLog("Train warning 9", $COLOR_PURPLE)
			EndIf

			If _Sleep($iDelayTrain1) Then ExitLoop
			For $i = 0 To UBound($TroopDarkName) - 1
				If Eval($TroopDarkName[$i] & "Comp") <> "0" Then
					$heightTroop = 296
					$positionTroop = $TroopDarkNamePosition[$i]
					If $TroopDarkNamePosition[$i] > 4 Then
						$heightTroop = 404
						$positionTroop = $TroopDarkNamePosition[$i] - 5
					EndIf

					;read troops in windows troopsfirst
					If $debugSetlog = 1 And Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)) <> 0 Then SetLog("ASSIGN TroopFirst.." & $TroopDarkName[$i] & ": " & Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)), $COLOR_PURPLE)
					Assign(("troopFirst" & $TroopDarkName[$i]), Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)))
					If Eval("troopFirst" & $TroopDarkName[$i]) = 0 Then
						If _Sleep($iDelayTrain1) Then ExitLoop
						If $debugSetlog = 1 And Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)) <> 0 Then SetLog("ASSIGN TroopFirst..." & $TroopDarkName[$i] & ": " & Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)), $COLOR_PURPLE)
						Assign(("troopFirst" & $TroopDarkName[$i]), Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)))
					EndIf
				EndIf
			Next
			;Too few troops, train first
			For $i = 0 To UBound($TroopDarkName) - 1
				If Eval("tooFew" & $TroopDarkName[$i]) = 1 Then
					If Number(Eval($TroopDarkName[$i] & "Comp")) > 2 Then
						TrainIt(Eval("e" & $TroopDarkName[$i]), Round(Eval($TroopDarkName[$i] & "Comp") / $numDarkBarracksAvaiables))
						$BarrackDarkStatus[$brrDarkNum - 1] = True ; Troops are being trained in this Dark barrack
					ElseIf $brrDarkNum <= Number(Eval($TroopDarkName[$i] & "Comp")) Then
						TrainIt(Eval("e" & $TroopDarkName[$i]), Ceiling(Eval($TroopDarkName[$i] & "Comp") / $numDarkBarracksAvaiables))
						$BarrackDarkStatus[$brrDarkNum - 1] = True ; Troops are being trained in this Dark barrack
					EndIf
				EndIf
			Next
			;Balanced troops, train in normal order
			For $i = 0 To UBound($TroopDarkName) - 1
				If $debugSetlog = 1 Then SetLog("** " & $TroopDarkName[$i] & " : " & "txtNum" & $TroopDarkName[$i] & " = " & Eval($TroopDarkName[$i] & "Comp") & "  Cur" & $TroopDarkName[$i] & " = " & Eval("Cur" & $TroopDarkName[$i]), $COLOR_PURPLE)
				If $debugSetlog = 1 Then SetLog("*** " & "txtNum" & $TroopDarkName[$i] & "=" & Eval($TroopDarkName[$i] & "Comp"), $COLOR_PURPLE)
				If $debugSetlog = 1 Then SetLog("*** " & "Cur" & $TroopDarkName[$i] & "=" & Eval("Cur" & $TroopDarkName[$i]), $COLOR_PURPLE)
				If $debugSetlog = 1 Then SetLog("*** " & $TroopDarkName[$i] & "EBarrack" & "=" & Eval("Cur" & $TroopDarkName[$i]), $COLOR_PURPLE)
				If Eval($TroopDarkName[$i] & "Comp") <> "0" And Eval("Cur" & $TroopDarkName[$i]) > 0 Then

					;If _ColorCheck(_GetPixelColor(261, 366), Hex(0x39D8E0, 6), 20) And $CurArch > 0 Then
					If Eval("Cur" & $TroopDarkName[$i]) > 0 Then
						If Not (IsTrainPage()) Then Return ;exit from train
						If Eval($TroopDarkName[$i] & "EBarrack") = 0 Then
							If $debugSetlog = 1 Then SetLog("Call Func TrainIt for " & $TroopDarkName[$i], $COLOR_PURPLE)
							TrainIt(Eval("e" & $TroopDarkName[$i]), 1)
							$BarrackDarkStatus[$brrDarkNum - 1] = True ; Troops are being trained in this Dark barrack
						ElseIf Eval($TroopDarkName[$i] & "EBarrack") >= Eval("Cur" & $TroopDarkName[$i]) Then
							If $debugSetlog = 1 Then SetLog("Call Func TrainIt for " & $TroopDarkName[$i], $COLOR_PURPLE)
							TrainIt(Eval("e" & $TroopDarkName[$i]), Eval("Cur" & $TroopDarkName[$i]))
							$BarrackDarkStatus[$brrDarkNum - 1] = True ; Troops are being trained in this Dark barrack
						Else
							If $debugSetlog = 1 Then SetLog("Call Func TrainIt for " & $TroopDarkName[$i], $COLOR_PURPLE)
							TrainIt(Eval("e" & $TroopDarkName[$i]), Eval($TroopDarkName[$i] & "EBarrack"))
							$BarrackDarkStatus[$brrDarkNum - 1] = True ; Troops are being trained in this Dark barrack
						EndIf
					EndIf
				EndIf
			Next
			;Too Many troops, train Last
			For $i = 0 To UBound($TroopDarkName) - 1 ; put troops at end of queue if there are too many
				If Eval("tooMany" & $TroopDarkName[$i]) = 1 Then
					If Number(Eval($TroopDarkName[$i] & "Comp")) > 2 Then
						TrainIt(Eval("e" & $TroopDarkName[$i]), Round(Eval($TroopDarkName[$i] & "Comp") / $numDarkBarracksAvaiables))
						$BarrackDarkStatus[$brrDarkNum - 1] = True ; Troops are being trained in this Dark barrack
					ElseIf $brrDarkNum <= Number(Eval($TroopDarkName[$i] & "Comp")) Then
						TrainIt(Eval("e" & $TroopDarkName[$i]), Ceiling(Eval($TroopDarkName[$i] & "Comp") / $numDarkBarracksAvaiables))
						$BarrackDarkStatus[$brrDarkNum - 1] = True ; Troops are being trained in this Dark barrack
					EndIf
				EndIf
			Next
			If _Sleep($iDelayTrain1) Then ExitLoop
			For $i = 0 To UBound($TroopDarkName) - 1
				If Eval($TroopDarkName[$i] & "Comp") <> "0" Then
					$heightTroop = 296
					$positionTroop = $TroopDarkNamePosition[$i]
					If $TroopDarkNamePosition[$i] > 4 Then
						$heightTroop = 404
						$positionTroop = $TroopDarkNamePosition[$i] - 5
					EndIf
					If $debugSetlog = 1 Then SetLog(">>>troopSecond" & $TroopDarkName[$i] & " = " & Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)), $COLOR_PURPLE)
					Assign(("troopSecond" & $TroopDarkName[$i]), Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)))
					If Eval("troopSecond" & $TroopDarkName[$i]) = 0 Then
						If _Sleep($iDelayTrain1) Then ExitLoop
						If $debugSetlog = 1 Then SetLog(">>>troopSecond" & $TroopDarkName[$i] & " = " & Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)), $COLOR_PURPLE)
						Assign(("troopSecond" & $TroopDarkName[$i]), Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop)))
					EndIf
				EndIf
			Next
			For $i = 0 To UBound($TroopDarkName) - 1
				If Eval("troopSecond" & $TroopDarkName[$i]) > Eval("troopFirst" & $TroopDarkName[$i]) And Eval($TroopDarkName[$i] & "Comp") <> "0" Then
					$ArmyComp += (Eval("troopSecond" & $TroopDarkName[$i]) - Eval("troopFirst" & $TroopDarkName[$i])) * $TroopDarkHeight[$i]
					If $debugSetlog = 1 Then SetLog("#Cur" & $TroopDarkName[$i] & " = " & Eval("Cur" & $TroopDarkName[$i]) & " - (" & Eval("troopSecond" & $TroopDarkName[$i]) & " - " & Eval("troopFirst" & $TroopDarkName[$i]) & ")", $COLOR_PURPLE)
					Assign(("Cur" & $TroopDarkName[$i]), Eval("Cur" & $TroopDarkName[$i]) - (Eval("troopSecond" & $TroopDarkName[$i]) - Eval("troopFirst" & $TroopDarkName[$i])))
					If $debugSetlog = 1 Then SetLog("**** " & "txtNum" & $TroopDarkName[$i] & "=" & Eval($TroopDarkName[$i] & "Comp"), $COLOR_PURPLE)
					If $debugSetlog = 1 Then SetLog("**** " & "Cur" & $TroopDarkName[$i] & "=" & Eval("Cur" & $TroopDarkName[$i]), $COLOR_PURPLE)
					If $debugSetlog = 1 Then SetLog("**** " & $TroopDarkName[$i] & "EBarrack" & "=" & Eval("Cur" & $TroopDarkName[$i]), $COLOR_PURPLE)
				EndIf
			Next

			;;;;;;; Train Minions to reach full army if trained troops not enough to reach full army or remaining capacity is lower than housing space of trained troop ;;;;;;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			If $icmbTroopComp <> 8 And $fullarmy = False And $FirstStart = False Then

				; Checks if there is Troops being trained in this Dark barrack
				If _ColorCheck(_GetPixelColor(565, 205, True), Hex(0xa8d070, 6), 20) == False Then ; If no green arrow
					$BarrackDarkStatus[$brrDarkNum - 1] = False ; No troop is being trained in this Dark barrack
				Else
					$BarrackDarkStatus[$brrDarkNum - 1] = True ; Troops are being trained in this Dark barrack
				EndIf

				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

				; Checks if the Dark barrack is full (stopped)
				If CheckFullBarrack() Then
					$BarrackDarkFull[$brrDarkNum - 1] = True ; Dark barrack is full
				Else
					$BarrackDarkFull[$brrDarkNum - 1] = False ; Dark barrack isn't full
				EndIf

				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

				;;;;;;;;;;;;; If The remaining capacity is lower then the Housing Space of training troop , delete the remaining training troop and train 10 Minions;;;;;;;;;;;
				;;;;;;;;;;;;; If no troops are being trained in all Dark barracks and its not full army or first start then train 10 Minions to reach full army;;;;;;;;;;;;;;;;
				If (Not $isNormalBuild) And (($BarrackDarkFull[0] = True Or $BarrackDarkStatus[0] = False) And ($BarrackDarkFull[1] = True Or $BarrackDarkStatus[1] = False)) Then
					While isDarkBarrack()
						$brrDarkNum -= 1
						If _Sleep($iDelayTrain1) Then ExitLoop

						$icount = 0
						While _ColorCheck(_GetPixelColor(565, 205, True), Hex(0xa8d070, 6), 20) ; While Green Arrow is there, delete
							Click(496, 197, 5, 0, "#0288")
							$icount += 1
							If $icount = 100 Then ExitLoop
						WEnd

						If _Sleep($iDelayTrain1) Then ExitLoop
						If $debugSetlog = 1 Then SetLog("Call Func TrainIt for Mini", $COLOR_PURPLE)
						If Not (IsTrainPage()) Then Return ;exit from train
						TrainIt($eMini, 10)
						_TrainMoveBtn(+1)
						If _Sleep($iDelayTrain2) Then ExitLoop
						$BarrackDarkFull[$brrDarkNum] = False
						$BarrackDarkStatus[$brrDarkNum] = True
						If $brrDarkNum <= 0 Then ExitLoop ; make sure no more infiniti loop
					WEnd
					If _Sleep($iDelayTrain4) Then Return
	                ClickP($aAway, 2, $iDelayTrain5, "#0291"); Click away twice with 250ms delay
					If _Sleep($iDelayTrain4) Then Return
					Return
				EndIf

			EndIf
			;;;;;; End Training Minions to Reach Full army ;;;;;;;;

			If Not (IsTrainPage()) Then Return
			_TrainMoveBtn(-1) ;click prev button
			If _Sleep($iDelayTrain2) Then ExitLoop
			$icount = 0
			If $brrDarkNum >= $numDarkBarracksAvaiables Then ExitLoop ; make sure no more infiniti loop
		WEnd
		;;;;;;;;;;;; End Training Dark Troops ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	EndIf
	If $debugSetlog = 1 Then SetLog("---=====================END TRAIN =======================================---", $COLOR_PURPLE)


	If _Sleep($iDelayTrain4) Then Return
	BrewSpells() ; Create Spells


	If _Sleep($iDelayTrain4) Then Return
	ClickP($aAway, 2, $iDelayTrain5, "#0291"); Click away twice with 250ms delay
	$FirstStart = False

	;;;;;; Protect Army cost stats from being missed up by DC and other errors ;;;;;;;
	If _Sleep($iDelayTrain4) Then Return
	VillageReport(True, True)

	$tempCounter = 0
	While ($iElixirCurrent = "" Or ($iDarkCurrent = "" And $iDarkStart <> "")) And $tempCounter < 30
		$tempCounter += 1
		If _Sleep(100) Then Return
		VillageReport(True, True)
	WEnd

	If $tempElixir <> "" And $iElixirCurrent <> "" Then
		$tempElixirSpent = ($tempElixir - $iElixirCurrent)
		$iTrainCostElixir += $tempElixirSpent
		$iElixirTotal -= $tempElixirSpent
	EndIf

	If $tempDElixir <> "" And $iDarkCurrent <> "" Then
		$tempDElixirSpent = ($tempDElixir - $iDarkCurrent)
		$iTrainCostDElixir += $tempDElixirSpent
		$iDarkTotal -= $tempDElixirSpent
	EndIf

	UpdateStats()

EndFunc   ;==>Train



Func IsTrainPage()

	Local $i = 0
	While $i < 30
		If _ColorCheck(_GetPixelColor(717, 120, True), Hex(0xE0070A, 6), 10) And _ColorCheck(_GetPixelColor(762, 328, True), Hex(0xF18439, 6), 10) Then ExitLoop
		_Sleep($iDelayIsTrainPage1)
		$i += 1
	WEnd
	If $i < 30 Then
		;If $DebugSetlog = 1 Then Setlog("**TrainPage OK**", $COLOR_PURPLE)
		Return True
	Else
		SetLog("Cannot find train page.", $COLOR_RED)
		Return False
	EndIf

EndFunc   ;==>IsTrainPage