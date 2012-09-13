#include-once

#include <array.au3>
#include <CommMG.au3>


Opt("mustdeclarevars", 1) ;testing only

Const $LIB_VERSION = 'XBeeAPI.au3 V0.0.1'
Global $debug = True
#cs
    Version 0.0.1	Add Begin and End funtion to initialize the serial port where XBee modem are conected
					Add _CheckIncomingFrame() and  _CheckRxFrameCheckSum()
	Version 0.0		Const and var definition

    AutoIt Version: 3.3.8.1
    Language:       English

    Description:    Functions for XBee series 2 modem comunication using the API mode

    Functions available:
					_XbeeBegin($port, $baudRate)
					_XbeeEnd($port)
					_CheckIncomingFrame()
					_CheckRxFrameCheckSum()

    Author: Antonio Morales
#ce

;********* CONST DEFINITION

Const $MAX_FRAME_SIZE = 96 ;  74 data + 24 byte for a 0x12 Api command (Verify)
Const $MAX_DATA_SIZE = 72; 72 	Bytes for maximum for the data to be sent or received

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
Const $ZB_BINDIND_TABLE_COMMAND = 0x12    ; ******** look for info about this frame
Const $AT_RESPONSE = 0x88
;Const TX_STATUS_RESPONSE 0x89  ; ******** look for info about this frame
Const $MODEM_STATUS_RESPONSE = 0x8A
Const $ZB_TX_STATUS_RESPONSE = 0x8B ; When a TX request is complete, the module sends a TX Status Message. This message will indicate if the packet was transmitted successfully
Const $ADVANCED_MODEM_STATUS_RESPONSE = 0x8C
Const $ZB_RX_RESPONSE = 0x90  ; When the modem receive an RF packet, it is sent out the UART using this message type.
Const $ZB_EXPLICIT_RX_RESPONSE = 0x91 ; When the modem receives a ZigBee FR packet it is sent out the UART using this message type if the EXPLICIT_RECEIVE_OPTION bit is set in AO
Const $ZB_IO_SAMPLE_RESPONSE = 0x92
Const $ZB_IO_NODE_IDENTIFIER_RESPONSE = 0x95  ; ******** look for info about this frame
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
Global $checksum
Global $frameLength
Global $complete
Global $errorCode

Global $frameId

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

	Local $DataBits =  8		; Data Bits
	Local $Parity = "none"		; Parity none
	Local $Stop = 1				; Stop
	Local $flow = 2				; Flow NONE

	_CommSetPort($port, $sportSetError, $baudRate, $DataBits, $Parity, $Stop, $flow)
	if $sportSetError <> '' then
		MsgBox(0,'Setport error = ',$sportSetError)
		Return 0
	EndIf

	Return 1

EndFunc


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
EndFunc




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
	Local $k = 4
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
			$lenght = $responseFrameData[3] ; hight byte alwais be 00

			If $debug Then
				ConsoleWrite($lenght & @CRLF)
			EndIf

			For $k=1 To $lenght + 1
				$responseFrameData[$k+3] = _CommReadByte($timeout)
			Next

			$responseFrameLenght = $lenght + 4
			If $debug Then
				For $k=1 To $lenght+4
					ConsoleWrite($responseFrameData[$k])
				Next
				ConsoleWrite(@CRLF)
			EndIf
			Return 1

		EndIf

	EndIf
	Return 0

EndFunc

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

	For $k=4 to $responseFrameLenght
		$Sum += "0x"&Hex($responseFrameData[$k],2)

		If $debug Then
			ConsoleWrite($responseFrameData[$k] & " " & Hex($responseFrameData[$k],2) & " " & $Sum  & " " & Hex(Int($Sum),2) & @CRLF)
		EndIf
	Next

	If "0x"&Hex(Int($Sum),2) = 0xFF Then
		Return 1
	EndIf
	Return 0
EndFunc