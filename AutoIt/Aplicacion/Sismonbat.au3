#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         myName

 Script Function:

 Version: 	0.1		Created main GUI
#ce ----------------------------------------------------------------------------


; LIBRERIAS
#include '..\XbeeAPI\XbeeAPI.au3'
#include <array.au3>
#include <CommMG.au3>
#include <StaticConstants.au3>
#include <ProgressConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>

Opt("GUIOnEventMode", 1)

; ******** MAIN ************


#cs
* ***************
*	MAIN FORM
* ***************
#ce
Global $GUIWidth = @DesktopWidth-20, $GUIHeight = @DesktopHeight-40
Global $ButtonWith = 40, $ButtonHeight = 40
Global $GUIWidthSpacer = 20, $GUIHeigthSpacer = 10

Global $myGui ; main GUI handler

Global $filemenu, $editmenu, $configmenu, $testmenu, $helpmenu ; form menu vars
Global $searchbutton, $readbutton, $viewbutton, $savebutton, $printbutton, $exitbutton ; button vars
Global $histotygraph ; Graph for histoy representation
Global $status ; to show the operation status
Global $charge ; to show the status charge of the current battery
Global $tempalarm, $chargealarm, $levelalarm, $emptyalarm ; to show the alarms produced in the current battery
Global $tempalarmbutton, $chargealarmbutton, $levelalarmbutton, $emptyalarmbutton ; to show the list of alarms
Global $voltajecheck, $currentcheck, $levelcheck, $tempcheck ; to manage the data to visualize
Global $truckmodel, $truckserial, $batterymodel, $batteryserial ; represent the data of actual battery bein analized
; Form creation
$myGui = GUICreate("Traction batteries monitor system", $GUIWidth, $GUIHeight, 0, 0)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
GUISetBkColor(0xf0f0f0)
GUISetState() ; Show the main GUI

; Form menu creation
$filemenu = GUICtrlCreateMenu("File")
$editmenu = GUICtrlCreateMenu("Edit")
$configmenu = GUICtrlCreateMenu("Config")
$testmenu = GUICtrlCreateMenu("Test")
$helpmenu = GUICtrlCreateMenu("?")

; Buttons creation
Dim $buttonxpos = 0, $buttonypos = 0
$searchbutton = GUICtrlCreateButton("Batteries",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -23)
$buttonxpos += $ButtonWith

$readbutton = GUICtrlCreateButton("Read Data",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -13)
$buttonxpos += $ButtonWith

$viewbutton = GUICtrlCreateButton("View History",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -94)
$buttonxpos += $ButtonWith

$savebutton = GUICtrlCreateButton("Save History",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -9)
$buttonxpos += $ButtonWith

$printbutton = GUICtrlCreateButton("Print",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -137)
$buttonxpos += $ButtonWith

$exitbutton = GUICtrlCreateButton("Exit",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)

; Status output creation
Dim $statusHeight = 50
$status = GUICtrlCreateEdit("Status output..." & @CRLF & "line 2",0,$GUIHeight - $statusHeight,$GUIWidth, $statusHeight)

; Checkbox to select data for display
Dim $checkboxheight = 15
Dim $checkboxwith = ($GUIWidth*3/16)
Dim $xpos = 0
GUICtrlCreateCheckbox("Voltage", $xpos ,$GUIHeight - $statusHeight - $checkboxheight, $checkboxwith, $checkboxheight)
$xpos += $checkboxwith
GUICtrlCreateCheckbox("Current", $xpos ,$GUIHeight - $statusHeight - $checkboxheight, $checkboxwith, $checkboxheight)
$xpos += $checkboxwith
GUICtrlCreateCheckbox("Level", $xpos ,$GUIHeight - $statusHeight - $checkboxheight, $checkboxwith, $checkboxheight)
$xpos += $checkboxwith
GUICtrlCreateCheckbox("Temperature", $xpos ,$GUIHeight - $statusHeight - $checkboxheight, $checkboxwith, $checkboxheight)

; History graphic creation
$histotygraph = GUICtrlCreateGraphic(0, $ButtonHeight, $GUIWidth*3/4, $GUIHeight-$ButtonHeight-$checkboxheight-$statusHeight, $SS_BLACKFRAME)

; Batery charge indicator creation
Dim $chargeWhith = $GUIWidth/4 - $GUIWidth/15
$charge = GUICtrlCreatePic(".\images\default.jpg", $GUIWidth*3/4 + $GUIWidth/30, $ButtonHeight, $chargeWhith, $chargeWhith)

