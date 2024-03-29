#include-once

#include "XbeeConstants.au3"
#include <array.au3>
#include <CommMG.au3>


Opt("mustdeclarevars", 1) ;testing only

Const $LIB_VERSION = 'XBeeAPI.au3 V0.9.2'
Global $debug = True
#cs
	Version 0.9.2	Fix error in SendFrame function when send the "0x7D" byte previous a escaped byte
	Version 0.9.1	Fix error in SendRemoteAtCommand function. Now it�s work ok
	Version 0.9.0	Fix an error in SendZBData with remote address, Now it�s work ok
					TODO fix the same error in RemoteAtCommand funct
	Version 0.8.0	Add XbeeConstants library for Const
	Version 0.7.2 	Add Constants for status bytes in rx frames
	Version 0.7.1	Add function to convert string to an array byte. Modify send frames functions
	Version 0.7.0	Add functions for reading data in statusResponses and DataResponses
	Version 0.6.0	Add functions for reading data in RemoteAtCommandResponse frames
	Version 0.5.1	Add function to set 64bits and 16bits remote address
	Version 0.5.0	Add remote request data and remote AT command send functions
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
	_ReadATCommandResponseCommand()
	_ReadATCommandResponseStatus()
	_ReadATCommandResponseValue()

	_ReadRemoteATCommandResponse()
	_ReadRemoteATCommandResponseStatus()
	_ReadRemoteATCommandResponseValue()
	_ReadRemoteATCommandResponseAddress64()
	_ReadRemoteATCommandResponseAddress16()

	_ReadModemStatus()

	_ReadZBDataResponse()
	_ReadZBDataResponseOption()
	_ReadZBDataResponseValue()
	_ReadZBDataResponseAddress64()
	_ReadZBDataResponseAddress16()

	_ReadZBStatusResponse()
	_ReadZBStatusReponseDeliveryStatus()
	_ReadZBStatusReponseDiscoveryStatus()
	_ReadZBStatusResponseAddress16()

	_SetFrameId()
	_IsEscaped($byte)

	_SetAddress64($address)
	_SetAddress16($address)

	Author: Antonio Morales
#ce



If ($debug) Then
	ConsoleWrite($LIB_VERSION & @CRLF)
EndIf


;**** TEST CODE

;****



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

			;If $debug Then
			;	ConsoleWrite($lenght & @CRLF)
			;EndIf

			For $k = 1 To $lenght + 1
				$responseFrameData[$k + 3] = _CommReadByte($timeout)
				If _IsEscaped($responseFrameData[$k + 3]) Then
					$responseFrameData[$k + 3] = "0x" & Hex(BitXOR(_CommReadByte($timeout), 0x20), 2)
				EndIf
			Next

			$responseFrameLenght = $lenght + 4
			;If $debug Then
			;	For $k = 1 To $lenght + 4
			;		ConsoleWrite($responseFrameData[$k])
			;	Next
			;	ConsoleWrite(@CRLF)
			;EndIf
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

	;If $debug Then
	;	ConsoleWrite("In CheckSum functrion, Lenght is: " & $responseFrameLenght & @CRLF)
	;EndIf

	For $k = 4 To $responseFrameLenght
		$Sum += "0x" & Hex($responseFrameData[$k], 2)

		;If $debug Then
		;	ConsoleWrite($responseFrameData[$k] & " " & Hex($responseFrameData[$k], 2) & " " & $Sum & " " & Hex(Int($Sum), 2) & @CRLF)
		;EndIf
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

	For $k = 4 to $lenght
		$checksum += $requestFrameData[$k]
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
;				$value - (optional) if <> 0 then set the value of the property sent
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
		$val = _StringToByteArray($value) ; Breaks the input string into an array of bytes
		$valLenght = $val[0]
	EndIf

	$k += 1
	$requestFrameData[$k] = $START_BYTE
	$k += 1
	$requestFrameData[$k] = 0x00						; Lenght Hight byte
	$k += 1
	$requestFrameData[$k] = "0x" & Hex(2 + $comLenght + $valLenght, 2) ;Lenght Low Byte (2 = api byte + frame id byte)
	$k += 1

	$requestFrameData[$k] = $AT_COMMAND_REQUEST			; Set the API FRAME byte
	$k += 1

	If $ack = 0 Then				; Generate the FrameID byte
		$requestFrameData[$k] = 0x00
	Else
		$requestFrameData[$k] = _GetFrameId()
	EndIf
	$k += 1

