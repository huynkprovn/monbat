#include-once

#include <array.au3>
#include <CommMG.au3>


Opt("mustdeclarevars", 1) ;testing only

Const $LIB_VERSION = 'XBeeAPI.au3 V0.4.0'
Global $debug = True
#cs
	Version 0.4.0	Escaped byte detection while sending each byte no in frame generation function.
					Created a function to calculate the sending checksum byte
	Version 0.3.0	Implements Functions for reading status and data in a ATResponseFrame
	Version 0.2.3 	Fix error while checksum byte was a escaped one.
	Version 0.2.2	Add secuential frameId funtionality
	Version 0.2.1 	Fix error while sending parameters to set in AT command
	Version 0.2.0	Add AT command sent functionality with _SendATCommand()funct
	Version 0.1.1	Check received escaped byte
	Version 0.1.0	Add functions body definition
	Version 0.0.1	Add Begin and End funtion to initialize the serial port where XBee modem are conected
	Add _CheckIncomingFrame() and  _CheckRxFrameCheckSum()
	Version 0.0		Const and var definition

	AutoIt Version: 3.3.8.1
	Language:       English

	Description:    Functions library for XBee series 2 modem comunication using the API mode

	Functions available:
	_XbeeBegin($port, $baudRate)
	_XbeeEnd($port)
	_CheckIncomingFrame()
	_CheckRxFrameCheckSum()
	_GenerateCheckSum()
	_GetApiID()

	_SendATCommand()
	_SendATCommandQueue()
	_SendRemoteATCommand()
	_SendZBData()
	_SendZBDataExplicit()

	_SendTxFrame()

	_ReadATCommandResponse()
	_ReadATCommandResponseStatus()
	_ReadATCommandResponseValue()

	_ReadRemoteATCommandResponse()
	_ReadModemStatusResponse()
	_ReadZBDataResponse()
	_ReadZBStatusResponse()

	_SetFrameId()
	_IsEscaped($byte)

	Author: Antonio Morales
#ce

;********* CONST DEFINITION

Const $MAX_FRAME_SIZE = 96 ;  72 data + 24 byte for a 0x12 Api command (Verify)
Const $MAX_DATA_SIZE = 74; 72 	Bytes for maximum for the data to be sent or received

; Escaped byte definition
Const $START_BYTE = 0x7E
Const $ESCAPE = 0x7D
Const $XON = 0x11
Const $XOFF = 0x13

; Define API id constants.
Const $AT_COMMAND_REQUEST = 0x08
Const $AT_COMMAND_QUEUE_REQUEST = 0x09
Const $REMOTE_AT_REQUEST = 0x17
Const $ZB_TX_REQUEST = 0x10
Const $ZB_EXPLICIT_TX_REQUEST = 0x11
Const $ZB_BINDIND_TABLE_COMMAND = 0x12 ; ******** look for info about this frame
Const $AT_RESPONSE = 0x88
;Const TX_STATUS_RESPONSE 0x89  ; ******** look for info about this frame
Const $MODEM_STATUS_RESPONSE = 0x8A
Const $ZB_TX_STATUS_RESPONSE = 0x8B ; When a TX request is complete, the module sends a TX Status Message. This message will indicate if the packet was transmitted successfully
Const $ADVANCED_MODEM_STATUS_RESPONSE = 0x8C
Const $ZB_RX_RESPONSE = 0x90 ; When the modem receive an RF packet, it is sent out the UART using this message type.
Const $ZB_EXPLICIT_RX_RESPONSE = 0x91 ; When the modem receives a ZigBee FR packet it is sent out the UART using this message type if the EXPLICIT_RECEIVE_OPTION bit is set in AO
Const $ZB_IO_SAMPLE_RESPONSE = 0x92
Const $ZB_IO_NODE_IDENTIFIER_RESPONSE = 0x95 ; ******** look for info about this frame
Const $AT_COMMAND_RESPONSE = 0x88
Const $REMOTE_AT_COMMAND_RESPONSE = 0x97

; Define TX STATUS constants. Returned in a TX Status API fram (0x8B)
Const $SUCCESS = 0x00
Const $MAC_ACK_FAILURE = 0x01
Const $CCA_FAILURE = 0x02
Const $INVALID_DESTINATION_ENDPOINT = 0x15
Const $NETWORK_ACK_FAILURE = 0x21
Const $NOT_JOINED_TO_NETWORK = 0x22
Const $SELF_ADDRESSED = 0x23
Const $ADDRESS_NOT_FOUND = 0x24
Const $ROUTE_NOT_FOUND = 0x25
Const $PAYLOAD_TOO_LARGE = 0x74
Const $INDIRECT_MESSAGE_UNREQUESTED = 0x75

