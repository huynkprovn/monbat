
#include <ButtonConstants.au3>
#include <DateTimeConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
Opt("GUIOnEventMode", 1)
#Region ### START Koda GUI section ### Form=
$Form1 = GUICreate("Form1", 615, 438, 192, 124)
GUISetOnEvent($GUI_EVENT_CLOSE, "Form1Close")
GUISetOnEvent($GUI_EVENT_MINIMIZE, "Form1Minimize")
GUISetOnEvent($GUI_EVENT_MAXIMIZE, "Form1Maximize")
GUISetOnEvent($GUI_EVENT_RESTORE, "Form1Restore")
$date = GUICtrlCreateDate("2012/10/10 22:51:35", 40, 24, 249, 33)
GUICtrlSetOnEvent(-1, "dateChange")
$battid = GUICtrlCreateInput("1", 48, 80, 65, 21)
GUICtrlSetOnEvent(-1, "battidChange")
$voltajeh = GUICtrlCreateInput("14.344", 48, 120, 89, 21)
GUICtrlSetOnEvent(-1, "voltajehChange")
$label = GUICtrlCreateLabel("voltajeh", 168, 120, 41, 17)
GUICtrlSetOnEvent(-1, "labelClick")
$batti = GUICtrlCreateLabel("batti", 160, 80, 24, 17)
GUICtrlSetOnEvent(-1, "battiClick")
$voltajel = GUICtrlCreateInput("14.344", 48, 160, 89, 21)
GUICtrlSetOnEvent(-1, "voltajelChange")
$Label1 = GUICtrlCreateLabel("voltajel", 168, 160, 37, 17)
GUICtrlSetOnEvent(-1, "Label1Click")
$amperaje = GUICtrlCreateInput("40.4", 48, 208, 89, 21)
GUICtrlSetOnEvent(-1, "amperajeChange")
$Label2 = GUICtrlCreateLabel("amperaje", 168, 208, 47, 17)
GUICtrlSetOnEvent(-1, "Label2Click")
$level = GUICtrlCreateRadio("level", 56, 256, 73, 25)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "levelClick")
$Label3 = GUICtrlCreateLabel("temperature", 168, 304, 60, 17)
GUICtrlSetOnEvent(-1, "Label3Click")
$temperature = GUICtrlCreateInput("40.4", 48, 304, 89, 21)
GUICtrlSetOnEvent(-1, "temperatureChange")
$okbutton = GUICtrlCreateButton("ok", 376, 64, 97, 41)
GUICtrlSetOnEvent(-1, "okbuttonClick")
$showbutton = GUICtrlCreateButton("show", 376, 128, 97, 41)
GUICtrlSetOnEvent(-1, "showbuttonClick")
$exitbutton = GUICtrlCreateButton("exit", 376, 208, 97, 33)
GUICtrlSetOnEvent(-1, "exitbuttonClick")
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

;$objErr = ObjEvent("AutoIt.Error","MyErrFunc")

#include "mysql.au3"

Global $username = "root"
Global $password = "monbat"
Global $database = "monbat"
Global $MySQLServerName = "localhost"

Global $SQLInstance
Global $SQLCode, $TableContents

$SQLInstance = _MySQLConnect($username, $password, $database, $MySQLServerName)



While 1
	Sleep(100)
WEnd

Func amperajeChange()

EndFunc
Func battiClick()

EndFunc
Func battidChange()

EndFunc
Func dateChange()

EndFunc
Func exitbuttonClick()
	_MySQLEnd($SQLInstance)
	Exit
EndFunc
Func Form1Close()
	_MySQLEnd($SQLInstance)
	Exit
EndFunc
Func Form1Maximize()

EndFunc
Func Form1Minimize()

EndFunc
Func Form1Restore()

EndFunc
Func Label1Click()

EndFunc
Func Label2Click()

EndFunc
Func Label3Click()

EndFunc
Func labelClick()

EndFunc
Func levelClick()

EndFunc
Func okbuttonClick()
	Local $data[9]
	Local $columns[9]

	$data[1] = GUICtrlRead($date)
	$data[2] = GUICtrlRead($battid)
	$data[3] = GUICtrlRead($voltajeh)
	$data[4] = GUICtrlRead($voltajel)
	$data[5] = GUICtrlRead($amperaje)
	$data[6] = GUICtrlRead($level)
	$data[7] = GUICtrlRead($temperature)
	$data[8] = ""

	$columns[1] = "fecha"
	$columns[2] = "battid"
	$columns[3] = "voltajeh"
	$columns[4] = "voltajel"
	$columns[5] = "amperaje"
	$columns[6] = "level"
	$columns[7] = "temperature"
	$columns[8] = ""
	Dim $fecha= "20121011233444"
	$vh= "23.2"

	$SQLCode = "INSERT INTO battsignals (voltajeh, level, temperature) VALUES (" & GUICtrlRead($voltajeh) & ", " & GUICtrlRead($level) & ", " & GUICtrlRead($temperature) & ")"
	ConsoleWrite($SQLCode & @CRLF)
	_Query($SQLInstance, $SQLCode)

EndFunc
Func showbuttonClick()

	$SQLCode = "SELECT * FROM battsignals"
	$TableContents = _Query($SQLInstance, $SQLCode)

	With $TableContents
		While Not .EOF
			ConsoleWrite(.Fields("fecha").value & ", " & .Fields("voltajeh").value & "V, " & .Fields("voltajel").value & "V")
			ConsoleWrite(", " & .Fields("temperature").value & "ºC" & @CRLF)
			.MoveNext
		WEnd
	EndWith

EndFunc
Func temperatureChange()

EndFunc
Func voltajehChange()

EndFunc
Func voltajelChange()

EndFunc
