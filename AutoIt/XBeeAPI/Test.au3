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
$remoteAddress64[0] = 0x00
$remoteAddress64[1] = 0x00
$remoteAddress64[2] = 0x00
$remoteAddress64[3] = 0x00
$remoteAddress64[4] = 0x00
$remoteAddress64[5] = 0x00
$remoteAddress64[6] = 0xFF
$remoteAddress64[7] = 0xFF
#ce

$remoteAddress64[0] = 0x00
$remoteAddress64[1] = 0x13
$remoteAddress64[2] = 0xA2
$remoteAddress64[3] = 0x00
$remoteAddress64[4] = 0x40
$remoteAddress64[5] = 0x86
$remoteAddress64[6] = 0xBF
$remoteAddress64[7] = 0x1A


$remoteAddress64[0] = 0xFF
$remoteAddress64[1] = 0xFE


_SendATCommand("SL")
;_SendZBData("07,D0")

Sleep(200)

While _CheckIncomingFrame()
	ConsoleWrite("API frame received" & @CRLF)


	For $k=1 To $responseFrameLenght
		ConsoleWrite(Hex($responseFrameData[$k],2))
	Next
	ConsoleWrite(@CRLF)
	Sleep(100)
WEnd

ConsoleWrite("Don't API frame received" & @CRLF)

_SendRemoteATCommand("ID")

Sleep(200)

While _CheckIncomingFrame()
	ConsoleWrite("API frame received" & @CRLF)


	For $k=1 To $responseFrameLenght
		ConsoleWrite(Hex($responseFrameData[$k],2))
	Next
	ConsoleWrite(@CRLF)
	Sleep(100)
WEnd

ConsoleWrite("Don't API frame received" & @CRLF)