;	If $debug Then
;		ConsoleWrite("AT command length is:" & $com[0] & @CRLF)
;	EndIf

	For $j = 1 To $com[0] ; Set the AT command
		$requestFrameData[$k] =  "0x" & Hex(Asc($com[$j]), 2)
		$k += 1
	Next

	If @NumParams > 1 Then ; Is a value present?
;		If $debug Then
;			ConsoleWrite("AT value length is:" & $val[0] & @CRLF)
;			For $j = 1 To $val[0]
;				ConsoleWrite($val[$j])
;			Next
;			ConsoleWrite(@CRLF)
;		EndIf

		For $j = 1 To $val[0] ;Set the AT Command value

			$requestFrameData[$k] = "0x" & $val[$j]
			;If $debug Then
			;	ConsoleWrite($requestFrameData[$k] & @CR)
			;EndIf
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
;			The remote Address must be set with the _SetAddress16($address) and _SetAddress64($address) function.
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SendRemoteATCommand($command, $value = 0, $ack = 1)
	Local $com, $comLenght 	; command and command lenght
	Local $val, $valLenght	; value and value lenght
	Local $k = 0			; to calculate the real frame lenght
	Local $j 				; counters

	$com = StringSplit($command, "") ; Breaks the input string into an array of characters
	$comLenght = $com[0]
	$valLenght = 0;
	If @NumParams > 1 Then
		$val = _StringToByteArray($value) ; Breaks the input string into an array of bytes
		$valLenght = $val[0]
	EndIf

	$k += 1
	$requestFrameData[$k] = $START_BYTE
	$k += 1
	$requestFrameData[$k] = 0x00						; Lenght Hight byte
	$k += 1
	$requestFrameData[$k] = "0x" & Hex(13 + $comLenght + $valLenght, 2) ;Lenght Low Byte (13 = api byte + frame id byte)
	$k += 1

	$requestFrameData[$k] = $REMOTE_AT_REQUEST			; Set the API FRAME byte
	$k += 1

	If $ack = 0 Then				; Generate the FrameID byte
		$requestFrameData[$k] = 0x00
	Else
		$requestFrameData[$k] = _GetFrameId()
	EndIf
	$k += 1


	For $j = 0 To 7 								; Set the Destination 64bit address
		$requestFrameData[$k] = "0x" & $remoteAddress64[$j]
		$k += 1
	Next

	$requestFrameData[$k] = "0x" & $remoteAddress16[0]     ; Set the Destination 16bit address
	$k += 1
	$requestFrameData[$k] = "0x" & $remoteAddress16[1]
	$k += 1

	$requestFrameData[$k] = 0x02 ;$ATOption
	$k += 1

;	If $debug Then
;		ConsoleWrite("AT command length is:" & $com[0] & @CRLF)
;	EndIf

	For $j = 1 To $com[0] ; Set the AT command
		$requestFrameData[$k] =  "0x" & Hex(Asc($com[$j]), 2)
		$k += 1
	Next

	If @NumParams > 1 Then ; Is a value present?
;		If $debug Then
;			ConsoleWrite("AT value length is:" & $val[0] & @CRLF)
;			For $j = 1 To $val[0]
;				ConsoleWrite($val[$j])
;			Next
;			ConsoleWrite(@CRLF)
;		EndIf

		For $j = 1 To $val[0] ;Set the AT Command value

			$requestFrameData[$k] = "0x" & $val[$j]
