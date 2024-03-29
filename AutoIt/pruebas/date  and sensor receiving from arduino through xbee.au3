#include <XbeeAPI.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiStatusBar.au3>
#include <WindowsConstants.au3>
#include <Date.au3>
#include <ComboConstants.au3>



Global $Form1, $Input1, $Button1, $Edit1, $StatusBar1
Global $com = 9
Global $CmBoBaud = 9600			; Baud
Global $CmboDataBits =  8		; Data Bits
Global $CmBoParity = "none"		; Parity none
Global $CmBoStop = 1			; Stop
Global $setflow = 2				; Flow NONE

Dim $sNewDate, $Date

#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Form1", 661, 600, 192, 124)

;$commandB = GUICtrlCreateCombo("", 397, 376, 145, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL,$CBS_UPPERCASE))

$Input1 = GUICtrlCreateCombo("", 48, 24, 137, 21, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL,$CBS_UPPERCASE))
GUICtrlSetData(-1, "GET_ID|RESET_ALARMS|SET_TRUCK_MODEL|SET_TRUCK_SN|SET_BATT_MODEL|SET_BATT_SN|CALIBRATE|SET_TIME|READ_MEMORY|EXIT|RESET_MEM", "READ_MEMORY")

$Button1 = GUICtrlCreateButton("Send", 432, 24, 129, 25)
$Edit1 = GUICtrlCreateEdit("", 16, 64, 625, 490, BitOR($ES_AUTOVSCROLL,$ES_AUTOHSCROLL,$ES_WANTRETURN,$WS_VSCROLL))
$StatusBar1 = _GUICtrlStatusBar_Create($Form1)
_GUICtrlStatusBar_SetMinHeight($StatusBar1, 17)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

;_CommSetPort($com, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow) ; Open the port

Dim $nMsg
Dim $dato

Func _convert_r($dato)
	Local $k
	Local $res
	Local $d
	Local $long = StringLen($dato)/2

	For $k=1 To $long
		$d = StringMid($dato,$long*2 - ($k*2-1),2) ;Extract byte by byte in reverse order
		$res += Dec($d)*255^($k - 1)     ; Convert to a decimal data
	Next
	Return $res
EndFunc

Func _convert($dato)
	Local $k
	Local $res
	Local $d
	Local $long = StringLen($dato)/2

	For $k=1 To $long
		$d = StringMid($dato,$k*2-1,2) ;Extract byte by byte
		$res += Dec($d)*255^($k - 1)     ; Convert to a decimal data
	Next
	Return $res
EndFunc

While 1


	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			_CommClosePort()
			Exit

		Case $Button1

			_SetAddress64(GUICtrlRead($Input1))
			_SetAddress16("FFFE")
			_SendZBData("00")       ; Send anything. Arduino only expect a RX data Api Frame.
	EndSwitch

	If _CheckIncomingFrame() Then
		If _GetApiID() == $ZB_RX_RESPONSE Then

			;GUICtrlSetData($Edit1, @CRLF, 1)
			;GUICtrlSetData($Edit1,_PrintFrame(),1)
			$dato = _ReadZBDataResponseValue()
			;GUICtrlSetData($Edit1, $dato & @CRLF,1)
			$Date = _convert(StringMid($dato, 1, 8))
			ConsoleWrite($Date & @CRLF)
			$sNewDate = _DateAdd('s', $Date, "1970/01/01 00:00:00")
			GUICtrlSetData($Edit1, "Date: " & $sNewDate & " , V+: " & StringMid($dato,9, 4) & " , V-: " & StringMid($dato,13, 4), 1)
			GUICtrlSetData($Edit1, " , A: " & StringMid($dato,17, 4) & " , T: " & StringMid($dato,21, 4) & " , T: " & StringMid($dato,25, 2) & @CRLF, 1)
	 	EndIf
	EndIf
WEnd
