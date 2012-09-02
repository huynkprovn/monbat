#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         A.M.R.

 Script Function:
	Template AutoIt script.

 Date: 23/08/2012

 Version: 	0.2.2	Remove $tempChar necesity
			0.2.1 	Add network reset command after change configuration to force modems to rejoin the network
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



Global $GUIWidth = 600, $GUIHeight = 600
Global $GUIWidthSpacer = 20, $GUIHeigthSpacer = 10

Global $myGui ; main GUI handler
Global $myTab, $GeneralTab, $ConfigTab, $ChatTab ; handlers for tab structure
Global $COMportA, $ATID_A, $ATSH_A, $ATSL_A, $ATDH_A, $ATDL_A ; for the configuration of XBee modem in AT Mode.
Global $COMportB, $ATID_B, $ATSH_B, $ATSL_B, $ATDH_B, $ATDL_B ; for the configuration of XBee modem in AT Mode.
Global $ConfOutput ; for the configuration of XBee modem in AT Mode.
Global $ConfSendButtonA, $ConfReadButtonA, $ConfSendButtonB, $ConfReadButtonB, $ConfConnectButton, $ConfModemAReset, $ConfModemBReset
Global $Sp = 5, $S = 5 ; To separate a control of each other

Global $ChatCOMportA, $ChatCOMportB ;


$myGui = GUICreate("Formulario de pruebas con ARDUINO", $GUIWidth, $GUIHeight, @DesktopWidth / 4, 20)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
$myTab = GUICtrlCreateTab( 10, 10, $GUIWidth - 20, $GUIHeight - 20)
$GeneralTab = GUICtrlCreateTabItem("General")

;***************************************************************************************************
;
;
;***************************************************************************************************
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