;			If $debug Then
;				ConsoleWrite($requestFrameData[$k] & @CR)
;			EndIf
			$k += 1
		Next
	EndIf

	$requestFrameData[$k] = _GenerateCheckSum($k-1)
	$requestFrameLenght = $k

	_SendTxFrame()
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
Func _SendZBData($data, $ack = 1, $br = 0x00, $op = 0x00)
	Local $val, $valLenght	; value and value lenght
	Local $k = 0
	Local $j = 0

	$val = _StringToByteArray($data) ; Breaks the input string into an array of bytes
	$valLenght = $val[0]

	$k += 1
	$requestFrameData[$k] = $START_BYTE
	$k += 1
	$requestFrameData[$k] = 0x00						; Lenght Hight byte
	$k += 1
	$requestFrameData[$k] = "0x" & Hex(14 + $valLenght, 2) ;Lenght Low Byte (14 = api byte + frame id byte + 64bit + 16bit + BrRadious + optipn)
	$k += 1

	$requestFrameData[$k] = $ZB_TX_REQUEST			; Set the API FRAME byte
	$k += 1

	If $ack = 0 Then								; Generate the FrameID byte
		$requestFrameData[$k] = 0x00
	Else
		$requestFrameData[$k] = _GetFrameId()
	EndIf
	$k += 1

	For $j = 0 To 7 								; Set the Destination 64bit address
		$requestFrameData[$k] = "0x" & $remoteAddress64[$j]
		$k += 1
	Next

	$requestFrameData[$k] = "0x" & $remoteAddress16[0]     ; Set the Destination 16bit address
	$k += 1
	$requestFrameData[$k] = "0x" & $remoteAddress16[1]
	$k += 1

	$requestFrameData[$k] = 0x00						; Set the Broadcast Radius byte
	$k += 1

	$requestFrameData[$k] = 0x00						; Set the Option byte
	$k += 1

	For $j = 1 to $valLenght
		$requestFrameData[$k] = "0x" & $val[$j]
		$k += 1
	Next

	$requestFrameData[$k] = _GenerateCheckSum($k-1)
	$requestFrameLenght = $k

	_SendTxFrame()


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
	If $debug Then
		ConsoleWrite($requestFrameData[1] & " ")
	EndIf
	For $k = 2 To $requestFrameLenght
		If _IsEscaped($requestFrameData[$k]) Then
			_CommSendByte(0x7D,$timeout)
			_CommSendByte("0x" & Hex(BitXOR($requestFrameData[$k], 0x20),2))

			If $debug Then
				ConsoleWrite(0x7D & " ")
				ConsoleWrite(BitXOR($requestFrameData[$k],0x20) & " ")
			EndIf
		Else
			_CommSendByte($requestFrameData[$k], 100)
			If $debug Then
				ConsoleWrite($requestFrameData[$k] & " ")
			EndIf

		EndIf
	Next
	If $debug Then
		ConsoleWrite(@CRLF)
	EndIf
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
; Function Name:	 _ReadModemStatus()
; Description:		Read the status byte in a ModemStatusResponse previosly
;					Checked with _GetApiID() = 0x8A
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _ReadModemStatus()
	Return $responseFrameData[5]
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
; Function Name:	_ReadATCommandResponseCommand()
; Description:		Return the command indicates in a RXAtCommandResponse previously checked
;					With the _GetApiId function equal to 0x88
;
; Parameters:		None
; Returns;  on success - return a char with de command
;           on error - return 0
;===============================================================================
Func _ReadATCommandResponseCommand()
	Return (Chr($responseFrameData[6]) & Chr($responseFrameData[7]))
EndFunc


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
; Function Name:	_ReadRemoteATCommandResponseCommand()
; Description:		Return the command indicates in a RXRemoteAtCommandResponse previously checked
;					With the _GetApiId function equal to 0x97
;
; Parameters:		None
; Returns;  on success - return a char with de command
;           on error - return 0
;===============================================================================
Func _ReadRemoteATCommandResponseCommand()
	Return (Chr($responseFrameData[16]) & Chr($responseFrameData[17]))
EndFunc


