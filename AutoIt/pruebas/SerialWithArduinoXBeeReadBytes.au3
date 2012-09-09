#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         myName

 Script Function:
	Pueba de lectura por el puerto serie del estado del puerto A1 enviados desde Arduino
	Los datos son enviados desde Arduino usando XBee en API Mode.
	Se esperan tramas del tipo ZigBee RX Packet. FrameType = 0x90

	Los dato"ConsoleWrite()"

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here

; LIBRERIAS
#include <array.au3>
#include <CommMG.au3>


; VARIABLES GLOBALES
Global $sportSetError = '' ;Internal for the Serial UDF


;COM Vars
Global $CMPort = 9				; Port
Global $CmBoBaud = 9600			; Baud
Global $CmboDataBits =  8		; Data Bits
Global $CmBoParity = "none"		; Parity none
Global $CmBoStop = 1			; Stop
Global $setflow = 2				; Flow NONE

Const $START_BYTE = 0x7E          ; Start byte for XBee API Frame

Const $ZBRxResponseFrame = 0x90

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

	Local $K ; contador


	While True

		$ByteRead = _CommReadByte(4000)
		If $ByteRead == $START_BYTE Then ; Read a start byte
			ConsoleWrite(Hex($ByteRead,2) & " ")

			While _CommGetInputCount() < 2 ; Wait until the lenght bytes are available
			WEnd

			$LenghtMSB = _CommReadByte(100)
			$LenghtLSB = _CommReadByte(100)
			$Lenght = $LenghtMSB & $LenghtLSB
			ConsoleWrite($Lenght & " ")

			While _CommGetInputCount() < ($LenghtMSB & $LenghtLSB) ; Wait until all byte are available
			Wend

			$FrameType = _CommReadByte(100)  	; Receive frame type. Must be 0x90
			ConsoleWrite(Hex($FrameType,2) & " ")

			For $K = 0 To 7
				$Address64[$K] = _CommReadByte(100)  ; Read the 64 source address
				ConsoleWrite(Hex($Address64[$K],2))
			Next
			ConsoleWrite(" ")

	;		ConsoleWrite(Hex($Address64,16) & " ")

			For $K = 0 To 1
				$Address16[$K] = _CommReadByte(100)  ; Read the 16 source address
				ConsoleWrite(Hex($Address16[$K],2))
			Next
			ConsoleWrite(" ")


			$Option = _CommReadByte(100)  	; Receive the option byte
			ConsoleWrite(Hex($Option,2) & " ")

			;ConsoleWrite(Hex($Address16,4) & " ")
			;ConsoleWrite(($Lenght - 11) & " ")
			For $K = 0 to ($Lenght - 11)    ; Read de Data = lenght - 8 byte (64 bit addr) - 2 byte (16bit addr) - 1 byte (checksum)
				$Data[$K] = _CommReadByte(100)
				ConsoleWrite(Hex($Data[$K],2))
			Next
			ConsoleWrite(" ")
			;ConsoleWrite(Hex($Data,($Lenght - 10)*2) & " ")

			$Checksum = _CommReadByte(100)
			ConsoleWrite(Hex($Checksum,2) & @CRLF)

		EndIf


	WEnd

EndFunc