#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         A.M.R.

 Script Function:
	Template AutoIt script.

 Date: 23/08/2012

 Version: 	0.2 	Change the GUI. Two serial connection available. Read the Source Address data.
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
Local $ConfSendButtonA, $ConfReadButtonA, $ConfSendButtonB, $ConfReadButtonB, $ConfConnectButton
Local $Sp = 5, $S = 5 ; To separate a control of each other

$myGui = GUICreate("Formulario de pruebas con ARDUINO", $GUIWidth, $GUIHeight, @DesktopWidth / 4, 20)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
$myTab = GUICtrlCreateTab( 10, 10, $GUIWidth - 20, $GUIHeight - 20)
$GeneralTab = GUICtrlCreateTabItem("General")

$ConfigTab = GUICtrlCreateTabItem("Config") ; Configurtation XBee interface tab
GUICtrlCreateLabel("COM port", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$COMportA = GUICtrlCreateCombo("", $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
GUICtrlSetOnEvent($COMportA,"_COMportASelect")
GUICtrlCreateLabel("COM port", $GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$COMportB = GUICtrlCreateCombo("",$GUIWidth / 2 + $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2)
GUICtrlSetOnEvent($COMportB,"_COMportASelect")
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

$ConfReadButtonA = GUICtrlCreateButton("Read Conf.", $GUIWidthSpacer, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 4)
GUICtrlSetOnEvent($ConfReadButtonA, "_CONFReadButtonClick")
$ConfSendButtonA = GUICtrlCreateButton("Send Conf.", $GUIWidthSpacer * 6, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 4)
GUICtrlSetOnEvent($ConfSendButtonA, "_CONFSendButtonClick")

$ConfReadButtonB = GUICtrlCreateButton("Read Conf.", $GUIWidth - $GUIWidthSpacer * 10, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 4)
GUICtrlSetOnEvent($ConfReadButtonB, "_CONFReadButtonClick")
$ConfSendButtonB = GUICtrlCreateButton("Send Conf.", $GUIWidth - $GUIWidthSpacer * 5, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 4)
GUICtrlSetOnEvent($ConfSendButtonB, "_CONFSendButtonClick")

$ConfConnectButton = GUICtrlCreateButton("Connect both", $GUIWidth / 2 - $GUIWidthSpacer * 2, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 4)
GUICtrlSetOnEvent($ConfConnectButton, "_CONFConnectButtonClick")

GUISetState() ; Show the main GUI

_COMportASelect()


while 1
	Sleep(10)
WEnd


;***************************************************************************************************
Func _CLOSEClicked ()
	MsgBox(0, "GUI Event", "You clicked CLOSE! Exiting...")
	Exit
EndFunc

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
Func _CONFSendButtonClick()
	Local $tempString ; For display de command send to the XBee Modem and his response

	;MsgBox(0, "Send Command to XBee modem", "Sending configuration to XBee modem")

	$CMPort = StringReplace(GUICtrlRead($COMportA),'COM','') ; Eliminate the COM caracters to the COMportA text

	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf

	;MsgBox(0, "Send Command to XBee modem", "Port COM open")

	$tempString = "Opening AT Command mode"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(1000)  ; wait 1 second. Necesary 1 second idle to enter in AT Mode.
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "+++"
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("+++")
	Sleep(1000)   ; Necesary for entering in AT Command mode.
	$readString = _CommGetLine(@CR,10,400)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $tempString)

	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Assingning Network ID"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATID " & GUICtrlRead($ATID_A)
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATID " & GUICtrlRead($ATID_A) & @CR)    ; send the ID to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & "Error assinging Network ID"
	Else
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $ConfOutput, $tempString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Assingning Destination Address Hight bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATDH " & GUICtrlRead($ATDH_A)
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATDH " & GUICtrlRead($ATDH_A) & @CR)    ; send the ID to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & "Error assinging Destination Address Hight bytes"
	Else
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $ConfOutput, $tempString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Assingning Destination Address Low bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATDL " & GUICtrlRead($ATDL_A)
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATDL " & GUICtrlRead($ATDL_A) & @CR)    ; send the ID to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	if $readString <> ("OK" & @CR) Then
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & "Error assinging Destination Address Low bytes"
	Else
		$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	EndIf
	GUICtrlSetData( $ConfOutput, $tempString)


	_CommClosePort()

	;MsgBox(0, "Send Command to XBee modem", "Port COM close")
EndFunc

Func _CONFReadButtonClick()
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
	Sleep(1000)  ; wait 1 second. Necesary 1 second idle to enter in AT Mode.
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "+++"
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("+++")
	Sleep(1000)   ; Necesary for entering in AT Command mode.
	$readString = _CommGetLine(@CR,10,400)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $tempString)


	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Network ID"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATID"
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATID" & @CR)    ; Request the ID to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $tempString)
	GUICtrlSetData($ATID_A, $readString)


	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Destination Address Hight bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATDH"
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATDH" & @CR)    ; Request the Higth byte Destination Address to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $tempString)
	GUICtrlSetData($ATDH_A, $readString)


	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Destination Address Low bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATDL"
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATDL" & @CR)    ; Request the Low byte Destination Address to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $tempString)
	GUICtrlSetData($ATDL_A, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Source Address Hight bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATSH"
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATSH" & @CR)    ; Request the Hight byte Source Address to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $tempString)
	GUICtrlSetData($ATSH_A, $readString)

	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Source Address Low bytes"
	GUICtrlSetData( $ConfOutput, $tempString)
	Sleep(100)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "ATSL"
	GUICtrlSetData( $ConfOutput, $tempString)
	_CommSendString("ATSL" & @CR)    ; Request the Low byte Source Address to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	$tempString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $tempString)
	GUICtrlSetData($ATSL_A, $readString)

	_CommClosePort()

	;MsgBox(0, "Send Command to XBee modem", "Port COM close")
EndFunc

Func _CONFConnectButtonClick()


EndFunc