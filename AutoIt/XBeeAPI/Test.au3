#include 'XbeeAPI.au3'
#include <array.au3>
#include <CommMG.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

Dim $send[98]
Dim $k = 1
Dim $lenght = 9
Dim $apiframe
Dim $ack = False
Dim $data = "00,22,00,44,00,66,00,88"
_XbeeBegin(9, 9600)
_SetAddress64("00,00,00,00,00,00,00,00")
_SetAddress16("FF,FE")
#CS
;_SendRemoteATCommand("SL")
_SendZBData($data)
;_SendRemoteATCommand("SL")
;_SendATCommand("SL")
Sleep(1000)
$ack = False

$k = 1
While ((Not _CheckIncomingFrame()) And ($k < 10))
	$k += 1
	Sleep(200)
WEnd

For $k = 1 To $responseFrameLenght
	ConsoleWrite(Hex($responseFrameData[$k],2))
Next

ConsoleWrite(@CRLF)

$k = 1
While ((Not _CheckIncomingFrame()) And ($k < 10))
	$k += 1
	Sleep(200)
WEnd

For $k = 1 To $responseFrameLenght
	ConsoleWrite(Hex($responseFrameData[$k],2))
Next


While (Not $ack And $k<20)
	If _CheckIncomingFrame() Then
		ConsoleWrite("API frame received" & @CRLF)

		If _GetApiID() = $ZB_TX_STATUS_RESPONSE Then
			ConsoleWrite("DELIVERY STATUS = " & Hex(_ReadZBStatusReponseDeliveryStatus(),2) & @CRLF)

		Else
			ConsoleWrite("NO STATUS RESPONSE OBTAINED" & @CRLF)
		EndIf
		$ack = True
	EndIf
	ConsoleWrite("Don't API frame received" & @CRLF)
	$k += 1
	Sleep(1000)
WEnd


While True
	While (Not _CheckIncomingFrame())
	WEnd
	;For $k = 1 To $responseFrameLenght
	;	ConsoleWrite(Hex($responseFrameData[$k],2))
	;Next
	ConsoleWrite(_ReadZBDataResponseValue() & @CRLF)
WEnd
#ce
While True
	_SendZBData("04,34")
	Sleep(500)
	$k = 1
	While ((Not _CheckIncomingFrame()) And ($k < 10))
		$k += 1
		Sleep(400)
	WEnd

	If ($k <> 10) Then
		ConsoleWrite("API frame received" & @CRLF)

		If _GetApiID() = $ZB_TX_STATUS_RESPONSE Then
			ConsoleWrite("DELIVERY STATUS = " & Hex(_ReadZBStatusReponseDeliveryStatus(),2) & @CRLF)

		Else
			ConsoleWrite("NO STATUS RESPONSE OBTAINED" & @CRLF)
			For $k = 1 To $responseFrameLenght
				ConsoleWrite(Hex($responseFrameData[$k],2))
			Next
			ConsoleWrite(@CRLF & @CRLF)
		EndIf
	Else
		ConsoleWrite("NO API frame received" & @CRLF)

	EndIf

	$k = 1
	Sleep (1000)
WEnd

