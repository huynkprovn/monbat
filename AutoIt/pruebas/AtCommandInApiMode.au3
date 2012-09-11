#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         myName

 Script Function:
	Pueba de envio de comandos AT usando frame tipo ATCommand (id 0x08)
	De la API ZigBee.
	Se envia el comandoAT "ID"
	Se espera hasta que el modem haya respondido (1 segundo)
	y se lee el contedido del puerto (Debe ser una trama tipo ATCommandResponse (id 0x88)
	Los datos se muestran por la consola formateados segun los campos con "ConsoleWrite()"

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here

; LIBRERIAS
#include <array.au3>
#include <CommMG.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>


; VARIABLES GLOBALES
Global $sportSetError = '' ;Internal for the Serial UDF

;ZigBee Const
Const $START_BYTE = 0x7E          ; Start byte for XBee API Frame
Const $ZBRxResponseFrame = 0x90
Const $ZBATCommandResponse = 0x88
Const $ZBATCommand = 0x08


;COM Vars
Global $CMPort = 9				; Port
Global $CmBoBaud = 9600			; Baud
Global $CmboDataBits =  8		; Data Bits
Global $CmBoParity = "none"		; Parity none
Global $CmBoStop = 1			; Stop
Global $setflow = 2				; Flow NONE

;GUI VARIABLES
Global $myGui
Global $GUIWidth = 400, $GUIHeight = 400
Global $GUIWidthSpacer = 20, $GUIHeigthSpacer = 10
Global $SendButton, $Output, $CommandAT
Global $Sp = 5, $S = 5 ; To separate a control of each other


Opt("GUIOnEventMode", 1)  ; Change to OnEvent mode

$myGui = GUICreate("Formulario de pruebas con ARDUINO", $GUIWidth, $GUIHeight, @DesktopWidth / 4, 20)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")

GUICtrlCreateLabel("Insert AT Command", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth / 2 - $GUIWidthSpacer * 2)
$CommandAT = GUICtrlCreateInput("", $GUIWidthSpacer, $GUIHeigthSpacer * ($Sp + 1.5), $GUIWidth / 2 - $GUIWidthSpacer * 2,$GUIHeigthSpacer * 2)
$Sp = $Sp + $S
$ConfOutput = GUICtrlCreateEdit("", $GUIWidthSpacer, $GUIHeigthSpacer * $Sp, $GUIWidth - $GUIWidthSpacer * 2, ($GUIHeight - $GUIHeigthSpacer * 6) - $GUIHeigthSpacer * $Sp)

$SendButton = GUICtrlCreateButton("Send", $GUIWidthSpacer, $GUIHeight - $GUIHeigthSpacer * 5, $GUIWidthSpacer * 3.5)
GUICtrlSetOnEvent($SendButton, "_SendButtonClick")

GUISetState() ; Show the main GUI

;Start up communication with the Arduino
_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)

_main()


Func _main()
	While 1
		Sleep(100)
	WEnd
EndFunc


Func _SendButtonClick()

	Local $ByteRead
	Local $LenghtMSB, $LenghtLSB, $Lenght
	Local $FrameType
	Local $Address64[8]
	Local $Address16[2]
	Local $Option
	Local $Data[72]    ; Max byte in data packet
	Local $Msg[]
	Local $Checksum
	Local $GeneratedCheckSum
	Local $ByteToSend

	Local $K = 0; contador


	$K = 0
	$GeneratedCheckSum = 0x00 ;Clear the checksum variable

	$ByteToSend = $START_BYTE
	;$ByteToSend = 0x7E
	_CommSendByte($ByteToSend, 100); Send Start Byte
	ConsoleWrite(Hex($ByteToSend,2) & " ")

	#cs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;$Lenght = "0x"&Hex(StringLen(GUICtrlRead($CommandAT)),2)
	;ConsoleWrite($Lenght & @CRLF)
	$Data = StringSplit(GUICtrlRead($CommandAT),"")  ; Breaks the input string into an array of characters

	For $K = 1 to $Data[0]
		ConsoleWrite("0x"&Hex(Asc($Data[$K]),2) & " ")
	Next
	ConsoleWrite(@CRLF)
	#ce

	$ByteToSend = 0x00
	_CommSendByte($ByteToSend, 100) ; Send Lenght hight byte
	ConsoleWrite(Hex($ByteToSend,2))


	$ByteToSend = "0x"&Hex(StringLen(GUICtrlRead($CommandAT))+2,2) ; Command Lenght + 2 byte (apiID and frameID)
	_CommSendByte($ByteToSend, 100); Send Lenght low byte
	ConsoleWrite(Hex($ByteToSend,2) & " ")

	$ByteToSend = $ZBATCommand
	;$ByteToSend = 0x08
	_CommSendByte($ByteToSend, 100); Send Api Frame ID
	ConsoleWrite(Hex($ByteToSend,2) & " ")
	$GeneratedCheckSum += $ByteToSend

	$ByteToSend = 0x01
	_CommSendByte($ByteToSend, 100); Send the frame ID byte
	ConsoleWrite(Hex($ByteToSend,2) & " ")
	$GeneratedCheckSum += $ByteToSend
;	$GeneratedCheckSum = $GeneratedCheckSum + $ByteToSend

	$Data = StringSplit(GUICtrlRead($CommandAT),"")  ; Breaks the input string into an array of characters

	For $K = 1 to $Data[0]
		;ConsoleWrite("0x"&Hex(Asc($Data[$K]),2) & " ")
		$ByteToSend = "0x"&Hex(Asc($Data[$K]),2)
		_CommSendByte($ByteToSend, 100) ; Send AT command first caracter
		ConsoleWrite(Hex($ByteToSend,2))
		$GeneratedCheckSum += $ByteToSend
	Next
	ConsoleWrite(" ")

	#cs
	$ByteToSend = "0x"&Hex(Binary("I"),2)
	;$ByteToSend = 0x49
	_CommSendByte($ByteToSend, 100) ; Send AT command first caracter
	ConsoleWrite(Hex($ByteToSend,2))
	$GeneratedCheckSum += $ByteToSend

	$ByteToSend =  "0x"&Hex(Binary("D"),2)
	;$ByteToSend = 0x44
	_CommSendByte($ByteToSend, 100); Send AT command second caracter
	ConsoleWrite(Hex($ByteToSend,2) & " ")
	$GeneratedCheckSum += $ByteToSend
	#ce

	$GeneratedCheckSum = 0xFF - $GeneratedCheckSum


	;$ByteToSend = 0x69
	_CommSendByte($GeneratedCheckSum, 100)  ;Send the checksum byte
	ConsoleWrite($GeneratedCheckSum & @CRLF)



	Sleep(1000)

	For $K = 1 To _CommGetInputCount()
		$ByteRead = _CommReadByte(100)
		ConsoleWrite( Hex($ByteRead,2))
	Next
	ConsoleWrite(@CRLF)


	Sleep(1000)

EndFunc

;***************************************************************************************************
;Check if byte is one of the escaped byte defined in XBee API
;
;***************************************************************************************************
Func _IsEscaped($byte)

	Select
		Case $byte == 0x7E
			Return 1

		Case $byte == 0x7D
			Return 1

		Case $byte == 0x11
			Return 1

		Case $byte == 0x13
			Return 1

		Case Else
			Return 0
	EndSelect

	Return 0
EndFunc

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CLOSEClicked ()
	_CommClosePort()
	Exit
EndFunc
