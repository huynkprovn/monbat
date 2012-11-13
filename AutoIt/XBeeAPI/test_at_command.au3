#include 'XbeeAPI.au3'
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

Dim $AtCommandForm, $comport, $value, $Remote, $command, $remote16Dir, $remote64Dir, $SendButton, $label16, $label64, $output
Dim $nMsg

#Region ### START Koda GUI section ### Form=
$AtCommandForm = GUICreate("AtCommandForm", 578, 373, 192, 124)
$comport = GUICtrlCreateCombo("", 32, 40, 105, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$command = GUICtrlCreateInput("", 32, 104, 89, 21)
$value = GUICtrlCreateInput("", 32, 160, 89, 21)
$Remote = GUICtrlCreateCheckbox("Remote", 200, 56, 113, 17)
GUICtrlSetState(-1, 0)
$remote64Dir = GUICtrlCreateInput("", 200, 112, 113, 21)
GUICtrlSetState(-1,$GUI_HIDE)
$remote16Dir = GUICtrlCreateInput("", 200, 160, 113, 21)
GUICtrlSetState(-1,$GUI_HIDE)
$SendButton = GUICtrlCreateButton("Send", 400, 136, 137, 41)
$output = GUICtrlCreateEdit("", 24, 200, 537, 153)

GUICtrlCreateLabel("Puerto COM", 32, 24, 62, 17)
GUICtrlCreateLabel("AT Command", 32, 88, 68, 17)
GUICtrlCreateLabel("Value", 32, 144, 31, 17)
$label64 = GUICtrlCreateLabel("64 Bits Remote Address", 200, 96, 117, 17)
GUICtrlSetState(-1,$GUI_HIDE)
$label16 = GUICtrlCreateLabel("16 Bits Remote Address", 200, 144, 117, 17)
GUICtrlSetState(-1,$GUI_HIDE)

GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

Dim $portlist, $pl,$k

$portlist = _CommListPorts(0) ;find the available COM ports and write them into the COMportB combo
									;$portlist[0] contain the $portlist[] lenght

If @error = 1 Then
	MsgBox(0,'trouble getting portlist','Program will terminate!')
	Exit
EndIf


For $pl = 1 To $portlist[0]
	GUICtrlSetData($comport,$portlist[$pl]);add de list or detected COMportAs to the $COMportA combo
Next

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit

		Case $Remote
			If (GUICtrlRead($Remote) = $GUI_CHECKED) Then
				GUICtrlSetState($remote16Dir,$GUI_SHOW)
				GUICtrlSetState($remote64Dir,$GUI_SHOW)
				GUICtrlSetState($label16,$GUI_SHOW)
				GUICtrlSetState($label64,$GUI_SHOW)
			Else
				GUICtrlSetState($remote16Dir,$GUI_HIDE)
				GUICtrlSetState($remote64Dir,$GUI_HIDE)
				GUICtrlSetState($label16,$GUI_HIDE)
				GUICtrlSetState($label64,$GUI_HIDE)
			EndIf



		Case $SendButton
			_XbeeBegin(StringReplace(GUICtrlRead($comport),'COM',''), 9600)
			If (GUICtrlRead($Remote) = $GUI_CHECKED) Then

				_SetAddress64(GUICtrlRead($remote64Dir))
				_SetAddress16(GUICtrlRead($remote16Dir))

				If GUICtrlRead($value) <> "" Then
					_SendRemoteATCommand(GUICtrlRead($command),GUICtrlRead($value))
				Else
					_SendRemoteATCommand(GUICtrlRead($command))
				EndIf

				; Read the transmision status response
				$k = 1
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(300)  ;300 ms * 10 times = 3 sec
				WEnd

				For $k = 1 To $responseFrameLenght
					GUICtrlSetData($output, Hex($responseFrameData[$k],2),1)
					ConsoleWrite(Hex($responseFrameData[$k],2))
				Next
				GUICtrlSetData($output, @CRLF, 1)
				ConsoleWrite(@CRLF)
			Else

				If GUICtrlRead($value) <> "" Then
					_SendATCommand(GUICtrlRead($command),GUICtrlRead($value))
				Else
					_SendATCommand(GUICtrlRead($command))
				EndIf

				$k = 1
				While ((Not _CheckIncomingFrame()) And ($k < 10))
					$k += 1
					Sleep(300)
				WEnd

				For $k = 1 To $responseFrameLenght
					GUICtrlSetData($output, Hex($responseFrameData[$k],2),1)
					ConsoleWrite(Hex($responseFrameData[$k],2))
				Next
				GUICtrlSetData($output, @CRLF, 1)
				ConsoleWrite(@CRLF)
			EndIf

			; Read de AT Response (remote or not)


			_CommClosePort()



	EndSwitch
WEnd