; Define MODEM STATUS constants. Returned in a Modem Status API frame (0x8A)
Const $HARDWARE_RESET = 0
Const $WATCHDOG_TIMER_RESET = 1
Const $ASSOCIATED = 2
Const $DISASSOCIATED = 3
Const $SYNCHRONIZATION_LOST = 4
Const $COORDINATOR_REALIGNMENT = 5
Const $COORDINATOR_STARTED = 6


;*********** GLOBAL VARIABLES DEFINITION

Global $apiId
Global $msbLength
Global $lsbLength
Global $checksum = 0x00
Global $frameLength
Global $complete
Global $errorCode

Global $frameId = 0x01

Global $address64[4]
;Global $addressHight
;Global $addressLow
Global $address16[2]

Global $remoteAddress64[4]
;Global $remoteAddressHight
;Global $remoteAddressLow
Global $remoteAddress16[2]

Global $responseFrameData[$MAX_FRAME_SIZE]
Global $responseFrameLenght

Global $requestFrameData[$MAX_FRAME_SIZE]
Global $requestFrameLenght

; Used in ZigBee Tx Status frame
Global $transmitRetryCount
Global $deliveryStatus
Global $discoveryStatus

; Used in ZigBee Receive packect frame
Global $option

; Used in ZigBee Transmit packect frame
Global $broadcastRadius

; Used in AT command frame
Global $atCommand
Global $atCommandValue

; Used in RX status frames
Global $status


; Used in serial comm library
Global $sportSetError = ''


If ($debug) Then
	ConsoleWrite($LIB_VERSION & @CRLF)
EndIf


;***************** FUNCTION DEFINITION ******************

;===============================================================================
;
; Function Name:  	_XbeeBegin($port, $baudRate)
; Description:    	Open a serial conection with the XBee modem conected to the
;					COM port $port at $baudRate bits/s. The other parameters
;					Necessary to stablish the connection are stablished automatically
; Parameters:     	$port - Integer: port who is connected the modem without the 'COM' string. Ex: 9
;					$baudrate - Integer: Connection baudrate, Ex: 4800, 9600, 56000
; Returns;  on success - returns 1 and sets $sErr to ''
;           on error returns 0 and with the error message in $sErr, and sets @error as follows
;                           @error             meaning error with
;                             1               dll call failed
;                             2               dll was not open and could not be opened
;                            -1               $baudRate
;                            -2               $Stop
;                            -4               $Bits
;                            -8               $Port = 0 not allowed
;                           -16               $Port not found
;                           -32               $Port access denied (in use?)
;                           -64               unknown error
;===============================================================================
Func _XbeeBegin($port, $baudRate)

	Local $DataBits = 8 ; Data Bits
	Local $Parity = "none" ; Parity none
	Local $Stop = 1 ; Stop
	Local $flow = 2 ; Flow NONE

	_CommSetPort($port, $sportSetError, $baudRate, $DataBits, $Parity, $Stop, $flow)
	If $sportSetError <> '' Then
		MsgBox(0, 'Setport error = ', $sportSetError)
		Return 0
	EndIf

	Return 1

EndFunc   ;==>_XbeeBegin


;===============================================================================
;
; Function Name:	_Xbee_End()
; Description:    	Close the serial connection with the Xbee modem.
;					If several COM ports are open with the CommMG.dll, close the active one
; Parameters:
; Returns;  		No return value
;
;===============================================================================
Func _XbeeEnd()
	_CommClosePort()
EndFunc   ;==>_XbeeEnd


;===============================================================================
;
; Function Name:	_CheckIncomingFrame()
; Description:		Check if is a available frame in the serial incoming buffer.
;					If yes, verify for a START BYTE and read the entire frame
; Parameters:		None
; Returns;  on success - return 1 and the available is read to the  $responseFrameData
;						 global variable
;           on error - return 0
;===============================================================================
Func _CheckIncomingFrame()
	Local $byteRead
	Local $k
	Local $lenght
	Local $timeout = 200

	If _CommGetInputCount() == 0 Then
		Return 0
	Else
		$byteRead = _CommReadByte($timeout)
		If $byteRead == $START_BYTE Then ; receive the frame
			$responseFrameData[1] = $byteRead
			$responseFrameData[2] = _CommReadByte($timeout) ;
			$responseFrameData[3] = _CommReadByte($timeout) ;
			If _IsEscaped($responseFrameData[3]) Then
				$responseFrameData[3] = "0x" & BitXOR(_CommReadByte($timeout), 0x20)
			EndIf

			$lenght = $responseFrameData[3] ; hight byte always be 00

			If $debug Then
				ConsoleWrite($lenght & @CRLF)
			EndIf

			For $k = 1 To $lenght + 1
				$responseFrameData[$k + 3] = _CommReadByte($timeout)
				If _IsEscaped($responseFrameData[$k + 3]) Then
					$responseFrameData[$k + 3] = "0x" & Hex(BitXOR(_CommReadByte($timeout), 0x20), 2)
				EndIf
			Next

			$responseFrameLenght = $lenght + 4
			If $debug Then
				For $k = 1 To $lenght + 4
					ConsoleWrite($responseFrameData[$k])
				Next
				ConsoleWrite(@CRLF)
			EndIf
			Return 1

		EndIf

	EndIf
	Return 0

