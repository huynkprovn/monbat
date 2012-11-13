#include 'XbeeAPI.au3'
#include <array.au3>
#include <CommMG.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

Dim $Form, $comportA, $shA, $slA, $dlA, $dhA, $myA, $commandA, $atcomA, $valueA, $Group1, $sendA, $readA, $outputA
Dim $comportB, $shB, $slB, $dlB, $dhB, $myB, $commandB, $atcomB, $valueB, $Group2, $sendB, $readB, $outputB
Dim $nMsg

;COM Vars
Global $comA, $comB				; Ports
Global $CmBoBaud = 9600			; Baud
Global $CmboDataBits =  8		; Data Bits
Global $CmBoParity = "none"		; Parity none
Global $CmBoStop = 1			; Stop
Global $setflow = 2				; Flow NONE


#Region ### START Koda GUI section ### Form=C:\Users\asus\Documents\pfc\codigo\AutoIt\Aplicacion\forms\API test.kxf
$Form = GUICreate("Formulario de pruebas API Mode", 469, 703, 588, 9)

$comportA = GUICtrlCreateCombo("", 40, 32, 75, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$shA = GUICtrlCreateLabel("      ", 40, 90, 75, 17)
$slA = GUICtrlCreateLabel("      ", 40, 147, 75, 17)
$dhA = GUICtrlCreateInput("", 40, 205, 75, 21)
$dlA = GUICtrlCreateInput("", 40, 262, 75, 21)
$myA = GUICtrlCreateInput("", 40, 320, 75, 21)
$commandA = GUICtrlCreateCombo("", 40, 376, 145, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL,$CBS_UPPERCASE))
GUICtrlSetData(-1, "AT_Command|Remote_AT_Command|ZB_Request", "AT_Command")
$atcomA = GUICtrlCreateInput("", 140, 440, 30, 21)
$valueA = GUICtrlCreateInput("", 40, 440, 75, 21)
$readA = GUICtrlCreateButton("READ", 24, 664, 75, 33)
$sendA = GUICtrlCreateButton("SEND", 139, 664, 75, 33)
$Group1 = GUICtrlCreateGroup("", 24, 8, 185, 481)

$comportB = GUICtrlCreateCombo("", 272, 32, 75, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$shB = GUICtrlCreateLabel("      ", 272, 90, 75, 17)
$slB = GUICtrlCreateLabel("      ", 272, 147, 75, 17)
$dhB = GUICtrlCreateInput("", 272, 205, 75, 21)
$dlB = GUICtrlCreateInput("", 272, 262, 75, 21)
$myB = GUICtrlCreateInput("", 272, 320, 75, 21)
$commandB = GUICtrlCreateCombo("", 272, 376, 145, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL,$CBS_UPPERCASE))
GUICtrlSetData(-1, "AT_Command|Remote_AT_Command|ZB_Request", "AT_Command")
$atcomB = GUICtrlCreateInput("", 372, 440, 30, 21)
$valueB = GUICtrlCreateInput("", 272, 440, 75, 21)
$readB = GUICtrlCreateButton("READ", 253, 664, 75, 33)
$sendB = GUICtrlCreateButton("SEND", 368, 664, 75, 33)
$Group2 = GUICtrlCreateGroup("", 256, 8, 185, 481)

$outputA = GUICtrlCreateEdit("", 24, 520, 185, 120, BitOR($ES_AUTOVSCROLL,$ES_WANTRETURN,$WS_VSCROLL))
$outputB = GUICtrlCreateEdit("", 256, 520, 185, 120, BitOR($ES_AUTOVSCROLL,$ES_WANTRETURN,$WS_VSCROLL))

GUICtrlCreateLabel("COM A", 40, 16, 38, 17)
GUICtrlCreateLabel("SH", 40, 72, 19, 17)
GUICtrlCreateLabel("SL", 40, 128, 17, 17)
GUICtrlCreateLabel("DH", 40, 184, 20, 17)
GUICtrlCreateLabel("DL", 40, 248, 18, 17)
GUICtrlCreateLabel("MY", 40, 304, 20, 17)
GUICtrlCreateLabel("Command", 40, 360, 51, 17)
GUICtrlCreateLabel("COM", 140, 424, 30, 21)
GUICtrlCreateLabel("Value", 40, 424, 31, 17)

