#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         myName

 Script Function:

 Version: 	0.1.3 	Add COM port config form.
					group all button event in the same handler function
			0.1.2  	Fixed error when cursor move over the button
			0.1.1	Add buttons for show alarms and label to display help of
					buttons actions
			0.1		Created main GUI
#ce ----------------------------------------------------------------------------


; LIBRERIAS
;#include '..\XbeeAPI\XbeeAPI.au3'
#include <array.au3>
#include <CommMG.au3>
#include <StaticConstants.au3>
#include <ProgressConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>

Opt("GUIOnEventMode", 1)

; ******** MAIN ************

Const $PROGRAM_VERSION = "0.1.2"

#cs
* ***************
*	MAIN FORM
* ***************
#ce
Global $GUIWidth = @DesktopWidth-20, $GUIHeight = @DesktopHeight-40
Global $ButtonWith = 40, $ButtonHeight = 40
Global $GUIWidthSpacer = 20, $GUIHeigthSpacer = 10

Global $myGui ; main GUI handler

Global $filemenu, $filemenu_open, $filemenu_exit, $filemenu_save, $filemenu_printpreview, $filemenu_print
Global $editmenu, $editmenu_copy, $editmenu_paste, $editmenu_cut
Global $configmenu, $configmenu_serialport, $configmenu_database
Global $testmenu, $testmenu_serialport, $testmenu_database
Global $helpmenu, $helpmenu_help, $helpmenu_about, $helpmenu_version ; form menu vars
Global $searchbutton, $readbutton, $viewbutton, $savebutton, $printbutton, $exitbutton ; button vars
Global $searchbuttonhelp, $readbuttonhelp, $viewbuttonhelp, $savebuttonhelp, $printbuttonhelp, $exitbuttonhelp; to display contextual help
Global $histotygraph ; Graph for histoy representation
Global $status ; to show the operation status
Global $charge ; to show the status charge of the current battery
Global $tempalarm, $chargealarm, $levelalarm, $emptyalarm ; to show the alarms produced in the current battery
Global $tempalarmbutton, $chargealarmbutton, $levelalarmbutton, $emptyalarmbutton ; to show the list of alarms
Global $tempalarmbuttonehelp, $chargealarmbuttonhelp, $levelalarmbuttonhelp, $emptyalarmbuttonhelp ; to display contextual help
Global $voltajecheck, $currentcheck, $levelcheck, $tempcheck ; to manage the data to visualize
Global $truckmodel, $truckserial, $batterymodel, $batteryserial ; represent the data of actual battery bein analized
; Form creation
$myGui = GUICreate("Traction batteries monitor system", $GUIWidth, $GUIHeight, 0, 0)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
;GUISetOnEvent($GUI_EVENT_MOUSEMOVE, "_MouseMove")
GUISetBkColor(0xf0f0f0)
GUISetState() ; Show the main GUI