EndFunc   ;==>_CheckIncomingFrame


;===============================================================================
;
; Function Name:	_CheckRxFrameCheckSum()
; Description:		Check the Checksum byte in the received API frame content in
;					the $responseFrameData global var.
;					Must be useb after a "_CheckIncomingFrame() = true" function call
; Parameters:		None
; Returns;  on success - return 1 Cheksum byte ok
;           on error - return 0
;===============================================================================
Func _CheckRxFrameCheckSum()
	Local $k
	Local $Sum = 0x0

	If $debug Then
		ConsoleWrite("In CheckSum functrion, Lenght is: " & $responseFrameLenght & @CRLF)
	EndIf

	For $k = 4 To $responseFrameLenght
		$Sum += "0x" & Hex($responseFrameData[$k], 2)

		If $debug Then
			ConsoleWrite($responseFrameData[$k] & " " & Hex($responseFrameData[$k], 2) & " " & $Sum & " " & Hex(Int($Sum), 2) & @CRLF)
		EndIf
	Next

	If "0x" & Hex(Int($Sum), 2) = 0xFF Then
		Return 1
	EndIf
	Return 0
EndFunc   ;==>_CheckRxFrameCheckSum


;===============================================================================
;
; Function Name:	 _GenerateCheckSum($lenght)
; Description:		Calculate the checksum byte of a API frame contained in the
;					the output frame variable and lenght $lenght
;
; Parameters:		$lenght - Lenght of the frame to calculete checksum
; Returns;  on success - return the calculated checksum byte
;           on error - return 0
;===============================================================================
Func _GenerateCheckSum($lenght)
	Local $k
	Local $checksum = 0x00

	If $debug Then
		ConsoleWrite("longitud de la trama = " & $lenght & @CRLF)
	EndIf

	For $k = 4 to $lenght
		$checksum += $requestFrameData[$k]
		If $debug Then
			ConsoleWrite($requestFrameData[$k] & " " & $checksum & " " & Hex($checksum,2) & @CRLF)
		EndIf
	Next

	Return (0xFF - $checksum)
EndFunc   ;==>_GenerateCheckSum


;===============================================================================
;
; Function Name:	_GetApiID()
; Description:		Return the API ID byte in a API frame previosly received whith
;
; Parameters:
; Returns;  on success - return The API frame byte
;           on error - return 0
;===============================================================================
Func _GetApiID()

	If $responseFrameData[1] == 0x7E Then
		Return $responseFrameData[4]
	EndIf
	Return 0

EndFunc   ;==>_GetApiID


;===============================================================================
;
; Function Name:?  _SendATCommand()
; Description:	Send an AT command frame to a local Xbee modem conected via serial
;		port to the PC.
;		The AT command must previosly be set with the XXXXX function
;		If the ATcommand contain a value data, the value must previosly
;		be set with the XXXXX function
;
; Parameters: 	$command - The AT command without the AT prefix
;				$value - (optional) if <> 0 then set the value of the property sent with $command
;									must be a byte comma separated string
;				$ack - (optional) if <> 0 a byte frame byte is set to an automatically valor.
;							else is set to 0 (no at command response is will be given)
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SendATCommand($command, $value = 0, $ack = 1)
	Local $com, $comLenght 	; command and command lenght
	Local $val, $valLenght	; value and value lenght
	Local $k = 0			; to calculate the real frame lenght
	Local $j 				; counters

	$com = StringSplit($command, "") ; Breaks the input string into an array of characters
	$comLenght = $com[0]
	$valLenght = 0;
	If @NumParams > 1 Then
		$val = StringSplit($value, ",")
		$valLenght = $val[0]
	EndIf

	$k += 1
	$requestFrameData[$k] = $START_BYTE
	$k += 1
	$requestFrameData[$k] = 0x00						; Lenght Hight byte
	$k += 1
	$requestFrameData[$k] = "0x" & Hex(2 + $comLenght + $valLenght, 2) ;Lenght Low Byte (2 = api byte + frame id byte)
	$k += 1

	$requestFrameData[$k] = $AT_COMMAND_REQUEST			; All byte from this one until the frame end are used in checksum calculation
	$k += 1

	If $ack = 0 Then				; Generate the FrameID byte
		$requestFrameData[$k] = 0x00
	Else
		$requestFrameData[$k] = _GetFrameId()
	EndIf
	$k += 1

	If $debug Then
		ConsoleWrite("AT command length is:" & $com[0] & @CRLF)
	EndIf

	For $j = 1 To $com[0] ; Set the AT command
		$requestFrameData[$k] =  "0x" & Hex(Asc($com[$j]), 2)
		$k += 1
	Next

	If @NumParams > 1 Then ; Is a value present?
		If $debug Then
			ConsoleWrite("AT value length is:" & $val[0] & @CRLF)
			For $j = 1 To $val[0]
				ConsoleWrite($val[$j])
			Next
			ConsoleWrite(@CRLF)
		EndIf

		For $j = 1 To $val[0] ;Set the AT Command value

			$requestFrameData[$k] = "0x" & $val[$j]
			If $debug Then
				ConsoleWrite($requestFrameData[$k] & @CR)
			EndIf
			$k += 1
		Next
	EndIf

	$requestFrameData[$k] = _GenerateCheckSum($k-1)
	$requestFrameLenght = $k

	_SendTxFrame()

