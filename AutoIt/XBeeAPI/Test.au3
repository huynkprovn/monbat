#include 'XbeeAPI.au3'
#include <array.au3>
#include <CommMG.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

Dim $send[98]
Dim $k
Dim $lenght = 9
Dim $apiframe

_XbeeBegin(9, 9600)



#cs
$requestFrameData[1] = 0x7E    ; ATSH command
$requestFrameData[2] = 0x00
$requestFrameData[3] = 0x04
$requestFrameData[4] = 0x08
$requestFrameData[5] = 0x01
$requestFrameData[6] = 0x53
$requestFrameData[7] = 0x48
$requestFrameData[8] = 0x5B

$requestFrameLenght = 8

_SendTxFrame()


$send[1] = 0x7E
$send[2] = 0x00
$send[3] = 0x04
$send[4] = 0x08
$send[5] = 0x01
$send[6] = 0x53
$send[7] = 0x4C
$send[8] = 0x57


For $k = 1 To 8
	_CommSendByte($send[$k],100)
	ConsoleWrite(Hex($send[$k],2))
Next
ConsoleWrite(@CRLF)
Sleep(500)
#ce


_SendATCommand("SH")

Sleep(200)


If _CheckIncomingFrame() Then
	ConsoleWrite("API frame received" & @CRLF)
Else
	ConsoleWrite("Don't API frame received" & @CRLF)
EndIf

For $k=1 To $responseFrameLenght
	ConsoleWrite(Hex($responseFrameData[$k],2))
Next
ConsoleWrite(@CRLF)

If	_GetApiID() = $AT_RESPONSE Then
	ConsoleWrite(_ReadATCommandResponseValue())
EndIf

_XbeeEnd()

#cs
For $k=1 To $responseFrameLenght
	ConsoleWrite(Hex($responseFrameData[$k],2))
Next
ConsoleWrite(@CRLF & $responseFrameLenght & @CRLF)

$apiframe = _GetApiID()
ConsoleWrite( Hex($apiframe,2) & @CRLF)


If _CheckRxFrameCheckSum() Then
	ConsoleWrite("Checksum Correct" & @CRLF)
Else
	ConsoleWrite("Checksum Incorrect" & @CRLF)
EndIf

ConsoleWrite(Hex(0x0434,2))
#ce
