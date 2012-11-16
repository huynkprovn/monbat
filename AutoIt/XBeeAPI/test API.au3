#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Add_Constants=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include "XbeeAPI.au3"
#include <array.au3>
#include <CommMG.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

Dim $Form, $comportA, $shA, $slA, $dlA, $dhA, $myA, $commandA, $atcomA, $valueA, $Group1, $sendA, $readA, $outputA, $outputAreset
Dim $comportB, $shB, $slB, $dlB, $dhB, $myB, $commandB, $atcomB, $valueB, $Group2, $sendB, $readB, $outputB, $outputBreset
Dim $DesA64, $DesB64, $DesA16, $DesB16
Dim $DesA64T, $DesB64T, $DesA16T, $DesB16T
Dim $DesA64check, $DesB64check, $DesA16check, $DesB16check
Dim $nMsg

;COM Vars
Global $comA, $comB				; Ports
Global $CmBoBaud = 9600			; Baud
Global $CmboDataBits =  8		; Data Bits
Global $CmBoParity = "none"		; Parity none
Global $CmBoStop = 1			; Stop
Global $setflow = 2				; Flow NONE

Global $Aconnected
Global $Bconnected

#Region ### START Koda GUI section ### ;Form=C:\Users\asus\Documents\pfc\codigo\AutoIt\Aplicacion\forms\API test.kxf
$Form = GUICreate("Formulario de pruebas API Mode", 600, 703, 588, 9)


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
$DesA64 = GUICtrlCreateInput("", 225, 32, 110, 25)
$DesA64check = GUICtrlCreateCheckbox("", 340, 32, 32, 32)
$DesA16 = GUICtrlCreateInput("", 225, 90, 110, 25)
$DesA16check = GUICtrlCreateCheckbox("", 340, 90, 32, 32)


$comportB = GUICtrlCreateCombo("", 397, 32, 75, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$shB = GUICtrlCreateLabel("      ", 397, 90, 75, 17)
$slB = GUICtrlCreateLabel("      ", 397, 147, 75, 17)
$dhB = GUICtrlCreateInput("", 397, 205, 75, 21)
$dlB = GUICtrlCreateInput("", 397, 262, 75, 21)
$myB = GUICtrlCreateInput("", 397, 320, 75, 21)
$commandB = GUICtrlCreateCombo("", 397, 376, 145, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL,$CBS_UPPERCASE))
GUICtrlSetData(-1, "AT_Command|Remote_AT_Command|ZB_Request", "AT_Command")
$atcomB = GUICtrlCreateInput("", 497, 440, 30, 21)
$valueB = GUICtrlCreateInput("", 397, 440, 75, 21)
$readB = GUICtrlCreateButton("READ", 378, 664, 75, 33)
$sendB = GUICtrlCreateButton("SEND", 493, 664, 75, 33)
$Group2 = GUICtrlCreateGroup("", 381, 8, 185, 481)
$DesB64 = GUICtrlCreateInput("", 225, 262, 110, 25)
$DesB64check = GUICtrlCreateCheckbox("", 340, 262, 32, 32)
$DesB16 = GUICtrlCreateInput("", 225, 320, 110, 25)
$DesB16check = GUICtrlCreateCheckbox("", 340, 320, 32, 32)

$outputA = GUICtrlCreateEdit("", 24, 520, 250, 120, BitOR($ES_AUTOVSCROLL,$ES_WANTRETURN,$WS_VSCROLL))
$outputB = GUICtrlCreateEdit("", 316, 520, 250, 120, BitOR($ES_AUTOVSCROLL,$ES_WANTRETURN,$WS_VSCROLL))
$outputAreset = GUICtrlCreateButton("Rst", 244, 470, 30, 30)
$outputBreset = GUICtrlCreateButton("Rst", 316, 470, 30, 30)

GUICtrlCreateLabel("COM A", 40, 16, 38, 17)
GUICtrlCreateLabel("SH", 40, 72, 19, 17)
GUICtrlCreateLabel("SL", 40, 128, 17, 17)
GUICtrlCreateLabel("DH", 40, 184, 20, 17)
GUICtrlCreateLabel("DL", 40, 248, 18, 17)
GUICtrlCreateLabel("MY", 40, 304, 20, 17)
GUICtrlCreateLabel("Command", 40, 360, 51, 17)
GUICtrlCreateLabel("COM", 140, 424, 30, 21)
GUICtrlCreateLabel("Value", 40, 424, 31, 17)
GUICtrlCreateLabel("64bits Destination Addr", 225, 16)
GUICtrlCreateLabel("16bits Destination Addr", 225, 72)

GUICtrlCreateLabel("COM B", 397, 16, 38, 17)
GUICtrlCreateLabel("SH", 397, 72, 19, 17)
GUICtrlCreateLabel("SL", 397, 128, 17, 17)
GUICtrlCreateLabel("DH", 397, 184, 20, 17)
GUICtrlCreateLabel("DL", 397, 248, 18, 17)
GUICtrlCreateLabel("MY", 397, 304, 20, 17)
GUICtrlCreateLabel("Command", 397, 360, 51, 17)
GUICtrlCreateLabel("COM", 497, 424, 30, 21)
GUICtrlCreateLabel("Value", 397, 424, 31, 17)
GUICtrlCreateLabel("64bits Destination Addr", 225, 248)
GUICtrlCreateLabel("16bits Destination Addr", 225, 304)