GUICtrlCreateLabel("COM B", 272, 16, 38, 17)
GUICtrlCreateLabel("SH", 272, 72, 19, 17)
GUICtrlCreateLabel("SL", 272, 128, 17, 17)
GUICtrlCreateLabel("DH", 272, 184, 20, 17)
GUICtrlCreateLabel("DL", 272, 248, 18, 17)
GUICtrlCreateLabel("MY", 272, 304, 20, 17)
GUICtrlCreateLabel("Command", 272, 360, 51, 17)
GUICtrlCreateLabel("COM", 372, 424, 30, 21)
GUICtrlCreateLabel("Value", 272, 424, 31, 17)


GUISetState(@SW_SHOW)

#EndRegion ### END Koda GUI section ###

_COMportASelect()
_COMportBSelect()

Func _COMportASelect()
	Local $pl; contador
	Local $portlist

	$portlist = _CommListPorts(0) ;find the available COM ports and write them into the COMportA combo
									;$portlist[0] contain the $portlist[] lenght

	If @error = 1 Then
		MsgBox(0,'trouble getting portlist','Program will terminate!')
		Exit
	EndIf

	For $pl = 1 To $portlist[0]
		GUICtrlSetData($comportA,$portlist[$pl]);add de list or detected COMportAs to the $COMportA combo
	Next
EndFunc

Func _COMportBSelect()
	Local $pl; contador
	Local $portlist

	$portlist = _CommListPorts(0) ;find the available COM ports and write them into the COMportB combo
									;$portlist[0] contain the $portlist[] lenght

	If @error = 1 Then
		MsgBox(0,'trouble getting portlist','Program will terminate!')
		Exit
	EndIf

	For $pl = 1 To $portlist[0]
		GUICtrlSetData($comportB,$portlist[$pl]);add de list or detected COMportAs to the $COMportA combo
	Next
EndFunc