; Form menu creation
$filemenu = GUICtrlCreateMenu("&File")
$filemenu_open = GUICtrlCreateMenuItem("Open",$filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$filemenu_save = GUICtrlCreateMenuItem("Save",$filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$filemenu_printpreview = GUICtrlCreateMenuItem("Print Preview", $filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$filemenu_print = GUICtrlCreateMenuItem("Print", $filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$filemenu_exit = GUICtrlCreateMenuItem("Exit", $filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$editmenu = GUICtrlCreateMenu("&Edit")
$editmenu_copy = GUICtrlCreateMenuItem("Copy",$editmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$editmenu_cut = GUICtrlCreateMenuItem("Cut", $editmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$editmenu_paste = GUICtrlCreateMenuItem("Paste", $editmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$configmenu = GUICtrlCreateMenu("&Config")
$configmenu_serialport = GUICtrlCreateMenuItem("Configure Serial Port", $configmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$configmenu_database = GUICtrlCreateMenuItem("Configure Database Access", $configmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$testmenu = GUICtrlCreateMenu("&Test")
$testmenu_serialport = GUICtrlCreateMenuItem("Test Serial Port Conection", $testmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$testmenu_database = GUICtrlCreateMenuItem("Test Database Conection", $testmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$helpmenu = GUICtrlCreateMenu("&?")
$helpmenu_help = GUICtrlCreateMenuItem("Help", $helpmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$helpmenu_about = GUICtrlCreateMenuItem("About", $helpmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$helpmenu_version = GUICtrlCreateMenuItem("Version", $helpmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")

; Buttons creation
Dim $buttonxpos = 0, $buttonypos = 0
$searchbutton = GUICtrlCreateButton("Batteries",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -23)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$searchbuttonhelp =GUICtrlCreateLabel("search batteries monitored in range", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$readbutton = GUICtrlCreateButton("Read Data",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -13)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$readbuttonhelp =GUICtrlCreateLabel("Read data from selected battery monitor memory", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$viewbutton = GUICtrlCreateButton("View History",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -94)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$viewbuttonhelp =GUICtrlCreateLabel("Select date range to show", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$savebutton = GUICtrlCreateButton("Save History",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -9)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$savebuttonhelp =GUICtrlCreateLabel("Save history in database", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$printbutton = GUICtrlCreateButton("Print",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -137)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$printbuttonhelp =GUICtrlCreateLabel("Print current history and alarms", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$exitbutton = GUICtrlCreateButton("Exit",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$exitbuttonhelp =GUICtrlCreateLabel("Exit the application", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)

; Status output creation
Dim $statusHeight = 50
$status = GUICtrlCreateEdit("",0,$GUIHeight - $statusHeight,$GUIWidth, $statusHeight)

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
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$tempalarmbuttonehelp = GUICtrlCreateLabel("Show temperature alarms", $buttonxpos - $ButtonWith/2, 2*$ButtonHeight + $chargeWhith + $GUIWidth/40 + 20)
GUICtrlSetState(-1,$GUI_HIDE)

$chargealarm = GUICtrlCreateLabel("Charge", $GUIWidth*3/4 + $GUIWidth/40 + $alarmwith, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos += $alarmwith
$chargealarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($chargealarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$chargealarmbuttonhelp = GUICtrlCreateLabel("Show charge cycle alarms", $buttonxpos - $ButtonWith/2, 2*$ButtonHeight + $chargeWhith + $GUIWidth/40 + 20)
GUICtrlSetState(-1,$GUI_HIDE)

$levelalarm = GUICtrlCreateLabel("Level", $GUIWidth*3/4 + $GUIWidth/40 + 2*$alarmwith, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos += $alarmwith
$levelalarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($levelalarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$levelalarmbuttonhelp = GUICtrlCreateLabel("Show electrolyte level alarms", $buttonxpos - $ButtonWith/2, 2*$ButtonHeight + $chargeWhith + $GUIWidth/40 + 20)
GUICtrlSetState(-1,$GUI_HIDE)

$emptyalarm = GUICtrlCreateLabel("Empty", $GUIWidth*3/4 + $GUIWidth/40 + 3*$alarmwith, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos += $alarmwith
$emptyalarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($emptyalarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$emptyalarmbuttonhelp = GUICtrlCreateLabel("Show voltage alarms", $buttonxpos - $ButtonWith/2, 2*$ButtonHeight + $chargeWhith + $GUIWidth/40 + 20)
GUICtrlSetState(-1,$GUI_HIDE)

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
Global $alarmform
Global $alarmoutput

$alarmform = GUICreate("Alarm List",400,600)
$alarmoutput = GUICtrlCreateEdit("", 10, 10, 380, 580)

#cs
* ***************
*	COM PORT SELEC FORM
* ***************
#ce
Global $comportselectform, $comportselct, $baudrateselct, $databitselect, $dataparityselect, $stopbitselect, $flowcontrolselect
Global $comselectokbutton, $comselectcancelbutton, $comselecthelpbutton

$comportselectform = GUICreate("COM port Selection", 366, 215, 314, 132)
GUICtrlCreateLabel("COM Port", 41, 15, 59, 25, $SS_CENTERIMAGE)
$comportselct = GUICtrlCreateCombo("", 96, 15, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlCreateLabel("Baud Rate", 40, 45, 59, 25, $SS_CENTERIMAGE)
$baudrateselct = GUICtrlCreateCombo("", 96, 45, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlCreateLabel("Data", 40, 75, 59, 25, $SS_CENTERIMAGE)
$databitselect = GUICtrlCreateCombo("", 96, 75, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlCreateLabel("Parity", 40, 105, 59, 25, $SS_CENTERIMAGE)
$dataparityselect = GUICtrlCreateCombo("dataparityselect", 96, 105, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlCreateLabel("Stop", 40, 135, 59, 25, $SS_CENTERIMAGE)
$stopbitselect = GUICtrlCreateCombo("stopbitselect", 96, 135, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlCreateLabel("Flow C.", 40, 165, 59, 25, $SS_CENTERIMAGE)
$flowcontrolselect = GUICtrlCreateCombo("", 96, 165, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
$comselectokbutton = GUICtrlCreateButton("Ok", 220, 16, 89, 33)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$comselectcancelbutton = GUICtrlCreateButton("Cancel", 220, 76, 89, 33)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$comselecthelpbutton = GUICtrlCreateButton("Help", 220, 140, 89, 33)
GUICtrlSetOnEvent(-1, "_ButtonClicked")


#cs
* ***************
*	VERSION FORM
* ***************
#ce
Dim $versionform
Dim $versionformokbutton

$versionform = GUICreate("Version", 200,150)
GUICtrlCreateLabel("Traction batteries monitor system" & @CRLF & "Version: " & $PROGRAM_VERSION, 10,10)
$versionformokbutton = GUICtrlCreateButton("Ok", 75, 110, 50, 30)
GUIctrlSetOnEvent(-1, "_ButtonClicked")


_Main()

Func _Main ()

	While 1

		Sleep(10)
	WEnd
EndFunc


;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CLOSEClicked ()
	Exit
EndFunc

;check if mouse is over a button to display a description
Func _MouseMove ()
	Local $mouseinfo

	$mouseinfo = GUIGetCursorInfo($myGui)
	If @error Then
		GUICtrlSetData($status,"e",1)
	Else
		Switch $mouseinfo[4]
			Case $searchbutton
				GUICtrlSetState($searchbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)
			Case $readbutton
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)
			Case $viewbutton
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)
			Case $savebutton
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_SHOW)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)
			Case $printbutton
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)
			Case $exitbutton
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)
			Case $tempalarmbutton
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_SHOW)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)
			Case $chargealarmbutton
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)
			Case $levelalarmbutton
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)
			Case $emptyalarmbutton
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_SHOW)
			case Else
				GUICtrlSetState($searchbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($readbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($viewbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($savebuttonhelp, $GUI_HIDE)
				GUICtrlSetState($printbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($exitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($tempalarmbuttonehelp, $GUI_HIDE)
				GUICtrlSetState($chargealarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($levelalarmbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($emptyalarmbuttonhelp, $GUI_HIDE)

		EndSwitch
	EndIf



EndFunc


Func _ButtonClicked ()
	Switch @GUI_CtrlId
		Case $searchbutton

		Case $readbutton

		Case $viewbutton

		Case $savebutton

		Case $printbutton

		Case $exitbutton
			Exit

		Case $tempalarmbutton
			GUISetState(@SW_DISABLE,$myGui)
			GUISetState(@SW_SHOW ,$alarmform)
			Sleep(2000)
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$alarmform)

		Case $levelalarmbutton
			GUISetState(@SW_DISABLE,$myGui)
			GUISetState(@SW_SHOW ,$alarmform)
			Sleep(2000)
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$alarmform)

		Case $chargealarmbutton
			GUISetState(@SW_DISABLE,$myGui)
			GUISetState(@SW_SHOW ,$alarmform)
			Sleep(2000)
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$alarmform)

		Case $emptyalarmbutton
			GUISetState(@SW_DISABLE,$myGui)
			GUISetState(@SW_SHOW ,$alarmform)
			Sleep(2000)
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$alarmform)

		Case $comselectokbutton

		Case $comselectcancelbutton

		Case $comselecthelpbutton

		case $versionformokbutton
			GUISetState(@SW_HIDE, $versionform)

		Case Else

	EndSwitch

EndFunc


Func _MenuClicked ()
	Switch @GUI_CTRLID
		Case $filemenu_open

		Case $filemenu_save

		Case $filemenu_printpreview

		Case $filemenu_print

		Case $filemenu_exit
			Exit

		Case $editmenu_copy

		Case $editmenu_cut

		Case $editmenu_paste

		Case $configmenu_serialport

		Case $configmenu_database

		Case $testmenu_serialport

		Case $testmenu_database

		Case $helpmenu_help

		Case $helpmenu_about

		Case $helpmenu_version
			GUISetState(@SW_SHOW,$versionform)

		Case Else

	EndSwitch

EndFunc

Func _VersionFormOkButtonClicked ()
	GUISetState(@SW_HIDE,$versionform)
EndFunc