GUISetState(@SW_SHOW)

#EndRegion ### END Koda GUI section ###

_COMportASelect()
_COMportBSelect()
$Aconnected = False
$Bconnected = False

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

		Case $DesA64check

			If (GUICtrlRead($DesA64check) = $GUI_CHECKED) Then
				$DesA64T = GUICtrlRead($DesA64)
				GUICtrlSetData($DesA64, GUICtrlRead($shB) & GUICtrlRead($slB))
			Else
				GUICtrlSetData($DesA64, $DesA64T)
			EndIf

		Case $DesA16check

			If (GUICtrlRead($DesA16check) = $GUI_CHECKED) Then
				$DesA16T = GUICtrlRead($DesA16)
				GUICtrlSetData($DesA16, GUICtrlRead($myB))
			Else
				GUICtrlSetData($DesA16, $DesA16T)
			EndIf

		Case $DesB64check

			If (GUICtrlRead($DesB64check) = $GUI_CHECKED) Then
				$DesB64T = GUICtrlRead($DesB64)
				GUICtrlSetData($DesB64, GUICtrlRead($shA) & GUICtrlRead($slA))
			Else
				GUICtrlSetData($DesB64, $DesB64T)
			EndIf

		Case $DesB16check

			If (GUICtrlRead($DesB16check) = $GUI_CHECKED) Then
				$DesB16T = GUICtrlRead($DesB16)
				GUICtrlSetData($DesB16, GUICtrlRead($myA))
			Else
				GUICtrlSetData($DesB16, $DesB16T)
			EndIf

		Case $outputAreset
			GUICtrlSetData($outputA, "")

		Case $outputBreset
			GUICtrlSetData($outputB, "")

		Case $readA

			If (GUICtrlRead($comportA) = "" Or GUICtrlRead($comportA) = GUICtrlRead($comportB)) Then    ;Check for a valid COM Port
				MsgBox(1, "Error in COM Port selection", "Please select a different COM Port")		; to avoid hanging the script
			Else
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

			EndIf

		Case $readB

			If (GUICtrlRead($comportB) = "" Or GUICtrlRead($comportB) = GUICtrlRead($comportA)) Then 	;Check for a valid COM Port
				MsgBox(1, "Error in COM Port selection", "Please select a different COM Port")			;to avoid hanging the scrip
			Else
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

			EndIf

		Case $sendA

			_CommSwitch(1)
			Switch GUICtrlRead($commandA)

				Case "AT_Command"

					If GUICtrlRead($valueA) <> "" Then
						_SendATCommand(GUICtrlRead($atcomA),GUICtrlRead($valueA))
					Else
						_SendATCommand(GUICtrlRead($atcomA))
					EndIf
					Sleep(100)

				Case "Remote_AT_Command"

					_SetAddress64(GUICtrlRead($DesA64))
					_SetAddress16(GUICtrlRead($DesA16))

					If GUICtrlRead($valueA) <> "" Then
						_SendRemoteATCommand(GUICtrlRead($atcomA),GUICtrlRead($valueA))
					Else
						_SendRemoteATCommand(GUICtrlRead($atcomA))
					EndIf
					Sleep(100)

				Case "ZB_Request"

					_SetAddress64(GUICtrlRead($DesA64))
					_SetAddress16(GUICtrlRead($DesA16))

					_SendZBData(GUICtrlRead($valueA))


			EndSwitch


		Case $sendB

			_CommSwitch(2)
			Switch GUICtrlRead($commandB)

				Case "AT_Command"

					If GUICtrlRead($valueB) <> "" Then
						_SendATCommand(GUICtrlRead($atcomB),GUICtrlRead($valueB))
					Else
						_SendATCommand(GUICtrlRead($atcomB))
					EndIf
					Sleep(100)

				Case "Remote_AT_Command"

					_SetAddress64(GUICtrlRead($DesB64))
					_SetAddress16(GUICtrlRead($DesB16))

					If GUICtrlRead($valueB) <> "" Then
						_SendRemoteATCommand(GUICtrlRead($atcomB),GUICtrlRead($valueB))
					Else
						_SendRemoteATCommand(GUICtrlRead($atcomB))
					EndIf
					Sleep(100)

				Case "ZB_Request"

					_SetAddress64(GUICtrlRead($DesB64))
					_SetAddress16(GUICtrlRead($DesB16))

					_SendZBData(GUICtrlRead($valueB))

			EndSwitch


	EndSwitch

	If $Aconnected = True Then
		_CommSwitch(1)
		If _CheckIncomingFrame() Then
			For $k = 1 To $responseFrameLenght
				GUICtrlSetData($outputA, Hex($responseFrameData[$k],2),1)
			Next
			GUICtrlSetData($outputA, @CRLF, 1)
			GUICtrlSetData($outputA,_PrintFrame(),1)
		EndIf
	EndIf

	If $Bconnected = True Then  ; for representing modem status frame
		_CommSwitch(2)
		If _CheckIncomingFrame() Then
			For $k = 1 To $responseFrameLenght
				GUICtrlSetData($outputB, Hex($responseFrameData[$k],2),1)
			Next
			GUICtrlSetData($outputB, @CRLF, 1)
			GUICtrlSetData($outputB,_PrintFrame(),1)
		EndIf
	EndIf

WEnd

