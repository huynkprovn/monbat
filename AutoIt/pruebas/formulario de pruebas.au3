#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         A.M.R.

 Script Function:
	Template AutoIt script.

 Date: 23/08/2012

 Version: 	0.2.1 	Add network reset command after change configuration to force modems to rejoin the network
					Add button for reset the XBee modem to factory setting.
			0.2 	Change the GUI. Read the Source Address data. Write Destination address data for
					enable direct transparent comunication between the both modem
			0.1.1 	Add Write values option
			0.1 	Conect via COM port with a Xbee modem and read ID, DH & DL parameters.

#ce ----------------------------------------------------------------------------



; INCLUDE LIBRARYS
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <commMG.au3>

; GLOBAL VARS
Global $sportSetError = '' ;Internal for the Serial UDF

;COM Vars
Global $CMPort	 				; Port
Global $CmBoBaud = 9600			; Baud
Global $CmboDataBits =  8		; Data Bits
Global $CmBoParity = "none"		; Parity none
Global $CmBoStop = 1			; Stop
Global $setflow = 2				; Flow NONE

Global $portlist 				; detected COM port list


Opt("GUIOnEventMode", 1)  ; Change to OnEvent mode


; ******** FUNCTIONS *************


; ******** MAIN ************



Local $GUIWidth = 600, $GUIHeight = 600
Local $GUIWidthSpacer = 20, $GUIHeigthSpacer = 10

Local $myGui ; main GUI handler
Local $myTab, $GeneralTab, $ConfigTab ; handlers for tab structure
Local $COMportA, $ATID_A, $ATSH_A, $ATSL_A, $ATDH_A, $ATDL_A ; for the configuration of XBee modem in AT Mode.
Local $COMportB, $ATID_B, $ATSH_B, $ATSL_B, $ATDH_B, $ATDL_B ; for the configuration of XBee modem in AT Mode.
Local $ConfOutput ; for the configuration of XBee modem in AT Mode.
Local $ConfSendButtonA, $ConfReadButtonA, $ConfSendButtonB, $ConfReadButtonB, $ConfConnectButton, $ConfModemAReset, $ConfModemBReset
Local $Sp = 5, $S = 5 ; To separate a control of each other

$myGui = GUICreate("Formulario de pruebas con ARDUINO", $GUIWidth, $GUIHeight, @DesktopWidth / 4, 20)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
$myTab = GUICtrlCreateTab( 10, 10, $GUIWidth - 20, $GUIHeight - 20)
$GeneralTab = GUICtrlCreateTabItem("General")