;***************************************************************************************************
;
;
;***************************************************************************************************
$ChatTab = GUICtrlCreateTabItem("Chat") ; XBee Chat tab
$Sp = 5
GUICtrlCreateLabel("COM port", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ChatCOMportA = GUICtrlCreateCombo("", $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
;GUICtrlSetOnEvent($COMportA,"_COMportASelect")
GUICtrlCreateLabel("COM port", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$ChatCOMportB = GUICtrlCreateCombo("",$GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
;GUICtrlSetOnEvent($COMportB,"_COMportBSelect")


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

	GUICtrlSetData( $ConfOutput, "Opening AT Command mode")
	$readString = _ConfEnterATMode($ConfOutput)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & "Error entering AT Mode",1)
		Return -1
	Else
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & $readString,1)
	EndIf

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Network ID",1)
	$readString = _ConfGetData("ATID", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATID_A, $readString)

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Destination Address Hight bytes",1)
	$readString = _ConfGetData("ATDH", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATDH_A, $readString)

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Destination Address Low bytes",1)
	$readString = _ConfGetData("ATDL", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATDL_A, $readString)

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Source Address Hight bytes",1)
	$readString = _ConfGetData("ATSH", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATSH_A, $readString)

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Source Address Low bytes",1)
	$readString = _ConfGetData("ATSL", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATSL_A, $readString)

	_ConfExitATMode($ConfOutput)
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
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & "Error entering AT Mode",1)
		Return -1
	Else
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & $readString,1)
	EndIf

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Network ID",1)
	$readString = _ConfGetData("ATID", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATID_B, $readString)

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Destination Address Hight bytes",1)
	$readString = _ConfGetData("ATDH", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATDH_B, $readString)

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Destination Address Low bytes",1)
	$readString = _ConfGetData("ATDL", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATDL_B, $readString)

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Source Address Hight bytes",1)
	$readString = _ConfGetData("ATSH", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATSH_B, $readString)

	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "Getting Source Address Low bytes",1)
	$readString = _ConfGetData("ATSL", $ConfOutput)
	Sleep(100)
	GUICtrlSetData($ATSL_B, $readString)

	_ConfExitATMode($ConfOutput)
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

	GUICtrlSetData( $ConfOutput, "Opening AT Command mode")
	$readString = _ConfEnterATMode($ConfOutput)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & "Error entering AT Mode",1)
		Return -1
	Else
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & $readString,1)
	EndIf

	GUICtrlSetData( $ConfOutput, @CRLF & "Setting Modem A to factory defaults",1)
	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "ATRE",1)
	_CommSendString("ATRE" & @CR)    ; send the factory default command to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & "Error sending factory defaults command",1)
		Return -1
	Else
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & $readString,1)
	EndIf

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

	GUICtrlSetData( $ConfOutput, "Opening AT Command mode")
	$readString = _ConfEnterATMode($ConfOutput)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & "Error entering AT Mode",1)
		Return -1
	Else
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & $readString,1)
	EndIf

	GUICtrlSetData( $ConfOutput, @CRLF & "Setting Modem B to factory defaults",1)
	Sleep(100)
	GUICtrlSetData( $ConfOutput, @CRLF & "ATRE",1)
	_CommSendString("ATRE" & @CR)    ; send the factory default command to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & "Error sending factory defaults command",1)
		Return -1
	Else
		GUICtrlSetData( $ConfOutput, @CRLF & "          " & $readString,1)
	EndIf

	_ConfExitATMode($ConfOutput)
	_CommClosePort()
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _SendConfToXBee($ID, $DH, $DL, $Output)
	Local $readString ; Response from XBee modem to the sent AT Command


	GUICtrlSetData( $Output, "Opening AT Command mode")
	$readString = _ConfEnterATMode($Output)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $Output, @CRLF & "          " & "Error entering AT Mode",1)
		Return -1
	Else
		GUICtrlSetData( $Output, @CRLF & "          " & $readString,1)
	EndIf

	GUICtrlSetData( $Output, @CRLF & "Assingning Network ID",1)
	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "ATID " & GUICtrlRead($ID),1)
	_CommSendString("ATID " & $ID & @CR)    ; send the ID to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $Output, @CRLF & "          " & "Error assinging Network ID",1)
		Return -1
	Else
		GUICtrlSetData( $Output, @CRLF & "          " & $readString,1)
	EndIf


	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "Assingning Destination Address Hight bytes",1)
	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "ATDH " & GUICtrlRead($DH),1)
	_CommSendString("ATDH " & $DH & @CR)    ; send the Destination Address Hight bytes to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $Output, @CRLF & "          " & "Error assinging Destination Address Hight bytes",1)
		Return -1
	Else
		GUICtrlSetData( $Output, @CRLF & "          " & $readString,1)
	EndIf

	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "Assingning Destination Address Low bytes",1)
	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "ATDL " & GUICtrlRead($DL),1)
	_CommSendString("ATDL " & $DL & @CR)    ; send the Destination Address Low bytes to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $Output, @CRLF & "          " & "Error assinging Destination Address Low bytes",1)
		Return -1
	Else
		GUICtrlSetData( $Output, @CRLF & "          " & $readString,1)
	EndIf

	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "Writing data in Memory",1)
	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "ATWR",1)
	_CommSendString("ATWR" & @CR)    ; send the write data to memory command
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $Output, @CRLF & "          " & "Error writing data to Memory",1)
		MsgBox(0,"Error...","Error writing data to memoty in XBee modem. Actual data will overwrite on next Modem restart")
		Return -1
	Else
		GUICtrlSetData( $Output, @CRLF & "          " & $readString,1)
	EndIf

	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "Force to rebuilt networking",1)
	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "ATNR",1)
	_CommSendString("ATNR" & @CR)    ; send the write data to memory command
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $Output, @CRLF & "          " & "Error forcing to rebuilt networking",1)
		Return -1
	Else
		GUICtrlSetData( $Output, @CRLF & "          " & $readString,1)
	EndIf

	_ConfExitATMode($Output)

EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _ConfEnterATMode($Output)
	Local $readString ; Response from XBee modem to the sent AT Command

	Sleep(1000)  ; wait 1 second. Necesary 1 second idle to enter in AT Mode.
	GUICtrlSetData( $Output, @CRLF & "+++",1)
	_CommSendString("+++")
	Sleep(1000)   ; Necesary for entering in AT Command mode.
	$readString = _CommGetLine(@CR,10,400)
	Return $readString
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _ConfExitATMode($Output)
	Local $readString ; Response from XBee modem to the sent AT Command

	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "Exit Command Mode",1)
	Sleep(100)
	GUICtrlSetData( $Output, @CRLF & "ATCN",1)
	_CommSendString("ATCN" & @CR)    ; send the write data to memory command
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		GUICtrlSetData( $Output, @CRLF & "          " & "Error while exiting command mode",1)
		Return -1
	Else
		GUICtrlSetData( $Output, @CRLF & "          " & $readString,1)
	EndIf
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _ConfGetData($command, $Output)
	Local $readString ; Response from XBee modem to the sent AT Command

	GUICtrlSetData( $Output, @CRLF & $command,1)
	Sleep(100)
	_CommSendString( $command & @CR)    ; Request the ID to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	GUICtrlSetData( $Output, @CRLF & "          " & $readString,1)
	Return $readString
EndFunc