While 1
	Local $Aconnected = False
	Local $Bconnected = False
	Local $k ; to wait for xbee response
	Local $j ; times to retry a at_command read
	Local $read ; boolean. The parameter is read
	Local $er ; error reading a at_command

	$nMsg = GUIGetMsg()
	Switch $nMsg

		Case $GUI_EVENT_CLOSE
			_CommSwitch(1)
			_CommClosePort()
			_CommSwitch(2)
			_CommClosePort()
			Exit

		Case $readA
			$er = False
			_CommSwitch(1)
			$comA = StringReplace(GUICtrlRead($comportA),'COM','') ; Eliminate the COM caracters to the COMportA text
			_CommSetPort($comA, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow) ; Open the port

			$Aconnected = True ; mark the comA port opened

			$read = False
			$j = 1
			While (Not $read And Not $er)
				_SendATCommand("SH")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($shA, _ReadATCommandResponseValue())
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputA, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputA, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

			$read = False
			$j = 1
			While (Not $read And Not $er)
				_SendATCommand("SL")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($slA, _ReadATCommandResponseValue())
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputA, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputA, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

			$read = False
			$j = 1
			While (Not $read And Not $er)
				_SendATCommand("DH")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($dhA, _ReadATCommandResponseValue())
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputA, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputA, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

			$read = False
			$j = 1
			While (Not $read And Not $er)
				_SendATCommand("DL")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($dlA, _ReadATCommandResponseValue())
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputA, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputA, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

			$read = False
			$j = 1
			While (Not $read And Not $er)
				_SendATCommand("MY")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($myA, _ReadATCommandResponseValue())
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputA, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputA, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

		Case $readB
			$er = False
			_CommSwitch(2)
			$comB = StringReplace(GUICtrlRead($comportB),'COM','') ; Eliminate the COM caracters to the COMportA text
			_CommSetPort($comB, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow) ; Open the port

			$Bconnected = True ; mark the comB port opened

			$read = False
			$j = 1
			$k = 1
			While (Not $read And Not $er)
				_SendATCommand("SH")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($shB, _ReadATCommandResponseValue())
					GUICtrlSetData($outputB, $responseFrameData, 1)
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputB, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputB, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

			$read = False
			$j = 1
			$k = 1
			While (Not $read And Not $er)
				_SendATCommand("SL")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($slB, _ReadATCommandResponseValue())
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputB, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputB, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

			$read = False
			$j = 1
			$k = 1
			While (Not $read And Not $er)
				_SendATCommand("DH")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($dhB, _ReadATCommandResponseValue())
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputB, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputB, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

			$read = False
			$j = 1
			$k = 1
			While (Not $read And Not $er)
				_SendATCommand("DL")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($dlB, _ReadATCommandResponseValue())
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputB, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputB, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

			$read = False
			$j = 1
			$k = 1
			While (Not $read And Not $er)
				_SendATCommand("MY")
				Sleep(100)
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(100)
				WEnd

				If $k <> 10 And _GetApiID() = $AT_RESPONSE Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																	  ; hay una trama tipo $AT_RESPONSE
					GUICtrlSetData($myB, _ReadATCommandResponseValue())
					For $k = 1 To $responseFrameLenght
						GUICtrlSetData($outputB, Hex($responseFrameData[$k],2),1)
					Next
					GUICtrlSetData($outputB, @CRLF, 1)
					$read = True
				EndIf

				If $j = 3 Then
					$er = True
				EndIf
				$j += 1
			WEnd

		Case $sendA

			_CommSwitch(1)
			Switch GUICtrlRead($commandA)

				Case "AT_Command"
					$read = False
					$j = 1
					$k = 1
					While (Not $read And Not $er)

						If GUICtrlRead($valueA) <> "" Then
							_SendATCommand(GUICtrlRead($atcomA),GUICtrlRead($valueA))
						Else
							_SendATCommand(GUICtrlRead($atcomA))
						EndIf
						Sleep(100)

						While ((Not _CheckIncomingFrame()) And ($k < 10))
							$k += 1
							Sleep(100)
						WEnd

						If $k <> 10 Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																			; hay una trama
							For $k = 1 To $responseFrameLenght
								GUICtrlSetData($outputA, Hex($responseFrameData[$k],2),1)
							Next
							GUICtrlSetData($outputA, @CRLF, 1)
							$read = True
						EndIf

						If $j = 3 Then
							$er = True
						EndIf
						$j += 1
					WEnd

				Case "Remote_AT_Command"

				Case "ZB_Request"

			EndSwitch


		Case $sendB

			_CommSwitch(2)
			Switch GUICtrlRead($commandB)

				Case "AT_Command"

					$read = False
					$j = 1
					$k = 1
					While (Not $read And Not $er)

						If GUICtrlRead($valueB) <> "" Then
							_SendATCommand(GUICtrlRead($atcomB),GUICtrlRead($valueB))
						Else
							_SendATCommand(GUICtrlRead($atcomB))
						EndIf
						Sleep(100)

						While ((Not _CheckIncomingFrame()) And ($k < 10))
							$k += 1
							Sleep(100)
						WEnd

						If $k <> 10 Then       ; Si en la sentencia anterior no se ha agotado el tiempo y
																			; hay una trama
							For $k = 1 To $responseFrameLenght
								GUICtrlSetData($outputB, Hex($responseFrameData[$k],2),1)
							Next
							GUICtrlSetData($outputB, @CRLF, 1)
							$read = True
						EndIf

						If $j = 3 Then
							$er = True
						EndIf
						$j += 1
					WEnd


				Case "Remote_AT_Command"

				Case "ZB_Request"

			EndSwitch


	EndSwitch

	If $Aconnected Then
		_CommSwitch(1)
		If _CheckIncomingFrame() Then
			For $k = 1 To $responseFrameLenght
				GUICtrlSetData($outputA, Hex($responseFrameData[$k],2),1)
			Next
			GUICtrlSetData($outputA, @CRLF, 1)
		EndIf
	EndIf

	If $Bconnected Then  ; for representing modem status frame
		_CommSwitch(2)
		If _CheckIncomingFrame() Then
			For $k = 1 To $responseFrameLenght
				GUICtrlSetData($outputB, Hex($responseFrameData[$k],2),1)
			Next
			GUICtrlSetData($outputB, @CRLF, 1)
		EndIf
	EndIf

WEnd
