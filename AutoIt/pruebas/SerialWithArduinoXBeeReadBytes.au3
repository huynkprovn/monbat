#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         myName

 Script Function:
	Pueba de lectura por el puerto serie del estado del puerto A1 enviados desde Arduino
	Los datos son enviados desde Arduino usando XBee en API Mode.
	Se esperan tramas del tipo ZigBee RX Packet. FrameType = 0x90

	Los datos se muestran por la consola formateados segun los campos con "ConsoleWrite()"

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

	Local $K = 0; contador


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

			$FrameType = _ReadByte(100)  	; Receive frame type. Must be 0x90
			ConsoleWrite(Hex($FrameType,2) & " ")

			While $K <= 7	; eight first byte for the 64 source address
				$Address64[$K] = _ReadByte(100)  ; Read a byte
				ConsoleWrite(Hex($Address64[$K],2))
				$K += 1
			WEnd
			ConsoleWrite(" ")

			While ($K >= 8 And $K <= 9) ; two byte for the 16 source address
				$Address16[$K - 8] = _ReadByte(100)  ; Read a byte
				ConsoleWrite(Hex($Address16[$K - 8],2))
				$K += 1
			WEnd
			ConsoleWrite(" ")

			$Option = _ReadByte(100)  ; Read the option byte
			ConsoleWrite(Hex($Option,2) & " ")
			$K += 1

			While ($K < $Lenght - 1)    ; Read the data
				$Data[$K - 11] = _ReadByte(100)  ; Read a byte
				ConsoleWrite(Hex($Data[$K - 11],2))
				$K += 1
			WEnd
			ConsoleWrite(Hex($Option,2) & " ")

			$Checksum = _ReadByte(100)  ; Read a byte
			ConsoleWrite(Hex($Checksum,2) & @CRLF)

			$K = 0

		EndIf


	WEnd

EndFunc


#cs --------------------------------------------------------------------------------------------
	-	Read a byte from default serial port and check if is an API-2 mode escaped byte
	-	if so, return the correct byte
	-	if not, return the read byte
#ce
Func _ReadByte($wait = 0)
	Local $ByteRead

	$ByteRead = _CommReadByte($wait)  ; Read a byte
	If $ByteRead == 0x7D Then	; This byte must be escaped return the next byte xor 0x20
		Return (BitXOR(_CommReadByte(100),0x20))
	Else
		Return $ByteRead
	EndIf

EndFunc