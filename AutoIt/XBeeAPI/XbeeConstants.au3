;********* CONST DEFINITION

Const $MAX_FRAME_SIZE = 30;  72 data + 24 byte for a 0x12 Api command (Verify)
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

; Define Delivery STATUS constants. Returned in a TX Status API frame (0x8B)
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

; Define Discovery STATUS constants. Returned in a TX Status API frame (0x8B)
Const $NO_DISCOVERY_OVERHEAD = 0x00
Const $ADDRESS_DISCOVERY = 0x01
Const $ROUTE_DISCOVERY = 0x02
Const $ADDRESS_AND_ROUTE = 0x03
Const $EXTENDED_TIMEOUT_DISCOVERY = 0x40

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

Global $address64[8]
;Global $addressHight
;Global $addressLow
Global $address16[2]

Global $remoteAddress64[8]
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
Global $option = 0x00

; Used in ZigBee Transmit packect frame
Global $broadcastRadius = 0x00

; Used in AT command frame
Global $atCommand
Global $atCommandValue
; Used in AT Remote command frame
Global $ATOption = 0x02

; Used in RX status frames
Global $status


; Used in serial comm library
Global $sportSetError = ''


Func _PrintFrame()

	Local $msg

	$msg = ""
	Switch _GetApiID()

		Case $MODEM_STATUS_RESPONSE

			$msg &= "MStatus: "
			Switch _ReadModemStatus()
				Case $HARDWARE_RESET
					$msg &= "Hw Reset" & @CRLF
				Case $WATCHDOG_TIMER_RESET
					$msg &= "WD Timer Reset" & @CRLF
				Case $ASSOCIATED
					$msg &= "Associated" & @CRLF
				Case $DISASSOCIATED
					$msg &= "Diassociated" & @CRLF
				Case $SYNCHRONIZATION_LOST
					$msg &= "Sync Lost" & @CRLF
				Case $COORDINATOR_REALIGNMENT
					$msg &= "Coord Realignment" & @CRLF
				Case $COORDINATOR_STARTED
					$msg &= "Coord Started" & @CRLF
			EndSwitch


		Case $ZB_TX_STATUS_RESPONSE
			$msg &= "TxStatus: From: " & _ReadZBStatusReponseAddress16() & ", "
			Switch _ReadZBStatusReponseDeliveryStatus()
				Case $SUCCESS
					$msg &= "DeliveryST: Success, "
				Case $MAC_ACK_FAILURE
					$msg &= "DeliveryST: Mac Ack Failure, "
				Case $CCA_FAILURE
					$msg &= "DeliveryST: CCA Failure, "
				Case $INVALID_DESTINATION_ENDPOINT
					$msg &= "DeliveryST: Invalid Des Endpoint, "
				Case $NETWORK_ACK_FAILURE
					$msg &= "DeliveryST: Network ACK Failure, "
				Case $NOT_JOINED_TO_NETWORK
					$msg &= "DeliveryST: Not Joined to Net, "
				Case $SELF_ADDRESSED
					$msg &= "DeliveryST: Self Addressed, "
				Case $ADDRESS_NOT_FOUND
					$msg &= "DeliveryST: Addr Not Found, "
				Case $ROUTE_NOT_FOUND
					$msg &= "DeliveryST: Route Not Found, "
				Case $PAYLOAD_TOO_LARGE
					$msg &= "DeliveryST: Playload Too Large, "
				Case $INDIRECT_MESSAGE_UNREQUESTED
					$msg &= "DeliveryST: Indirect MSG Unreq, "
				Case Else
					$msg &= "DeliveryST: " & _ReadZBStatusReponseDeliveryStatus() & ", "
			EndSwitch

			Switch _ReadZBStatusReponseDiscoveryStatus()
				Case $NO_DISCOVERY_OVERHEAD
					$msg &= "DiscoveryST: No Discovery Overhead" & @CRLF
				Case $ADDRESS_DISCOVERY
					$msg &= "DiscoveryST: Addr Discovery" & @CRLF
				Case $ROUTE_DISCOVERY
					$msg &= "DiscoveryST: Route Discovery" & @CRLF
				Case $ADDRESS_AND_ROUTE
					$msg &= "DiscoveryST: Addr & Route" & @CRLF
				Case $EXTENDED_TIMEOUT_DISCOVERY
					$msg &= "DiscoveryST: Extend Timeout Discovery" & @CRLF
				Case Else
					$msg &= "DiscoveryST: " & _ReadZBStatusReponseDiscoveryStatus() & @CRLF
			EndSwitch


		Case $ZB_RX_RESPONSE
			$msg &= "DataRx: " & _ReadZBDataResponseValue()
			$msg &= " From: " & _ReadZBDataResponseAddress16() & " / " & _ReadZBDataResponseAddress64()
			$msg &= ", Rx Option: " & _ReadZBDataResponseOption() & @CRLF

		Case $AT_COMMAND_RESPONSE
			$msg &= "AtComRx: Command: " & _ReadATCommandResponseCommand()
			$msg &= ", Status: "
			Switch _ReadATCommandResponseStatus()
				Case 0
					$msg &= "OK, "
				Case 1
					$msg &= "ERROR, "
				Case 2
					$msg &= "Invalid Command, "
				Case 3
					$msg &= "Invalid Parameter, "
				Case 4
					$msg &= "Tx Failure, "
			EndSwitch

#cs
			Switch StringUpper(_ReadATCommandResponseCommand())
				Case "NI"
					$msg &= "Value: " & _BytestringToCharstring(_ReadATCommandResponseValue()) & @CRLF
				Case Else
					$msg &= "Value: " & _ReadATCommandResponseValue() & @CRLF

			EndSwitch
#ce
			$msg &= "Value: " & _ReadATCommandResponseValue() & @CRLF
		Case $REMOTE_AT_COMMAND_RESPONSE
			$msg &= "RAtComRx: "& @CRLF

	EndSwitch

	Return $msg


EndFunc


Func _BytestringToCharstring($string)
	Local $str
	Local $k
	$str =""
	For $k=1 To StringLen($string)/2
		$str &= Chr(StringMid($string,$k*2-1,2))
	Next
	Return $str
EndFunc