;===============================================================================
;
; Function Name:	_ReadRemoteATCommandResponseStatus()
; Description:		Return the status byte in a RXRemoteAtCommandResponse previously checked
;					With the _GetApiId function equal to 0x97
;
; Parameters:		None
; Returns;  on success - return the status byte
;           on error - return 0
;===============================================================================
Func _ReadRemoteATCommandResponseStatus()
	Return $responseFrameData[18]
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
Func _ReadRemoteATCommandResponseValue()
	Local $k
	Local $value = ""

	For $k = 19 To ($responseFrameLenght - 1)
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
Func _ReadRemoteATCommandResponseAddress64()
	Local $k
	Local $value = ""

	For $k = 6 To 13
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
Func _ReadRemoteATCommandResponseAddress16()
	Local $k
	Local $value = ""

	For $k = 14 To 15
		$value &= Hex($responseFrameData[$k],2)
	Next

	Return $value
EndFunc


;===============================================================================
;
; Function Name:	_ReadZBDataResponseOption()
; Description:		Return the option byte in a RXZBDataResponse previously checked
;					With the _GetApiId function equal to 0x90
;
; Parameters:		None
; Returns;  on success - return the status byte
;           on error - return 0
;===============================================================================
Func _ReadZBDataResponseOption()
	Return $responseFrameData[15]
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
Func _ReadZBDataResponseValue()
	Local $k
	Local $value = ""

	For $k = 16 To ($responseFrameLenght - 1)
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
Func _ReadZBDataResponseAddress64()
	Local $k
	Local $value = ""

	For $k = 5 To 12
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
Func _ReadZBDataResponseAddress16()
	Local $k
	Local $value = ""

	For $k = 13 To 14
		$value &= Hex($responseFrameData[$k],2)
	Next

	Return $value
EndFunc


;===============================================================================
;
; Function Name:	_ReadZBStatusReponseDeliveryStatus()
; Description:		Return the delivery status byte in a ZB TX status Response previously checked
;					With the _GetApiId function equal to 0x8B
;
; Parameters:		None
; Returns;  on success - return the status byte
;           on error - return 0
;===============================================================================
Func _ReadZBStatusReponseDeliveryStatus()
	Return $responseFrameData[9]
EndFunc


;===============================================================================
;
; Function Name:	_ReadZBStatusReponseDiscoveryStatus()
; Description:		Return the discovery status byte in a ZB TX status Response previously checked
;					With the _GetApiId function equal to 0x8B
;
; Parameters:		None
; Returns;  on success - return the status byte
;           on error - return 0
;===============================================================================
Func _ReadZBStatusReponseDiscoveryStatus()
	Return $responseFrameData[10]
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
Func _ReadZBStatusReponseAddress16()
	Local $k
	Local $value = ""

	For $k = 6 To 7
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
		;If $debug Then
		;	ConsoleWrite("escaped byte" & @CRLF)
		;EndIf
		Return 1
	Else
		Return 0
	EndIf

EndFunc   ;==>_IsEscaped


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SetAddress64($address)

	Local $addr
	Local $k

	$addr = _StringToByteArray($address) ; Breaks the input string into an array of bytes

	If $addr[0] > 8 Then
		Return 0
	Else
		For $k = 1 To 8
			$remoteAddress64[$k-1] = $addr[$k]
		Next
	EndIf
	Return 1

EndFunc   ;==>_SetAddress64


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return 1
;           on error - return 0
;===============================================================================
Func _SetAddress16($address)

	Local $addr
	Local $k

	$addr = _StringToByteArray($address) ; Breaks the input string into an array of bytes

	If $addr[0] > 2 Then
		Return 0
	Else
		For $k = 1 To 2
			$remoteAddress16[$k-1] = $addr[$k]
		Next
	EndIf
	Return 1

EndFunc   ;==>_SetAddress16


;===============================================================================
;
; Function Name:
; Description:
;
; Parameters:
; Returns;  on success - return an array with one byte for cell. Array lenght in pos 0
;           on error - return 0
;===============================================================================
Func _StringToByteArray($string)
	Local $k
	Local $array[20]

	For $k=1 To StringLen($string)/2
		$array[$k] = StringMid($string,$k*2-1,2)
	Next
	$array[0] = $k-1

	Return $array

Endfunc    ;==>_StringToByteArray
