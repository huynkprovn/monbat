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



;Start up communication with the Arduino
_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)

_main()

_CommClosePort()


Func _main()

	Local $ByteRead
	Local $LenghtMSB, $LenghtLSB, $Lenght
	Local $FrameType
	Local $Address64[8]
	Local $Address16[2]
	Local $Option
	Local $Data[72]    ; Max byte in data packet
	Local $Checksum
	Local $GeneratedCheckSum
	Local $ByteToSend

	Local $K = 0; contador


	While True

	$K = 0
	$GeneratedCheckSum = 0x00 ;Clear the checksum variable

	$ByteToSend = $START_BYTE
	;$ByteToSend = 0x7E
	_CommSendByte($ByteToSend, 100); Send Start Byte
	ConsoleWrite(Hex($ByteToSend,2) & " ")

	$ByteToSend = 0x00
	_CommSendByte($ByteToSend, 100) ; Send Lenght hight byte
	ConsoleWrite(Hex($ByteToSend,2))


	$ByteToSend = 0x04
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
	WEnd

EndFunc

;***************************************************************************************************
;Check if the byte receive is one of the escaped byte defined in XBee API
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