#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         A.M.R.

 Script Function:
	Template AutoIt script.

 Date: 23/08/2012

 Version: 0.1 Conect via COM port with a Xbee modem and read ID, DH & DL parameters.

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



Local $GUIWidth = 400, $GUIHeight = 500
Local $GUIWidthSpacer = 20, $GUIHeigthSpacer = 10

Local $myGui ; main GUI handler
Local $myTab, $GeneralTab, $ConfigTab ; handlers for tab structure
Local $COMport, $ATID, $ATDH, $ATDL, $ConfOutput ; for the configuration of XBee modem in AT Mode.
Local $ConfSendButton


$myGui = GUICreate("Formulario de pruebas con ARDUINO", $GUIWidth, $GUIHeight, @DesktopWidth / 4, 20)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
$myTab = GUICtrlCreateTab( 10, 10, $GUIWidth - 20, $GUIHeight - 20)
$GeneralTab = GUICtrlCreateTabItem("General")

$ConfigTab = GUICtrlCreateTabItem("Config") ; Configurtation XBee interface tab
GUICtrlSetOnEvent($ConfigTab, "_COMPortSelect")
GUICtrlCreateLabel("Select COM port", $GUIWidthSpacer, $GUIHeigthSpacer * 5, $GUIWidth - $GUIWidthSpacer * 2)
$COMport = GUICtrlCreateCombo("", $GUIWidthSpacer, $GUIHeigthSpacer * 6.5, $GUIWidth - $GUIWidthSpacer * 2)
GUICtrlSetOnEvent($COMport,"_COMPortSelect")
GUICtrlCreateLabel("Select Network ID", $GUIWidthSpacer, $GUIHeigthSpacer * 10, $GUIWidth - $GUIWidthSpacer * 2)
$ATID = GUICtrlCreateInput("", $GUIWidthSpacer, $GUIHeigthSpacer * 11.5, $GUIWidth - $GUIWidthSpacer * 2)
GUICtrlCreateLabel("Select Destination Address Hight", $GUIWidthSpacer, $GUIHeigthSpacer * 15, $GUIWidth - $GUIWidthSpacer * 2)
$ATDH = GUICtrlCreateInput("", $GUIWidthSpacer, $GUIHeigthSpacer * 16.5, $GUIWidth - $GUIWidthSpacer * 2)
GUICtrlCreateLabel("Select Destination Address Low", $GUIWidthSpacer, $GUIHeigthSpacer * 20, $GUIWidth - $GUIWidthSpacer * 2)
$ATDL = GUICtrlCreateInput("", $GUIWidthSpacer, $GUIHeigthSpacer * 21.5, $GUIWidth - $GUIWidthSpacer * 2)
$ConfOutput = GUICtrlCreateEdit("", $GUIWidthSpacer, $GUIHeigthSpacer * 27, $GUIWidth - $GUIWidthSpacer * 2, $GUIHeigthSpacer * 16)
$ConfSendButton = GUICtrlCreateButton("Send Conf.", $GUIWidth - $GUIWidthSpacer * 8, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 6)
GUICtrlSetOnEvent($ConfSendButton, "_CONFSendButtonClick")

$ConfReadButton = GUICtrlCreateButton("Read Conf.", $GUIWidthSpacer, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 6)
GUICtrlSetOnEvent($ConfReadButton, "_CONFReadButtonClick")


GUISetState() ; Show the main GUI

_COMPortSelect()


while 1
	Sleep(10)
WEnd


;***************************************************************************************************
Func _CLOSEClicked ()
	MsgBox(0, "GUI Event", "You clicked CLOSE! Exiting...")
	Exit
EndFunc

;***************************************************************************************************
Func _COMPortSelect()
	Local $pl; contador

	;MsgBox(0,"comportselectclick", "inside the comportselect click routine")
	$portlist = _CommListPorts(0) ;find the available COM ports and write them into the COMport combo
									;$portlist[0] contain the $portlist[] lenght

	If @error = 1 Then
		MsgBox(0,'trouble getting portlist','Program will terminate!')
		Exit
	EndIf


	For $pl = 1 To $portlist[0]
		GUICtrlSetData($COMport,$portlist[$pl]);add de list or detected COMports to the $COMport combo
	Next
	;GUICtrlSetData($COMport,$portlist[1]);show the first port found
EndFunc


;***************************************************************************************************
Func _CONFSendButtonClick()
	Local $temString ; For display de command send to the XBee Modem and his response

	;MsgBox(0, "Send Command to XBee modem", "Sending configuration to XBee modem")

	$CMPort = StringReplace(GUICtrlRead($COMport),'COM','') ; Eliminate the COM caracters to the COMport text

	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf

	;MsgBox(0, "Send Command to XBee modem", "Port COM open")

	_CommClosePort()

	;MsgBox(0, "Send Command to XBee modem", "Port COM close")
EndFunc

Func _CONFReadButtonClick()
	Local $temString ; For display de command send to the XBee Modem and his response
	Local $readString ; Response from XBee modem to the sent AT Command

	;MsgBox(0, "Send Command to XBee modem", "Read configuration from XBee modem")

	$CMPort = StringReplace(GUICtrlRead($COMport),'COM','') ; Eliminate the COM caracters to the COMport text

	_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return
	EndIf

	;MsgBox(0, "Send Command to XBee modem", "Port COM open")

	$temString = "Opening AT Command mode"
	GUICtrlSetData( $ConfOutput, $temString)
	Sleep(1000)  ; wait 1 second. Necesary 1 second idle to enter in AT Mode.
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "+++"
	GUICtrlSetData( $ConfOutput, $temString)
	_CommSendString("+++")
	Sleep(1000)   ; Necesary for entering in AT Command mode.
	$readString = _CommGetLine(@CR,10,400)
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $temString)


	$temString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Network ID"
	GUICtrlSetData( $ConfOutput, $temString)
	Sleep(100)
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "ATID"
	GUICtrlSetData( $ConfOutput, $temString)
	_CommSendString("ATID" & @CR)    ; Request the ID to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $temString)
	GUICtrlSetData($ATID, $readString)


	Sleep(100)
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Destination Address Hight bytes"
	GUICtrlSetData( $ConfOutput, $temString)
	Sleep(100)
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "ATDH"
	GUICtrlSetData( $ConfOutput, $temString)
	_CommSendString("ATDH" & @CR)    ; Request the Higth byte Destination Address to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $temString)
	GUICtrlSetData($ATDH, $readString)


	Sleep(100)
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "Getting Destination Address Low bytes"
	GUICtrlSetData( $ConfOutput, $temString)
	Sleep(100)
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "ATDL"
	GUICtrlSetData( $ConfOutput, $temString)
	_CommSendString("ATDL" & @CR)    ; Request the Low byte Destination Address to the XBee modem
	$readString = _CommGetLine(@CR,10,400)
	$temString = GUICtrlRead($ConfOutput) & @CRLF & "          " & $readString
	GUICtrlSetData( $ConfOutput, $temString)
	GUICtrlSetData($ATDL, $readString)


	_CommClosePort()

	;MsgBox(0, "Send Command to XBee modem", "Port COM close")
EndFunc