; Alarm indicator creation
Dim $alarmwith = ($GUIWidth/4 - $GUIWidth/20) / 4
$tempalarm = GUICtrlCreateLabel("Temp", $GUIWidth*3/4 + $GUIWidth/40, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos = $GUIWidth*3/4 + $GUIWidth/40 + ($alarmwith - $ButtonWith)/2
$tempalarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($tempalarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent($tempalarmbutton, "_TempAlarmButtonAClick")

$chargealarm = GUICtrlCreateLabel("Charge", $GUIWidth*3/4 + $GUIWidth/40 + $alarmwith, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos += $alarmwith
$chargealarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($chargealarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent($chargealarmbutton, "_ChargeAlarmButtonAClick")

$levelalarm = GUICtrlCreateLabel("Level", $GUIWidth*3/4 + $GUIWidth/40 + 2*$alarmwith, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos += $alarmwith
$levelalarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($levelalarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent($levelalarmbutton, "_LevelAlarmButtonAClick")

$emptyalarm = GUICtrlCreateLabel("Empty", $GUIWidth*3/4 + $GUIWidth/40 + 3*$alarmwith, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos += $alarmwith
$emptyalarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($emptyalarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent($emptyalarmbutton, "_EmptyAlarmButtonAClick")

; Truck and battery model and serie information representation
Dim $ypos = 2*$ButtonHeight + $chargeWhith + $GUIWidth/40 + 20 + 50
Dim $labelspacer = ($GUIHeight - $statusHeight - $ypos)/4
Dim $labelwith = 70
$xpos = $GUIWidth*3/4 + $GUIWidth/40
GUICtrlCreateLabel("Truck model",$xpos, $ypos, $labelwith, 15)
$truckmodel = GUICtrlCreateLabel("",$xpos + $labelwith, $ypos, $GUIWidth - $GUIWidth/40 -($xpos+$labelwith),15)
GUICtrlSetBkColor(-1,0xffffff)
$ypos += $labelspacer
GUICtrlCreateLabel("Truck serial",$xpos, $ypos, $labelwith, 15)
$truckserial = GUICtrlCreateLabel("",$xpos + $labelwith, $ypos, $GUIWidth - $GUIWidth/40 -($xpos+$labelwith),15)
GUICtrlSetBkColor(-1,0xffffff)
$ypos += $labelspacer
GUICtrlCreateLabel("Battery model",$xpos, $ypos, $labelwith, 15)
$batterymodel = GUICtrlCreateLabel("",$xpos + $labelwith, $ypos, $GUIWidth - $GUIWidth/40 -($xpos+$labelwith),15)
GUICtrlSetBkColor(-1,0xffffff)
$ypos += $labelspacer
GUICtrlCreateLabel("Battery serial",$xpos, $ypos, $labelwith, 15)
$batteryserial = GUICtrlCreateLabel("",$xpos + $labelwith, $ypos, $GUIWidth - $GUIWidth/40 -($xpos+$labelwith),15)
GUICtrlSetBkColor(-1,0xffffff)

#cs
* ***************
*	ALARM VISUALIZATION FORM
* ***************
#ce
Dim $alarmform
Dim $alarmoutput

$alarmform = GUICreate("Alarm List",400,600)
$alarmoutput = GUICtrlCreateEdit("", 10, 10, 380, 580)

While 1
WEnd

;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CLOSEClicked ()
	Exit
EndFunc

Func _TempAlarmButtonAClick ()
	GUISetState(@SW_DISABLE,$myGui)
	GUISetState(@SW_SHOW ,$alarmform)
	Sleep(2000)
	GUISetState(@SW_ENABLE,$myGui)
	GUISetState(@SW_SHOW ,$myGui)
	GUISetState(@SW_HIDE,$alarmform)
EndFunc


Func _LevelAlarmButtonAClick ()
	GUISetState(@SW_DISABLE,$myGui)
	GUISetState(@SW_SHOW ,$alarmform)
	Sleep(2000)
	GUISetState(@SW_ENABLE,$myGui)
	GUISetState(@SW_SHOW ,$myGui)
	GUISetState(@SW_HIDE,$alarmform)
EndFunc


Func _ChargeAlarmButtonAClick ()
	GUISetState(@SW_DISABLE,$myGui)
	GUISetState(@SW_SHOW ,$alarmform)
	Sleep(2000)
	GUISetState(@SW_ENABLE,$myGui)
	GUISetState(@SW_SHOW ,$myGui)
	GUISetState(@SW_HIDE,$alarmform)

EndFunc


Func _EmptyAlarmButtonAClick ()
	GUISetState(@SW_DISABLE,$myGui)
	GUISetState(@SW_SHOW ,$alarmform)
	Sleep(2000)
	GUISetState(@SW_ENABLE,$myGui)
	GUISetState(@SW_SHOW ,$myGui)
	GUISetState(@SW_HIDE,$alarmform)

EndFunc