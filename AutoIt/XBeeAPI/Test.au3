#include 'XbeeAPI.au3'
#include <array.au3>
#include <CommMG.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

Dim $send[98]
Dim $k
Dim $lenght = 9


$send[1] = 0x7E
$send[2] = 0x00
$send[3] = 0x04
$send[4] = 0x08
$send[5] = 0x01
$send[6] = 0x53
$send[7] = 0x4C
$send[8] = 0x57

_XbeeBegin(9, 9600)

For $k = 1 To 8
	_CommSendByte($send[$k],100)
	ConsoleWrite(Hex($send[$k],2))
Next
ConsoleWrite(@CRLF)
Sleep(500)

If _CheckIncomingFrame() Then
	ConsoleWrite("API frame received" & @CRLF)
Else
	ConsoleWrite("Don't API frame received" & @CRLF)
EndIf
_XbeeEnd()

For $k=1 To ($lenght+4)
	ConsoleWrite(Hex($responseFrameData[$k],2))
Next
ConsoleWrite(@CRLF & $responseFrameLenght & @CRLF)

If _CheckRxFrameCheckSum() Then
	ConsoleWrite("Checksum Correct" & @CRLF)
Else
	ConsoleWrite("Checksum Incorrect" & @CRLF)
EndIf

ConsoleWrite(Hex(0x0434,2))