$ConfigTab = GUICtrlCreateTabItem("Config") ; Configurtation XBee interface tab
GUICtrlCreateLabel("COM port", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$COMportA = GUICtrlCreateCombo("", $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
;GUICtrlSetOnEvent($COMportA,"_COMportASelect")
GUICtrlCreateLabel("COM port", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$COMportB = GUICtrlCreateCombo("",$GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
;GUICtrlSetOnEvent($COMportB,"_COMportBSelect")
$Sp = $Sp + $S
GUICtrlCreateLabel("Network ID", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATID_A = GUICtrlCreateInput("", $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
GUICtrlCreateLabel("Network ID", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATID_B = GUICtrlCreateInput("", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
$Sp = $Sp + $S
GUICtrlCreateLabel("Destination Address Hight", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATDH_A = GUICtrlCreateInput("", $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
GUICtrlCreateLabel("Destination Address Hight", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATDH_B = GUICtrlCreateInput("", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
$Sp = $Sp + $S
GUICtrlCreateLabel("Destination Address Low", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATDL_A = GUICtrlCreateInput("", $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
GUICtrlCreateLabel("Destination Address Low", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATDL_B = GUICtrlCreateInput("", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
$Sp = $Sp + $S
GUICtrlCreateLabel("Source Address Hight", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATSH_A = GUICtrlCreateLabel(" ", $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
GUICtrlCreateLabel("Source Address Hight", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATSH_B = GUICtrlCreateLabel(" ", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
$Sp = $Sp + $S
GUICtrlCreateLabel("Source Address Low", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATSL_A = GUICtrlCreateLabel(" ", $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
GUICtrlCreateLabel("Source Address Low", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ATSL_B = GUICtrlCreateLabel(" ", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
$Sp = $Sp + $S + 2

$ConfOutput = GUICtrlCreateEdit("", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth - $GUIWidthSpacer * 2, ($GUIHeight - $GUIHeigthSpacer * 6) - $GUIHeigthSpacer * $Sp)

$ConfReadButtonA = GUICtrlCreateButton("Read Conf.", $GUIWidthSpacer, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 3.5)
GUICtrlSetOnEvent($ConfReadButtonA, "_CONFReadButtonAClick")
$ConfSendButtonA = GUICtrlCreateButton("Send Conf.", $GUIWidthSpacer * 5.5, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 3.5)
GUICtrlSetOnEvent($ConfSendButtonA, "_CONFSendButtonAClick")

$ConfReadButtonB = GUICtrlCreateButton("Read Conf.", $GUIWidth - $GUIWidthSpacer * 9, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 3.5)
GUICtrlSetOnEvent($ConfReadButtonB, "_CONFReadButtonBClick")
$ConfSendButtonB = GUICtrlCreateButton("Send Conf.", $GUIWidth - $GUIWidthSpacer * 4.5, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 3.5)
GUICtrlSetOnEvent($ConfSendButtonB, "_CONFSendButtonBClick")

$ConfModemAReset = GUICtrlCreateButton("Reset", $GUIWidthSpacer * 10, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 2)
GUICtrlSetOnEvent($ConfModemAReset, "_CONFModemAResetClick")
$ConfModemBReset = GUICtrlCreateButton("Reset", $GUIWidth - $GUIWidthSpacer * 12, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 2)
GUICtrlSetOnEvent($ConfModemBReset, "_CONFModemBResetClick")

$ConfConnectButton = GUICtrlCreateButton("Connect both", $GUIWidth / 2 - $GUIWidthSpacer * 2, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 4)
GUICtrlSetOnEvent($ConfConnectButton, "_CONFConnectButtonClick")

GUISetState() ; Show the main GUI

_COMportASelect()
_COMportBSelect()

while 1
	Sleep(10)
WEnd


;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CLOSEClicked ()
	MsgBox(0, "GUI Event", "You clicked CLOSE! Exiting...")
	Exit
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _COMportASelect()
	Local $pl; contador

	;MsgBox(0,"COMportAselectclick", "inside the COMportAselect click routine")
	$portlist = _CommListPorts(0) ;find the available COM ports and write them into the COMportA combo
									;$portlist[0] contain the $portlist[] lenght

	If @error = 1 Then
		MsgBox(0,'trouble getting portlist','Program will terminate!')
		Exit
	EndIf


	For $pl = 1 To $portlist[0]
		GUICtrlSetData($COMportA,$portlist[$pl]);add de list or detected COMportAs to the $COMportA combo
	Next
	;GUICtrlSetData($COMportA,$portlist[1]);show the first port found
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _COMportBSelect()
	Local $pl; contador

	;MsgBox(0,"COMportAselectclick", "inside the COMportAselect click routine")
	$portlist = _CommListPorts(0) ;find the available COM ports and write them into the COMportB combo
									;$portlist[0] contain the $portlist[] lenght

	If @error = 1 Then
		MsgBox(0,'trouble getting portlist','Program will terminate!')
		Exit
	EndIf


	For $pl = 1 To $portlist[0]
		GUICtrlSetData($COMportB,$portlist[$pl]);add de list or detected COMportAs to the $COMportA combo
	Next
	;GUICtrlSetData($COMportA,$portlist[1]);show the first port found
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CONFSendButtonAClick()

	;MsgBox(0, "Send Command to XBee modem", "Sending configuration to XBee modem")

	$CMPort = StringReplace(GUICtrlRead($COMportA),'COM','') ; Eliminate the COM caracters to the COMportA text

	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf

	;MsgBox(0, "Send Command to XBee modem", "Port COM open")

	_SendConfToXBee(GUICtrlRead($ATID_A),GUICtrlRead($ATDH_A),GUICtrlRead($ATDL_A),$ConfOutput)


	_CommClosePort()

	;MsgBox(0, "Send Command to XBee modem", "Port COM close")
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CONFSendButtonBClick()

	;MsgBox(0, "Send Command to XBee modem", "Sending configuration to XBee modem")

	$CMPort = StringReplace(GUICtrlRead($COMportB),'COM','') ; Eliminate the COM caracters to the COMportA text

	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf

	;MsgBox(0, "Send Command to XBee modem", "Port COM open")

	_SendConfToXBee(GUICtrlRead($ATID_B),GUICtrlRead($ATDH_B),GUICtrlRead($ATDL_B),$ConfOutput)


	_CommClosePort()

	;MsgBox(0, "Send Command to XBee modem", "Port COM close")
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CONFReadButtonAClick()
	Local $tempString ; For display de command send to the XBee Modem and his response
	Local $readString ; Response from XBee modem to the sent AT Command

	;MsgBox(0, "Send Command to XBee modem", "Read configuration from XBee modem")

	$CMPort = StringReplace(GUICtrlRead($COMportA),'COM','') ; Eliminate the COM caracters to the COMportA text

	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf

	;MsgBox(0, "Send Command to XBee modem", "Port COM open")

	$tempString = "Opening AT Command mode"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfEnterATMode($ConfOutput)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & "Error entering AT Mode"
		Return -1
	Else
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $ConfOutput, $tempString)


	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Network ID"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATID", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATID_A, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Destination Address Hight bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATDH", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATDH_A, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Destination Address Low bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATDL", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATDL_A, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Source Address Hight bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATSH", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATSH_A, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Source Address Low bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATSL", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATSL_A, $readString)

	_CommClosePort()

	;MsgBox(0, "Send Command to XBee modem", "Port COM close")
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CONFReadButtonBClick()
Local $tempString ; For display de command send to the XBee Modem and his response
	Local $readString ; Response from XBee modem to the sent AT Command

	;MsgBox(0, "Send Command to XBee modem", "Read configuration from XBee modem")

	$CMPort = StringReplace(GUICtrlRead($COMportB),'COM','') ; Eliminate the COM caracters to the COMportA text

	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf

	;MsgBox(0, "Send Command to XBee modem", "Port COM open")

	$tempString = "Opening AT Command mode"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfEnterATMode($ConfOutput)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & "Error entering AT Mode"
		Return -1
	Else
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $ConfOutput, $tempString)


	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Network ID"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATID", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATID_B, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Destination Address Hight bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATDH", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATDH_B, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Destination Address Low bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATDL", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATDL_B, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Source Address Hight bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATSH", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATSH_B, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Source Address Low bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfGetData("ATSL", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATSL_B, $readString)

	_CommClosePort()

	;MsgBox(0, "Send Command to XBee modem", "Port COM close")
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CONFConnectButtonClick()

	;write in Destiny addres of modem conected to PortB the Source Addres of modem conected to PortA
	$CMPort = StringReplace(GUICtrlRead($COMportB),'COM','') ; Eliminate the COM caracters to the COMportA text
	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf
	;MsgBox(0, "Send Command to XBee modem", "Port COM open")
	_SendConfToXBee(GUICtrlRead($ATID_A),GUICtrlRead($ATSH_A),GUICtrlRead($ATSL_A),$ConfOutput)
	_CommClosePort()

	;write in Destiny addres of modem conected to PortA the Source Addres of modem conected to PortB
	$CMPort = StringReplace(GUICtrlRead($COMportA),'COM','') ; Eliminate the COM caracters to the COMportA text
	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf
	;MsgBox(0, "Send Command to XBee modem", "Port COM open")
	_SendConfToXBee(GUICtrlRead($ATID_A),GUICtrlRead($ATSH_B),GUICtrlRead($ATSL_B),$ConfOutput)
	_CommClosePort()

	_CONFReadButtonAClick()
	_CONFReadButtonBClick()

EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CONFModemAResetClick()
	Local $tempString ; For display de command send to the XBee Modem and his response
	Local $readString ; Response from XBee modem to the sent AT Command

	$CMPort = StringReplace(GUICtrlRead($COMportA),'COM','') ; Eliminate the COM caracters to the COMportA text

	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf

	$tempString = "Opening AT Command mode"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfEnterATMode($ConfOutput)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & "Error entering AT Mode"
		Return -1
	Else
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $ConfOutput, $tempString)

	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Setting Modem A to factory defaults"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATRE"
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATRE" & @CR)    ; send the factory default command to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & "Error sending factory defaults command"
		Return -1
	Else
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $ConfOutput, $tempString)

	_ConfExitATMode($ConfOutput)

	_CommClosePort()

EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CONFModemBResetClick()
	Local $tempString ; For display de command send to the XBee Modem and his response
	Local $readString ; Response from XBee modem to the sent AT Command

	$CMPort = StringReplace(GUICtrlRead($COMportB),'COM','') ; Eliminate the COM caracters to the COMportA text

	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf

	$tempString = "Opening AT Command mode"
	GUICtrlSetData( $ConfOutput, $tempString)
	$readString = _ConfEnterATMode($ConfOutput)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & "Error entering AT Mode"
		Return -1
	Else
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $ConfOutput, $tempString)

	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Setting Modem B to factory defaults"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATRE"
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATRE" & @CR)    ; send the factory default command to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & "Error sending factory defaults command"
		Return -1
	Else
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $ConfOutput, $tempString)

	_ConfExitATMode($ConfOutput)

	_CommClosePort()
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _SendConfToXBee($ID, $DH, $DL, $Output)
	Local $tempString ; For display de command send to the XBee Modem and his response
	Local $readString ; Response from XBee modem to the sent AT Command


	$tempString = "Opening AT Command mode"
	GUICtrlSetData( $Output, $tempString)
	$readString = _ConfEnterATMode($Output)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & "Error entering AT Mode"
		Return -1
	Else
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $Output, $tempString)

	$tempString = GUICtrlRead($Output) & @CRLF & "Assingning Network ID"
	GUICtrlSetData( $Output, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "ATID " & GUICtrlRead($ID)
	GUICtrlSetData( $Output, $tempString)
	_CommSendString("ATID " & $ID & @CR)    ; send the ID to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & "Error assinging Network ID"
		Return -1
	Else
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $Output, $tempString)

	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "Assingning Destination Address Hight bytes"
	GUICtrlSetData( $Output, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "ATDH " & GUICtrlRead($DH)
	GUICtrlSetData( $Output, $tempString)
	_CommSendString("ATDH " & $DH & @CR)    ; send the Destination Address Hight bytes to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & "Error assinging Destination Address Hight bytes"
		Return -1
	Else
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $Output, $tempString)

	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "Assingning Destination Address Low bytes"
	GUICtrlSetData( $Output, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "ATDL " & GUICtrlRead($DL)
	GUICtrlSetData( $Output, $tempString)
	_CommSendString("ATDL " & $DL & @CR)    ; send the Destination Address Low bytes to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & "Error assinging Destination Address Low bytes"
		Return -1
	Else
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $Output, $tempString)

	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "Writing data in Memory"
	GUICtrlSetData( $Output, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "ATWR"
	GUICtrlSetData( $Output, $tempString)
	_CommSendString("ATWR" & @CR)    ; send the write data to memory command
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & "Error writing data to Memory"
		MsgBox(0,"Error...","Error writing data to memoty in XBee modem. Actual data will overwrite on next Modem restart")
		Return -1
	Else
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $Output, $tempString)

	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "Force to rebuilt networking"
	GUICtrlSetData( $Output, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "ATNR"
	GUICtrlSetData( $Output, $tempString)
	_CommSendString("ATNR" & @CR)    ; send the write data to memory command
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & "Error forcing to rebuilt networking"
		Return -1
	Else
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $Output, $tempString)

	_ConfExitATMode($Output)

EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _ConfEnterATMode($Output)
	Local $tempString ; For display de command send to the XBee Modem and his response
	Local $readString ; Response from XBee modem to the sent AT Command

	Sleep(1000)  ; wait 1 second. Necesary 1 second idle to enter in AT Mode.
	$tempString = GUICtrlRead($Output) & @CRLF & "+++"
	GUICtrlSetData( $Output, $tempString)
	_CommSendString("+++")
	Sleep(1000)   ; Necesary for entering in AT Command mode.
	$readString = _CommGetLine(@CR,10,400)
	;$tempString = GUICtrlRead($Output) & @CRLF & "          " & $readString
	;GUICtrlSetData( $Output, $tempString)
	Return $readString
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _ConfExitATMode($Output)
	Local $tempString ; For display de command send to the XBee Modem and his response
	Local $readString ; Response from XBee modem to the sent AT Command

	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "Exit Command Mode"
	GUICtrlSetData( $Output, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($Output) & @CRLF & "ATCN"
	GUICtrlSetData( $Output, $tempString)
	_CommSendString("ATCN" & @CR)    ; send the write data to memory command
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & "Error while exiting command mode"
		Return -1
	Else
		$tempString = GUICtrlRead($Output) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $Output, $tempString)
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _ConfGetData($command, $Output)
	Local $tempString ; For display de command send to the XBee Modem and his response
	Local $readString ; Response from XBee modem to the sent AT Command

	$tempString = GUICtrlRead($Output) & @CRLF & $command
	GUICtrlSetData( $Output, $tempString)
	Sleep(100)
	_CommSendString( $command & @CR)    ; Request the ID to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $Output, $tempString)
	Return $readString
EndFunc