EndFunc   ;==>_SendATCommand


;===============================================================================
;
; Function Name:?  _SendATCommandQueue()
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SendATCommandQueue()

EndFunc   ;==>_SendATCommandQueue


;===============================================================================
;
; Function Name:?  _SendRemoteATCommand()
; Description:		Equal to _SendATCommand.
;			The remote Address must be set with the XXXX function.
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SendRemoteATCommand()

EndFunc   ;==>_SendRemoteATCommand


;===============================================================================
;
; Function Name:?
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SendZBData()

EndFunc   ;==>_SendZBData


;===============================================================================
;
; Function Name:?
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SendZBDataExplicit()

EndFunc   ;==>_SendZBDataExplicit


;===============================================================================
;
; Function Name:	 _SendTxFrame()
; Description:		Send the previos calculated API frame set by each Send function
;					Check for escaped bytes before sending the bytes
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SendTxFrame()
	Local $k
	Local $timeout = 100

	_CommSendByte($requestFrameData[1],$timeout)
	For $k = 2 To $requestFrameLenght
		If _IsEscaped($requestFrameData[$k]) Then
			_CommSendByte(0x7D,$timeout)
			_CommSendByte("0x" & BitXOR($requestFrameData[$k], 0x20))
		Else
			_CommSendByte($requestFrameData[$k], 100)
		EndIf
	Next
EndFunc   ;==>_SendTxFrame


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _ReadATCommandResponse()

EndFunc   ;==>_ReadATCommandResponse


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _ReadRemoteATCommandResponse()

EndFunc   ;==>_ReadRemoteATCommandResponse


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _ReadModemStatusResponse()

EndFunc   ;==>_ReadModemStatusResponse


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _ReadZBDataResponse()

EndFunc   ;==>_ReadZBDataResponse


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _ReadZBStatusResponse()

EndFunc   ;==>_ReadZBStatusResponse


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _ReadFrameId()


EndFunc   ;==>_ReadFrameId


;===============================================================================
;
; Function Name:	_ReadATCommandResponseStatus()
; Description:		Return the status byte in a RXAtCommandResponse previously checked
;					With the _GetApiId function equal to 0x88
;
; Parameters:		None
; Returns;  on success - return the status byte
;           on error - return 0
;===============================================================================
Func _ReadATCommandResponseStatus()
	Return $responseFrameData[8]
EndFunc


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _ReadATCommandResponseValue()
	Local $k
	Local $value = ""

	For $k = 9 To ($responseFrameLenght - 1)
		$value &= Hex($responseFrameData[$k],2)
	Next

	Return $value
EndFunc


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SetFrameId()


EndFunc   ;==>_SetFrameId


;===============================================================================
;
; Function Name:	 _GetFrameID()
; Description:		Generate a secuencial IdFrame between 0x01 and 0xFF
; Parameters:
; Returns;  on success - return a byte containing the frameID
;           on error - return 0
;===============================================================================
Func _GetFrameId()
	If $apiId = 255 Then
		$apiId = 1
	Else
		$apiId += 1
	EndIf
	Return $apiId
EndFunc   ;==>_GetFrameId


;===============================================================================
;
; Function Name:	 _IsEscaped($byte)
; Description:		Check if the received byte is a escaped byte
;
; Parameters:
; Returns;  on success - return 1 (byte is a escaped byte)
;           on error - return 0
;===============================================================================
Func _IsEscaped($byte)

	If ($byte == $START_BYTE Or $byte == $ESCAPE Or $byte == $XON Or $byte == $XOFF) Then
		If $debug Then
			ConsoleWrite("escaped byte" & @CRLF)
		EndIf
		Return 1
	Else
		Return 0
	EndIf

EndFunc   ;==>_IsEscaped




