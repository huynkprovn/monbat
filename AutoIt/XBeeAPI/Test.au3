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

_XbeeBegin(9, 9600)
_SetAddress64("00,13,A2,00,40,86,BF,1A")
_SetAddress16("FF,FE")

_SendRemoteATCommand("ID")

Sleep(200)
$ack = False
While ($ack Or $k>20)
	If _CheckIncomingFrame() Then
		ConsoleWrite("API frame received" & @CRLF)

		If _GetApiID() = $ZB_TX_STATUS_RESPONSE Then
			ConsoleWrite("DELIVERY STATUS = " & Hex(_ReadZBStatusReponseDeliveryStatus(),2) & @CRLF)
			$ack = True
		Else
			ConsoleWrite("NO STATUS RESPONSE OBTAINED" & @CRLF)
		EndIf
	EndIf
	ConsoleWrite("Don't API frame received" & @CRLF)
	$k += 1
	Sleep(1000)
WEnd