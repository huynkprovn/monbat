#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Form1", 254, 168, 192, 124)
$Checkbox1 = GUICtrlCreateCheckbox("Checkbox1", 40, 32, 97, 17)
$Input1 = GUICtrlCreateInput("Input1", 40, 88, 121, 21)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

While 1
	If (GUICtrlRead($Checkbox1) = $GUI_CHECKED) Then
		GUICtrlSetData($Input1,"1")
		;MsgBox(0,"","set")
	Else
		GUICtrlSetData($Input1,"0")
		;MsgBox(0,"","unset")
	EndIf

WEnd
