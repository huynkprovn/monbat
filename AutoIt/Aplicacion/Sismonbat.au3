#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Antonio Morales Ruiz

 Script Function:

 Version:
			0.22.0	Add battery selection when writing to battsignals in database. not checked.
			0.21.2	Select from database with battery identification now work.
			0.21.1	Tab changes don't work. Change to severals forms
			0.21.0	Add battery selection when reading from database. Don't work
			0.20.0	Add track and battery identification data send
			0.19.0	Add X-axis values and some explaining labels
			0.18.3	Fix bugs in draw() funct
			0.18.2	expand the options range for x axis cursors. Can display data from several days
			0.18.1	Now works x axis zoom and x axis scroll separately
			0.18.0	Modify graphic representation. Don´t use dynamic resize array to improve the rendering performance
			0.17.4	Add checking receiving zbrxframe or resend if fail to "reset mem" and "send local time" functions
			0.17.3	Add checking receiving zbrxframe or resend if fail.
			0.17.2	Add checking status of tx data frame and resend if fail.
			0.17.1	Fix error in display function. Old data were displayed when new samples were reading.
			0.17.0	Add read from database functionality and read from database form.
			0.16.0 	Print sensor values from non periodic sampling method. Adapt methods for cursors
			0.15.0  Add save to database functionality. Date is saved in UNIX format. same error obtained saving in mysql "timestamp" format
			0.14.0	Add time sending functionality
			0.13.1	Fix a bug in reading process
			0.13.0  Add MySQL access parameters
			0.12.0	Reading sensors values from Arduino. Adjust scale in graphics. Create funct for physical values conversion
					Add date to the cursors position
			0.11.1	Change config file for a ini file to store serial port, database access and other config parameters
			0.11.0	Add config.cfg file for save comport and database parameters
			0.10.0	Add funtionality in search monitor form. Now scan for monitors and read theirs identifications values to show the list
			0.9.0	Add samples reading functionality.
			0.8.1	Fix error in vertical offset. Add label for date at cursors representation
			0.8.0	Add dynamic sensor value representation at cursor pos. Different buttons for scale x and y axis
			0.7.0	Add rules value dynamically adjusting
			0.6.2	Fix error. Draw out the graphics
			0.6.1	Show and hide values when cursors are visible or hidden
			0.6.0	Add Label for sensor measurements at cursor pos
			0.5.0 	Add Cursos and buttons icon
			0.4.0	Add Grid and rule with values. TODO dinamic asignation of rule value
			0.3.3 	Fix error with cursors buttons
			0.3.2	Fix error when printing the graphics with multiple forms app. GUISwitch($myGui) needed
			0.3.1	Add buttons to scale and move graphics. Error Don�t print the graphics
			0.3.0	add functionality to the graphic (in progress). TODO: add buttons to scale and move graphics. add cursors
			0.2.0	Add Comport connection functionality in the comportselectform. Add a new form for detecting xbee moden in coordinator range.
					Add Xbee modems search functionality in the $searchform, and modems address representation in it.
			0.1.5	Add DDBB config and Hardware monitor identification form
			0.1.4	Add functionality to COM port select form
			0.1.3 	Add COM port config form.
					group all button event in the same handler function
			0.1.2  	Fixed error when cursor move over the button
			0.1.1	Add buttons for show alarms and label to display help of
					buttons actions
			0.1		Created main GUI
#ce ----------------------------------------------------------------------------


; LIBRERIAS
#include '..\XbeeAPI\XbeeAPI.au3'
#include <array.au3>
#include <CommMG.au3>
#include <StaticConstants.au3>
#include <ProgressConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GuiListView.au3>
#include <GuiTab.au3>
#include <Date.au3>
#include <Misc.au3>    ; For mouse click detection handle
#include '..\libs\mysql\mysql.au3'




Opt("GUIOnEventMode", 1)

; ******** MAIN ************

Const $PROGRAM_VERSION = "0.21.0"
Const $ConfigFile = "Sismonbat.ini" ; File where store last com port configuration and database access

#cs
* ***************
*	MAIN FORM
* ***************
#ce

;$dllpath = "commg.dll"

Switch @OSArch
	Case "X64"
		_CommSetDllPath("c:\windows\syswow64\commg.dll")
	Case Else
		_CommSetDllPath("c:\windows\system32\commg.dll")
EndSwitch

Global $comport, $baudrate, $databit, $parity, $stopbit, $flowcontrol, $sportSetError, $serialconnected ; to manage the serial port conection

$comport = IniRead($ConfigFile, "COMPortConfig", "Port","")
$baudrate = IniRead($ConfigFile, "COMPortConfig", "BaudRate","")
$databit = IniRead($ConfigFile, "COMPortConfig", "DabaBits","")
$parity = IniRead($ConfigFile, "COMPortConfig", "ParityBits","")
$stopbit = IniRead($ConfigFile, "COMPortConfig", "StopBits","")
$flowcontrol = IniRead($ConfigFile, "COMPortConfig", "FlowControl","")

Global $username, $password, $database, $MySQLServerName    ; To manage the database connection
$username = IniRead($ConfigFile, "DatabaseConfig", "user","")
$password = IniRead($ConfigFile, "DatabaseConfig", "pass","")
$database = IniRead($ConfigFile, "DatabaseConfig", "DataBaseName","")
$MySQLServerName = IniRead($ConfigFile, "DatabaseConfig", "server", "")


Global $SQLInstance
Global $SQLCode, $TableContents

$SQLInstance = _MySQLConnect($username, $password, $database, $MySQLServerName)


Const $GUIWidth = @DesktopWidth-20, $GUIHeight = @DesktopHeight-40
Const $ButtonWith = 40, $ButtonHeight = 40
Const $GUIWidthSpacer = 20, $GUIHeigthSpacer = 10

Const $GET_ID = "01"
Const $RESET_ALARMS = "02"
Const $SET_TRUCK_MODEL = "03"
Const $SET_TRUCK_SN = "04"
Const $SET_BATT_MODEL = "05"
Const $SET_BATT_SN = "06"
Const $SET_BATT_CAPACITY = "61"
Const $CALIBRATE = "07"
Const $SET_TIME = "08"
Const $READ_MEMORY = "10"
Const $RESET_MEM = "99"

Global $myGui ; main GUI handler

Global $filemenu, $filemenu_open, $filemenu_exit, $filemenu_save, $filemenu_printpreview, $filemenu_print
Global $editmenu, $editmenu_copy, $editmenu_paste, $editmenu_cut
Global $configmenu, $configmenu_serialport, $configmenu_database, $configmenu_hardware, $configmenu_reset, $configmenu_settime
Global $testmenu, $testmenu_serialport, $testmenu_database
Global $helpmenu, $helpmenu_help, $helpmenu_about, $helpmenu_version ; form menu vars
Global $searchbutton, $readbutton, $viewbutton, $savebutton, $printbutton, $exitbutton ; button vars
Global $searchbuttonhelp, $readbuttonhelp, $viewbuttonhelp, $savebuttonhelp, $printbuttonhelp, $exitbuttonhelp; to display contextual help
Global $zoominYbutton, $zoomoutYbutton, $zoominXbutton, $zoomoutXbutton, $zoomfitbutton, $showcursorsbutton, $showgridbutton
Global $zoominYbuttonhelp, $zoomoutYbuttonhelp, $zoominXbuttonhelp, $zoomoutXbuttonhelp, $zoomfitbuttonhelp,$showcursorsbuttonhelp, $showgridbuttonhelp
Global $historygraph[5] ; Graph for histoy representation. One graph for each sensor
Global $status ; to show the operation status
Global $charge ; to show the status charge of the current battery
Global $tempalarm, $chargealarm, $levelalarm, $emptyalarm ; to show the alarms produced in the current battery
Global $tempalarmbutton, $chargealarmbutton, $levelalarmbutton, $emptyalarmbutton ; to show the list of alarms
Global $tempalarmbuttonehelp, $chargealarmbuttonhelp, $levelalarmbuttonhelp, $emptyalarmbuttonhelp ; to display contextual help
Global $voltajecheck, $currentcheck, $levelcheck, $tempcheck ; to manage the data to visualize
Global $truckmodel, $truckserial, $batterymodel, $batteryserial ; represent the data of actual battery bein analized
Global $addr64, $addr16 ; represent the address for the actual modem in battery bein analized
Global $response ; manage the msgbox pressed button

#cs
* ***************
*	SCAN MONITORIZED BATTERIES FORM
* ***************
#ce
Global $searchform, $monitorlist, $searchmonitorconnectbutton, $searchmonitorscanbutton
Global $monitor64addr, $monitor16addr
Global $monitorfounded[1][6]    ;the list of search of found
Global $count

$searchform = GUICreate("Truck/Battery Selection", 825, 443, 192, 124)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
;$monitorlist = GUICtrlCreateList("", 40, 48, 241, 331)
;GUICtrlSetData(-1, "H2X386U34432|W4X131R05445|W4X131S00453")  ; Testing only
$monitorlist = GUICtrlCreateListView("", 40, 48, 741, 331,-1, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_SUBITEMIMAGES))
_GUICtrlListView_InsertColumn($monitorlist,0,"64 Bits ADDR", 125)
_GUICtrlListView_InsertColumn($monitorlist,1,"16 Bits ADDR", 75)
_GUICtrlListView_InsertColumn($monitorlist,2,"Truck Model", 125)
_GUICtrlListView_InsertColumn($monitorlist,3,"Truck S/N", 125)
_GUICtrlListView_InsertColumn($monitorlist,4,"Battery Model", 125)
_GUICtrlListView_InsertColumn($monitorlist,5,"Battery S/N", 125)
_GUICtrlListView_SetItemCount($monitorlist, 40)       ; allocate memory for 40 rows in the listview control for prevent allocation every time a item is added

$searchmonitorscanbutton = GUICtrlCreateButton("Scan", 40, 400, 75, 25)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$searchmonitorconnectbutton = GUICtrlCreateButton("Connect", 208, 400, 75, 25)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
GUICtrlCreateLabel("Detected trucks/batteries monitorized ", 40, 8, 234, 34, BitOR($SS_CENTER,$SS_CENTERIMAGE))


#cs
* ***************
*	SELECT FROM DATABASE FORM
* ***************
#ce
Global $selectidform, $selectdateform
Global $batterylist[1][5]    ;the list of batteries stored in database for select one
Global $monitortab, $datetab, $myTab, $batteryidlist, $batteryID
Global $selecidNext, $selectidCancel, $selectidScan
Global $ini, $ini_h, $ini_m, $end, $end_h, $end_m, $selectDatePrev, $selectDateCancel, $selectDateOk
Global $ini_date, $end_date

$batteryID = 0
#Region ### START Koda GUI section ###
$selectidform = GUICreate("Select battery to show", 666, 464, 192, 124)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")

$batteryidlist = GUICtrlCreateListView("", 20, 40, 666-40, 338,-1, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_SUBITEMIMAGES))
_GUICtrlListView_InsertColumn($batteryidlist,0,"Id", 50)
_GUICtrlListView_InsertColumn($batteryidlist,1,"Truck Model", 125)
_GUICtrlListView_InsertColumn($batteryidlist,2,"Truck S/N", 125)
_GUICtrlListView_InsertColumn($batteryidlist,3,"Battery Model", 125)
_GUICtrlListView_InsertColumn($batteryidlist,4,"Battery S/N", 125)
_GUICtrlListView_SetItemCount($batteryidlist, 40)       ; allocate memory for 40 rows in the listview control for prevent allocation every time a item is added

$selectidScan= GUICtrlCreateButton("Scan", 70 , 388, 129, 41)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$selectidCancel = GUICtrlCreateButton("Cancel", 265 , 388, 129, 41)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$selecidNext = GUICtrlCreateButton("Next", 460, 388, 129, 41)
GUICtrlSetOnEvent(-1, "_ButtonClicked")

$selectdateform = GUICreate("Select date range to show", 666, 464, 192, 124)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
GUICtrlCreateGroup("", 24, 60, 297, 297)
$ini = GUICtrlCreateMonthCal("2013/02/14", 48, 100, 249, 177)
$ini_h = GUICtrlCreateInput("", 48, 300, 81, 21, $GUI_SS_DEFAULT_INPUT);BitOR($GUI_SS_DEFAULT_INPUT,$ES_READONLY))
GUICtrlSetOnEvent(-1,"_imputBoxChange")
GUICtrlCreateUpdown($ini_h)
$ini_m = GUICtrlCreateInput("", 176, 300, 81, 21, $GUI_SS_DEFAULT_INPUT);BitOR($GUI_SS_DEFAULT_INPUT,$ES_READONLY))
GUICtrlSetOnEvent(-1,"_imputBoxChange")
GUICtrlCreateUpdown($ini_m)
GUICtrlCreateLabel("Day", 48, 76, 23, 17)
GUICtrlCreateLabel("Hour", 48, 284, 27, 17)
GUICtrlCreateLabel("Minute", 176, 284, 36, 17)

GUICtrlCreateGroup("", 336, 60, 297, 297)
$end = GUICtrlCreateMonthCal("2013/02/14", 360, 100, 249, 177)
$end_h = GUICtrlCreateInput("", 360, 300, 81, 21, $GUI_SS_DEFAULT_INPUT);BitOR($GUI_SS_DEFAULT_INPUT,$ES_READONLY))
GUICtrlSetOnEvent(-1,"_imputBoxChange")
GUICtrlCreateUpdown($end_h)
$end_m = GUICtrlCreateInput("", 488, 300, 81, 21, $GUI_SS_DEFAULT_INPUT);BitOR($GUI_SS_DEFAULT_INPUT,$ES_READONLY))
GUICtrlSetOnEvent(-1,"_imputBoxChange")
GUICtrlCreateUpdown($end_m)
GUICtrlCreateLabel("Day", 360, 76, 23, 17)
GUICtrlCreateLabel("Hour", 360, 284, 27, 17)
GUICtrlCreateLabel("Minute", 488, 284, 36, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)

$selectDatePrev= GUICtrlCreateButton("Prev", 70 , 388, 129, 41)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$selectDateCancel = GUICtrlCreateButton("Cancel", 265, 388, 129, 41)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$selectDateOk = GUICtrlCreateButton("Ok", 460, 388, 129, 41)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
GUICtrlCreateLabel("INITIAL DATE", 120, 44, 88, 20)
GUICtrlSetFont(-1, 10, 400, 0, "MS Sans Serif")
GUICtrlCreateLabel("END DATE", 440, 44, 73, 20)
GUICtrlSetFont(-1, 10, 400, 0, "MS Sans Serif")
GUICtrlCreateTabItem("")
#EndRegion ### END Koda GUI section ###

#cs
* ***************
*	ALARM VISUALIZATION FORM
* ***************
#ce
Global $alarmform
Global $alarmoutput

$alarmform = GUICreate("Alarm List",400,600)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
$alarmoutput = GUICtrlCreateEdit("", 10, 10, 380, 580)

#cs
* ***************
*	COM PORT SELECT FORM
* ***************
#ce
Global $comportselectform, $comportselect, $baudrateselct, $databitselect, $dataparityselect, $stopbitselect, $flowcontrolselect
Global $comselectokbutton, $comselectcancelbutton, $comselecthelpbutton

$comportselectform = GUICreate("COM port Selection", 366, 215, 314, 132)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
GUICtrlCreateLabel("COM Port", 41, 15, 59, 25, $SS_CENTERIMAGE)
$comportselect = GUICtrlCreateCombo("", 96, 15, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlCreateLabel("Baud Rate", 40, 45, 59, 25, $SS_CENTERIMAGE)
$baudrateselct = GUICtrlCreateCombo("", 96, 45, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlSetData(-1,"300|600|1200|2400|4800|9600|14400|19200|38400|57600|115200", "9600")
GUICtrlCreateLabel("Data", 40, 75, 59, 25, $SS_CENTERIMAGE)
$databitselect = GUICtrlCreateCombo("", 96, 75, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlSetData(-1,"7 bits|8 bits", "8 bits")
GUICtrlCreateLabel("Parity", 40, 105, 59, 25, $SS_CENTERIMAGE)
$dataparityselect = GUICtrlCreateCombo("", 96, 105, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlSetData(-1, "none|even|odd|mark|space", "none")
GUICtrlCreateLabel("Stop", 40, 135, 59, 25, $SS_CENTERIMAGE)
$stopbitselect = GUICtrlCreateCombo("", 96, 135, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlSetData(-1,"1 bit|1,5 bits|2 bits","1 bit")
GUICtrlCreateLabel("Flow C.", 40, 165, 59, 25, $SS_CENTERIMAGE)
$flowcontrolselect = GUICtrlCreateCombo("", 96, 165, 81, 25, BitOR($CBS_DROPDOWN,$CBS_AUTOHSCROLL))
GUICtrlSetData(-1,"Hardware|Xon/Xoff|none","none")
$comselectokbutton = GUICtrlCreateButton("&Ok", 220, 16, 89, 33)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$comselectcancelbutton = GUICtrlCreateButton("&Cancel", 220, 76, 89, 33)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$comselecthelpbutton = GUICtrlCreateButton("&Help", 220, 140, 89, 33)
GUICtrlSetOnEvent(-1, "_ButtonClicked")


#cs
* ***************
*	DATABASE ACCESS CONFIG FORM
* ***************
#ce
Global $databaseconfigform, $databaseselectokbutton, $databaseselectcancelbutton, $databaseselecthelpbutton
Global $databaseselectdatabase, $databaseselectuser, $databaseselectpassword

$databaseconfigform = GUICreate("Database access configuration", 367, 216, 304, 119)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
GUICtrlCreateLabel("Database", 25, 8, 50, 17)
$databaseselectdatabase = GUICtrlCreateInput("", 25, 24, 313, 21)
GUICtrlCreateLabel("User", 25, 56, 26, 17)
$databaseselectuser = GUICtrlCreateInput("", 25, 72, 313, 21)
GUICtrlCreateLabel("Password", 25, 104, 50, 17)
$databaseselectpassword = GUICtrlCreateInput("", 25, 120, 313, 21, BitOR($GUI_SS_DEFAULT_INPUT,$ES_PASSWORD))
$databaseselectokbutton = GUICtrlCreateButton("&OK", 25, 160, 89, 32)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$databaseselectcancelbutton = GUICtrlCreateButton("&Cancel", 136, 160, 89, 32)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$databaseselecthelpbutton = GUICtrlCreateButton("&Help", 248, 160, 89, 32)
GUICtrlSetOnEvent(-1, "_ButtonClicked")

#cs
* ***************
*	HARDWARE DATA CONFIG FORM
* ***************
#ce
Global $hardwaredataform, $dataconfigtruckmodel, $dataconfigtruckserial, $dataconfigbatterymodel, $dataconfigbatteryserial
Global $dataconfigcancelbutton, $dataconfigokbutton, $dataconfighelpbutton

$hardwaredataform = GUICreate("Hardware monitor identifiacion values", 367, 216, 313, 163)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
GUICtrlCreateGroup("Truck Data", 24, 8, 153, 137)
GUICtrlCreateLabel("Model", 31, 32, 33, 17)
$dataconfigtruckmodel = GUICtrlCreateInput("", 31, 48, 137, 21)
$dataconfigtruckserial = GUICtrlCreateInput("", 31, 104, 137, 21)
GUICtrlCreateLabel("Serial", 31, 88, 30, 17)
;GUICtrlCreateGroup("", -99, -99, 1, 1)
GUICtrlCreateGroup("Battery Data", 184, 8, 153, 137)
GUICtrlCreateLabel("Model", 191, 32, 33, 17)
$dataconfigbatterymodel = GUICtrlCreateInput("", 191, 48, 137, 21)
GUICtrlCreateLabel("Serial", 191, 88, 33, 17)
$dataconfigbatteryserial = GUICtrlCreateInput("", 191, 104, 137, 21)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$dataconfigcancelbutton = GUICtrlCreateButton("&Cancel", 136, 160, 89, 32)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$dataconfigokbutton = GUICtrlCreateButton("&OK", 25, 160, 89, 32)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$dataconfighelpbutton = GUICtrlCreateButton("&Help", 248, 160, 89, 32)
GUICtrlSetOnEvent(-1, "_ButtonClicked")


#cs
* ***************
*	VERSION FORM
* ***************
#ce
Global $versionform
Global $versionformokbutton

$versionform = GUICreate("Version", 200,150)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
GUICtrlCreateLabel("Traction batteries monitor system" & @CRLF & "Version: " & $PROGRAM_VERSION, 10,10)
$versionformokbutton = GUICtrlCreateButton("Ok", 75, 110, 50, 30)
GUIctrlSetOnEvent(-1, "_ButtonClicked")



; Form creation
$myGui = GUICreate("Traction batteries monitor system", $GUIWidth, $GUIHeight, 5, 5)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
GUISetOnEvent($GUI_EVENT_MOUSEMOVE, "_MouseMove")
GUISetBkColor(0xf0f0f0)
GUISetState() ; Show the main GUI

; Form menu creation
$filemenu = GUICtrlCreateMenu("&File")
$filemenu_open = GUICtrlCreateMenuItem("&Open",$filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$filemenu_save = GUICtrlCreateMenuItem("&Save",$filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$filemenu_printpreview = GUICtrlCreateMenuItem("Pr&int Preview", $filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$filemenu_print = GUICtrlCreateMenuItem("&Print", $filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$filemenu_exit = GUICtrlCreateMenuItem("&Exit", $filemenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$editmenu = GUICtrlCreateMenu("&Edit")
$editmenu_copy = GUICtrlCreateMenuItem("&Copy",$editmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$editmenu_cut = GUICtrlCreateMenuItem("&Cut", $editmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$editmenu_paste = GUICtrlCreateMenuItem("&Paste", $editmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$configmenu = GUICtrlCreateMenu("&Config")
$configmenu_serialport = GUICtrlCreateMenuItem("Configure &Serial Port", $configmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$configmenu_database = GUICtrlCreateMenuItem("Configure &Database Access", $configmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$configmenu_hardware = GUICtrlCreateMenuItem("&Set Monitor Identification", $configmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$configmenu_reset = GUICtrlCreateMenuItem("&Reset Monitor Memory", $configmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$configmenu_settime = GUICtrlCreateMenuItem("Send local &time to monitor", $configmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$testmenu = GUICtrlCreateMenu("&Test")
$testmenu_serialport = GUICtrlCreateMenuItem("Test &Serial Port Conection", $testmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$testmenu_database = GUICtrlCreateMenuItem("Test &Database Conection", $testmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$helpmenu = GUICtrlCreateMenu("&?")
$helpmenu_help = GUICtrlCreateMenuItem("&Help", $helpmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$helpmenu_about = GUICtrlCreateMenuItem("&About", $helpmenu)
GUICtrlSetOnEvent(-1, "_MenuClicked")
$helpmenu_version = GUICtrlCreateMenuItem("&Version", $helpmenu)
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
$buttonxpos += $ButtonWith*8

$zoominYbutton = GUICtrlCreateButton("Zoom In",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_BITMAP)
GUICtrlSetImage(-1, ".\images\zoomin.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$zoominYbuttonhelp =GUICtrlCreateLabel("Zoom In Vertical Axix", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$zoomoutYbutton = GUICtrlCreateButton("Zoom Out",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_BITMAP)
GUICtrlSetImage(-1, ".\images\zoomout.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$zoomoutYbuttonhelp =GUICtrlCreateLabel("Zoom Out Vertical Axix", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$zoominXbutton = GUICtrlCreateButton("Zoom In",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_BITMAP)
GUICtrlSetImage(-1, ".\images\zoomin.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$zoominXbuttonhelp =GUICtrlCreateLabel("Zoom In Horiontal Axix", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$zoomoutXbutton = GUICtrlCreateButton("Zoom Out",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_BITMAP)
GUICtrlSetImage(-1, ".\images\zoomout.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$zoomoutXbuttonhelp =GUICtrlCreateLabel("Zoom Out Horizontal Axix", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$zoomfitbutton = GUICtrlCreateButton("Zoom Fit",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_BITMAP)
GUICtrlSetImage($zoomfitbutton, ".\images\zoom100.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$zoomfitbuttonhelp =GUICtrlCreateLabel("Zoom Fit", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$showcursorsbutton = GUICtrlCreateButton("Show Cursors",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_BITMAP)
GUICtrlSetImage(-1, ".\images\cursor.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$showcursorsbuttonhelp =GUICtrlCreateLabel("Show Cursors", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$showgridbutton = GUICtrlCreateButton("Show Grid",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_BITMAP)
GUICtrlSetImage(-1, ".\images\grid.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$showgridbuttonhelp =GUICtrlCreateLabel("Show Grid", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
Global $grid = False


Const $statusHeight = 50

; Checkbox to select data for display
Const $checkboxheight = 15
Const $checkboxwith = ($GUIWidth*3/16)

Dim $xpos = 0
$voltajecheck = GUICtrlCreateCheckbox("Voltage", $xpos ,$GUIHeight - $statusHeight - $checkboxheight-3);, $checkboxwith, $checkboxheight)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$xpos += $checkboxwith
$currentcheck = GUICtrlCreateCheckbox("Current", $xpos ,$GUIHeight - $statusHeight - $checkboxheight-3);, $checkboxwith, $checkboxheight)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$xpos += $checkboxwith
$tempcheck = GUICtrlCreateCheckbox("Temperature", $xpos ,$GUIHeight - $statusHeight - $checkboxheight-3);, $checkboxwith, $checkboxheight)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$xpos += $checkboxwith
$levelcheck = GUICtrlCreateCheckbox("Level", $xpos ,$GUIHeight - $statusHeight - $checkboxheight-3);, $checkboxwith, $checkboxheight)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "_ButtonClicked")

Global $sensorvalue[4][2]  ; Respresentation of sensors values at current cursors position
$xpos = 0
$sensorvalue[0][0] = GUICtrlCreateLabel("C1:xx.xxV", $xpos + 80, $GUIHeight - $statusHeight - $checkboxheight);, $checkboxwith, $checkboxheight)
GUICtrlSetColor(-1,0xff0000)
GUICtrlSetState(-1, $GUI_HIDE)
$sensorvalue[0][1] = GUICtrlCreateLabel("C2:xx.xxV", $xpos + 140, $GUIHeight - $statusHeight - $checkboxheight);, $checkboxwith, $checkboxheight)
GUICtrlSetColor(-1,0xff0000)
GUICtrlSetState(-1, $GUI_HIDE)
$xpos += $checkboxwith
$sensorvalue[1][0] = GUICtrlCreateLabel("C1:xxx.xA", $xpos + 80, $GUIHeight - $statusHeight - $checkboxheight);, $checkboxwith, $checkboxheight)
GUICtrlSetColor(-1,0x14ce00)
GUICtrlSetState(-1, $GUI_HIDE)
$sensorvalue[1][1] = GUICtrlCreateLabel("C2:xxx.xA", $xpos + 140, $GUIHeight - $statusHeight - $checkboxheight);, $checkboxwith, $checkboxheight)
GUICtrlSetColor(-1,0x14ce00)
GUICtrlSetState(-1, $GUI_HIDE)
$xpos += $checkboxwith
$sensorvalue[2][0] = GUICtrlCreateLabel("C1:+xx.xºC", $xpos + 80, $GUIHeight - $statusHeight - $checkboxheight);, $checkboxwith, $checkboxheight)
GUICtrlSetColor(-1,0x0000ff)
GUICtrlSetState(-1, $GUI_HIDE)
$sensorvalue[2][1] = GUICtrlCreateLabel("C2:-xx.xºC", $xpos + 140, $GUIHeight - $statusHeight - $checkboxheight);, $checkboxwith, $checkboxheight)
GUICtrlSetColor(-1,0x0000ff)
GUICtrlSetState(-1, $GUI_HIDE)
$xpos += $checkboxwith
$sensorvalue[3][0] = GUICtrlCreateLabel("C1: Ok", $xpos + 80, $GUIHeight - $statusHeight - $checkboxheight);, $checkboxwith, $checkboxheight)
GUICtrlSetColor(-1,0xff00ff)
GUICtrlSetState(-1, $GUI_HIDE)
$sensorvalue[3][1] = GUICtrlCreateLabel("C2: No Ok", $xpos + 140, $GUIHeight - $statusHeight - $checkboxheight);, $checkboxwith, $checkboxheight)
GUICtrlSetColor(-1,0xff00ff)
GUICtrlSetState(-1, $GUI_HIDE)

; Status output creation
$status = GUICtrlCreateEdit("",0,$GUIHeight - $statusHeight,$GUIWidth, $statusHeight)

; History graphic creation
Global $xmax = Int($GUIWidth*3/4)
Global $ymax	= Int($GUIHeight-$ButtonHeight-$checkboxheight-$statusHeight)
Global $sensor[6][1] ; sensors signals for representation [date,v+,v-,a,t,l]
Global $offset[5] = [-Int($ymax/4), -Int($ymax/4),Int($ymax/2),Int($ymax/10),Int($ymax/2)]; offset off each sensor representation
Global $yscale[5] = [25,25,1,10,1]	 ; scale of each sensor representation
Global $colours[5] = [0xff0000, 0x000000, 0x14ce00, 0x0000ff, 0xff00ff] ; Sensor representation colours
Global $visible[5] = [True,True,True,True,True]
Global $xscale
Global $screen[6][$xmax] ; For display the sensors signal in graphic control. Used instead $sensor[][] because periodic samples are needed
					; for expand/contract and cursors fucntionality

;********************** ONLY FOR TEST ***** REMOVE
#cs ReDim $sensor[6][$xmax/4] ; redim
be used by +1 when receiving each sensor sample

For $k = 0 To $xmax/4 -1
	$sensor[0][$k] = $k * 2
Next

For $k = 0 To $xmax/4 -1
	$sensor[1][$k] = 12+5*Sin($k/50)
Next

For $k = 0 To $xmax/4 -1
	$sensor[2][$k] = 11.5+5*Sin($k/50)
Next

Dim $inc = 2
Dim $val = 0
For $k = 0 To $xmax/4 -1

	$sensor[3][$k] = $val
	If $val > 150 Then
		$inc = -2
	ElseIf $val < -150 Then
		$inc = 2
	EndIf
	$val = $val + $inc
Next

For $k = 0 To $xmax/4 -1
	$sensor[4][$k] = 25+20*Cos($k/30)
Next
;***************************************** REMOVE
#ce

Global $xoff_m, $xoff_p, $yoff_m, $yoff_p

$xoff_m = GUICtrlCreateButton("",$xmax - 80,$ButtonHeight,20,20,$BS_BITMAP)
GUICtrlSetImage($xoff_m, ".\images\left.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$xoff_p = GUICtrlCreateButton("",$xmax - 60,$ButtonHeight,20,20,$BS_BITMAP)
GUICtrlSetImage($xoff_p, ".\images\right.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$yoff_p = GUICtrlCreateButton("",$xmax - 20,$ButtonHeight + 0, 20, 20,$BS_BITMAP)
GUICtrlSetImage($yoff_p, ".\images\up.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$yoff_m = GUICtrlCreateButton("",$xmax - 20,$ButtonHeight + 20, 20, 20,$BS_BITMAP)
GUICtrlSetImage($yoff_m, ".\images\down.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")

Global $rules
$rules = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER)
_DrawRules()

Global $grid
$grid = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax)
_DrawGrid()
Global $gridvisible = False
GUICtrlSetState($grid, $GUI_HIDE)

Global $timesValue[4]
Global $rulesValue[3][9]
For $k=0 to 8
	$rulesValue[0][$k] = GUICtrlCreateLabel("V", 1, $ButtonHeight + $ymax +5 - ($k+1)*$ymax/10, 40)
	GUICtrlSetColor(-1,$colours[0])
Next
For $k=0 to 8
	$rulesValue[1][$k] = GUICtrlCreateLabel("A", $xmax - 40, $ButtonHeight + $ymax +5 - ($k+1)*$ymax/10,39)
	GUICtrlSetColor(-1,$colours[2])
	$rulesValue[2][$k] = GUICtrlCreateLabel("ºC", $xmax + 3, $ButtonHeight + $ymax +5 - ($k+1)*$ymax/10, 40)
	GUICtrlSetColor(-1,$colours[3])
Next
For $k=0 to 3
	$timesValue[$k] = GUICtrlCreateLabel("XX/XX/XXXX XX:XX:XX", 2*($k+1)*$xmax/10-50, $ButtonHeight+15)
	GUICtrlSetColor(-1,0x7f7f7f)
Next

Global $xoffset = 0
Global $yoffset = 0
Global $xgain = 1
Global $ygain = 1

Global $cursor[2]
$cursor[0] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER)
$cursor[1] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER)

Global $cursor1 = ($xmax-1)/4		; the cursors x pos and his initial value
Global $cursor2 = 3*($xmax-1)/4
Global $cursorvisible = False
_DrawCursors()
GUICtrlSetState($cursor[0], $GUI_HIDE)
GUICtrlSetState($cursor[1], $GUI_HIDE)

$historygraph[0] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax);, $WS_BORDER) ;V+
$historygraph[1] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax);, $WS_BORDER) ;V-
$historygraph[2] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax);, $WS_BORDER) ;A
$historygraph[3] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax);, $WS_BORDER) ;T
$historygraph[4] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax);, $WS_BORDER) ;L

Global $cursor1date, $cursor2date
$cursor1date=GUICtrlCreateLabel("C1: 23/05/2012 11:23:34", $xmax/5, $ymax+15)
GUICtrlSetColor(-1,0xff0000)
GUICtrlSetState(-1, $GUI_HIDE)
$cursor2date=GUICtrlCreateLabel("C2: 23/05/2012 11:54:20", $xmax*3/5, $ymax+15)
GUICtrlSetState(-1, $GUI_HIDE)
GUICtrlSetColor(-1,0x0000ff)

; Batery charge indicator creation
Const $chargeWhith = $GUIWidth/4 - $GUIWidth/15
GUICtrlCreateLabel("State Of Charge",$GUIWidth*3/4 + $GUIWidth/30 + $chargeWhith/2 - 40, $ButtonHeight/2)
$charge = GUICtrlCreatePic(".\images\default.jpg", $GUIWidth*3/4 + $GUIWidth/30, $ButtonHeight, $chargeWhith, $chargeWhith)

; Alarm indicator creation
Const $alarmwith = ($GUIWidth/4 - $GUIWidth/20) / 4
$tempalarm = GUICtrlCreateLabel("Temp", $GUIWidth*3/4 + $GUIWidth/40, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos = $GUIWidth*3/4 + $GUIWidth/40 + ($alarmwith - $ButtonWith)/2
$tempalarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($tempalarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$tempalarmbuttonehelp = GUICtrlCreateLabel("Show temperature alarms", $buttonxpos - $ButtonWith, 2*$ButtonHeight + $chargeWhith + $GUIWidth/40 + 20)
GUICtrlSetState(-1,$GUI_HIDE)

$chargealarm = GUICtrlCreateLabel("Charge", $GUIWidth*3/4 + $GUIWidth/40 + $alarmwith, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos += $alarmwith
$chargealarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($chargealarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$chargealarmbuttonhelp = GUICtrlCreateLabel("Show charge cycle alarms", $buttonxpos - $ButtonWith, 2*$ButtonHeight + $chargeWhith + $GUIWidth/40 + 20)
GUICtrlSetState(-1,$GUI_HIDE)

$levelalarm = GUICtrlCreateLabel("Level", $GUIWidth*3/4 + $GUIWidth/40 + 2*$alarmwith, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos += $alarmwith
$levelalarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($levelalarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$levelalarmbuttonhelp = GUICtrlCreateLabel("Show electrolyte level alarms", $buttonxpos - $ButtonWith, 2*$ButtonHeight + $chargeWhith + $GUIWidth/40 + 20)
GUICtrlSetState(-1,$GUI_HIDE)

$emptyalarm = GUICtrlCreateLabel("Empty", $GUIWidth*3/4 + $GUIWidth/40 + 3*$alarmwith, $ButtonHeight + $chargeWhith + $GUIWidth/40, $alarmwith, 20,$SS_CENTER)
$buttonxpos += $alarmwith
$emptyalarmbutton = GUICtrlCreateButton( "1", $buttonxpos , $ButtonHeight + $chargeWhith + $GUIWidth/40 + 20, $ButtonWith, $ButtonHeight, $BS_BITMAP)
GUICtrlSetImage($emptyalarmbutton, ".\images\noalarm.bmp")
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$emptyalarmbuttonhelp = GUICtrlCreateLabel("Show voltage alarms", $buttonxpos - $ButtonWith, 2*$ButtonHeight + $chargeWhith + $GUIWidth/40 + 20)
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



_Main()

Func _Main ()

	;Local $hDLL = DllOpen("user32.dll")
	Local $pos[2]

	_Draw()
	While 1
		If $cursorvisible Then
			If _IsPressed("01") Then
				$pos = MouseGetPos()
				GUICtrlSetData($status, $pos[0] & " , " & $pos[1] & " , " & $ButtonHeight)
				If (($pos[0]>$xmax-10) Or ($pos[1]<130) Or ($pos[1]>($ButtonHeight+$ymax))) Then   ; 90 is the upper form border/ 130 is under the offset button
				Else
					$cursor1 = $pos[0]-8											; 8 = the form border
					_DrawCursors()
				EndIf

				While _IsPressed("01")
					Sleep(10)
				Wend
			ElseIf _IsPressed("02") Then
				$pos = MouseGetPos()
				If (($pos[0]>$xmax-10) Or ($pos[1]<130) Or ($pos[1]>($ButtonHeight+$ymax))) Then
				Else
					$cursor2 = $pos[0]-8
					_DrawCursors()
				EndIf
				While _IsPressed("02")
					Sleep(10)
				Wend
			EndIf
		EndIf
		Sleep(200)
	WEnd

EndFunc


;***************************************************************************************************
;
;
;***************************************************************************************************
Func _CLOSEClicked ()
	Switch @GUI_WINHANDLE
		Case $myGui
			If ($serialconnected) Then      ;If a serial port is open close it before exit application
				_CommClosePort()
			EndIf
			_MySQLEnd($SQLInstance)
			Exit

		Case $versionform
			GUISetState(@SW_HIDE, $versionform)

		Case $alarmform
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$alarmform)

		Case $comportselectform
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$comportselectform)

		Case $hardwaredataform
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$hardwaredataform)

		Case $databaseconfigform
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$databaseconfigform)

		Case $searchform
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$searchform)

		Case $selectidform
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$selectidform)

		Case $selectdateform
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$selectdateform)


		Case Else

	EndSwitch

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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
			Case $zoominYbutton
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
			Case $zoominXbutton
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
			Case $zoomoutYbutton
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
			Case $zoomoutXbutton
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
			Case $zoomfitbutton
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
			Case $showcursorsbutton
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_SHOW)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)
			Case $showgridbutton
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_SHOW)
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
				GUICtrlSetState($zoominYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoominXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutYbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomoutXbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($zoomfitbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showcursorsbuttonhelp, $GUI_HIDE)
				GUICtrlSetState($showgridbuttonhelp, $GUI_HIDE)

		EndSwitch
	EndIf



EndFunc


Func _ButtonClicked ()

	Local $k ; General counter
	Local $dat ;
	Local $res ; Byte to byte char conversion
	Local $dato ;
	Local $Time, $Time1 ; Used for delay calculation in XBee transmisions/responses
	Local $first
	Local $received ; a status ok frame is received
	Local $times ; Used for control the resend xbee frame

	Switch @GUI_CtrlId

		Case $searchbutton
			GUISetState(@SW_DISABLE,$myGui)
			GUISetState(@SW_SHOW ,$searchform)
			If (NoT $serialconnected) Then
				$response = MsgBox(1,"COM Port not selected","There is not a serial connection with a COM port." & @CRLF & "Press ´OK´ for use the last configuration used, or press ´NO´ for manual configuration")
				GUICtrlSetData($status, $response & @CRLF)
				If $response = 1 Then
					_CommSetPort($comport, $sportSetError, $baudrate, $databit, $parity, $stopbit, $flowcontrol) ; Open the port

					;TODO look for error in com connection. Now ok connection is assumed
					$serialconnected = True
				Else
					GUISetState(@SW_ENABLE,$myGui)
					GUISetState(@SW_SHOW ,$myGui)
					GUISetState(@SW_HIDE,$searchform)
				EndIf
			EndIf

		Case $searchmonitorscanbutton				;SCAN FOR XBEE MODEM IN RANGE
			ReDim $monitorfounded [1][6] ; prevent show old searched
			_GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($monitorlist)) ; Clear previous printed list

			_SetAddress64("000000000000FFFF")  ;Send a broadcast remote AT request with the "AI" command
			_SetAddress16("FFFE")				; All associated Xbee modem send to coordinator a response frame
			_SendRemoteATCommand("AI")
			Sleep(1000)

			$count = 1 				; Reset the variable for counting detected monitors
			While _CheckIncomingFrame()  ; Catch the modem response and store theirs address
				If (_GetApiID() = $REMOTE_AT_COMMAND_RESPONSE) Then
					ReDim $monitorfounded [$count][6]
					$monitorfounded[$count-1][0]=_ReadRemoteATCommandResponseAddress64()
					$monitorfounded[$count-1][1]=_ReadRemoteATCommandResponseAddress16()
					$count += 1
				EndIf
			WEnd

			; Ask each searched modem for theirs identification data
			For $count = 0 To (UBound($monitorfounded,1)-1)
				_SetAddress64($monitorfounded[$count][0])
				_SetAddress16($monitorfounded[$count][1])
				GUICtrlSetData($status, @CRLF & "Conecting with :" & $monitorfounded[$count][0] & " / " & $monitorfounded[$count][1] & "      ", 1)

				$first = True
				$times = 1
				While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
					_SendZBData($GET_ID)

					ConsoleWrite(@CRLF & "count = " & $count)

					$Time = TimerInit()
					While ((TimerDiff($Time)/1000) <= 1 )  ; Wait until a zb data packet is received or 1second
						GUICtrlSetData($status, ".", 1)
						If _CheckIncomingFrame() Then
							GUICtrlSetData($status, "-", 1)
							If _GetApiID() == $ZB_RX_RESPONSE Then
								GUICtrlSetData($status, "/", 1)
								$received=True
								$dato = _ReadZBDataResponseValue() ; Extract the data sent by the arduino
								If StringMid($dato, 1, 2) = $GET_ID Then		; The data is a response for a GET_ID frame request
									Switch StringMid($dato, 3, 2)
										Case "01"
											$res=""
											For $k = 3 to (StringLen($dato)-1)/2
												$res &= Chr("0x"&StringMid($dato,2*$k-1 ,2))
											Next
											ConsoleWrite(@CRLF & "count = " & $count)
											$monitorfounded[$count][2] = $res

										Case "02"
											$res=""
											For $k = 3 to (StringLen($dato)-1)/2
												$res &= Chr("0x"&StringMid($dato,2*$k-1 ,2))
											Next
											$monitorfounded[$count][3] = $res

										Case "03"
											$res=""
											For $k = 3 to (StringLen($dato)-1)/2
												$res &= Chr("0x"&StringMid($dato,2*$k-1 ,2))
											Next
											$monitorfounded[$count][4] = $res

										Case "04"
											$res=""
											For $k = 3 to (StringLen($dato)-1)/2
												$res &= Chr("0x"&StringMid($dato,2*$k-1 ,2))
											Next
											$monitorfounded[$count][5] = $res

									EndSwitch

									$Time = TimerInit() ; Reset the time counter
								EndIf
							EndIf
						EndIf
						Sleep(100)
					WEnd
					$times+=1
				Wend
			Next
			_GUICtrlListView_AddArray($monitorlist, $monitorfounded)


		Case $searchmonitorconnectbutton
			$addr64 = $monitorfounded[_GUICtrlListView_GetSelectedIndices($monitorlist)][0]
			$addr16 = $monitorfounded[_GUICtrlListView_GetSelectedIndices($monitorlist)][1]
			_SetAddress64($addr64)
			_SetAddress16($addr16)


			$first = True
			$times = 1
			While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
				_SendZBData($GET_ID)
				;ConsoleWrite(@CRLF & "count = " & $count)

				$Time = TimerInit()
				While ((TimerDiff($Time)/1000) <= 1 )  ; Wait until a zb data packet is received or 1second
					GUICtrlSetData($status, ".", 1)
					If _CheckIncomingFrame() Then
						GUICtrlSetData($status, "-", 1)
						If _GetApiID() == $ZB_RX_RESPONSE Then
							GUICtrlSetData($status, "/", 1)
							$received=True
							$dato = _ReadZBDataResponseValue() ; Extract the data sent by the arduino
							If StringMid($dato, 1, 2) = $GET_ID Then		; The data is a response for a GET_ID frame request
								Switch StringMid($dato, 3, 2)
									Case "01"
										$res=""
										For $k = 3 to (StringLen($dato)-1)/2
											$res &= Chr("0x"&StringMid($dato,2*$k-1 ,2))
										Next
										GUICtrlSetData($truckmodel, $res)

									Case "02"
										$res=""
										For $k = 3 to (StringLen($dato)-1)/2
											$res &= Chr("0x"&StringMid($dato,2*$k-1 ,2))
										Next
										GUICtrlSetData($truckserial, $res)

									Case "03"
										$res=""
										For $k = 3 to (StringLen($dato)-1)/2
											$res &= Chr("0x"&StringMid($dato,2*$k-1 ,2))
										Next
										GUICtrlSetData($batterymodel, $res)

									Case "04"
										$res=""
										For $k = 3 to (StringLen($dato)-1)/2
											$res &= Chr("0x"&StringMid($dato,2*$k-1 ,2))
										Next
										GUICtrlSetData($batteryserial, $res)

								EndSwitch

								$Time = TimerInit() ; Reset the time counter
							EndIf
						EndIf
					EndIf
					Sleep(100)
				WEnd
				$times+=1
			Wend



			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$searchform)


		Case $readbutton
			_SetAddress64($addr64)
			_SetAddress16($addr16)
			$first = True
			$received = False
			ReDim $sensor[6][1]

			$times=1
			#cs
			While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
				_SendZBData($READ_MEMORY) ; Send the READ_MEMORY_COMMAND to the arduino
				Sleep(750)
				If _CheckIncomingFrame() Then        ; check if the frame is received or resend
					ConsoleWrite(_PrintFrame() & @CRLF)
					If (_GetApiID() = $ZB_TX_STATUS_RESPONSE) Then
						If (_ReadZBStatusReponseDeliveryStatus() = $SUCCESS) Then
							$received = True
						EndIf
					EndIf
				EndIf
			WEnd
			#ce

			;If $received Then
			While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
				_SendZBData($READ_MEMORY) ; Send the READ_MEMORY_COMMAND to the arduino
				$Time = TimerInit()
				While ((TimerDiff($Time)/1000) <= 0.75 )  ; Wait until a zb data packet is received or 750ms
					GUICtrlSetData($status, ".", 1)
					If _CheckIncomingFrame() Then
						ConsoleWrite(_PrintFrame() & @CRLF)
						GUICtrlSetData($status, "-", 1)
						If _GetApiID() == $ZB_RX_RESPONSE Then
							GUICtrlSetData($status, "/", 1)
							$received = True
							$dato = _ReadZBDataResponseValue() ; Extract the data sent by the arduino
							If StringMid($dato, 1, 2) = $READ_MEMORY Then		; The data is a response for a READ_MEMORY_COMMAND frame request
								;ReDim $sensor[6][UBound($sensor,2)+1]		; add space for the received data
								If $first Then			; if array has only 1 cell write the data in it, in other case
									$first = False
								Else
									ReDim $sensor[6][UBound($sensor,2)+1]		; add space for the next data
								EndIf
								$sensor[0][UBound($sensor,2)-1] = Int(_convert(StringMid($dato, 3, 8)))
								$sensor[1][UBound($sensor,2)-1] = _voltaje(Dec(StringMid($dato,11, 4)))
								$sensor[2][UBound($sensor,2)-1] = _voltaje(Dec(StringMid($dato,15, 4)))
								$sensor[3][UBound($sensor,2)-1] = _current(Dec(StringMid($dato,19, 4)))
								$sensor[4][UBound($sensor,2)-1] = _temperature(Dec(StringMid($dato,23, 4)))
								$sensor[5][UBound($sensor,2)-1] = StringMid($dato,27, 2)
								$Time = TimerInit() ; Reset the time counter
							EndIf
						EndIf
					EndIf
					Sleep(1)
				WEnd
				$times+=1
			WEnd
			;_ArrayDisplay($sensor, "")
			GUICtrlSetData($status, @CRLF, 1)
			_Draw()

		Case $viewbutton
			GUISetState(@SW_SHOW ,$selectidform)

		Case $selectidScan
			$SQLCode = "SELECT * FROM batteries"
			$TableContents = _Query($SQLInstance, $SQLCode)
			ReDim $batterylist[1][5]
			_GUICtrlListView_DeleteAllItems(GUICtrlGetHandle($batteryidlist)) ; Clear previous printed list

			$first = True
			With $TableContents
				While Not .EOF
					If $first Then			; if array has only 1 cell write the data in it, in other case
						$first = False
					Else
						ReDim $batterylist[UBound($batterylist,1)+1][5]		; add space for the next data
					EndIf

					$batterylist[UBound($batterylist,1)-1][0] = .Fields("battid").value
					$batterylist[UBound($batterylist,1)-1][1] = .Fields("truckmodel").value
					$batterylist[UBound($batterylist,1)-1][2] = .Fields("truckserial").value
					$batterylist[UBound($batterylist,1)-1][3] = .Fields("battmodel").value
					$batterylist[UBound($batterylist,1)-1][4] = .Fields("battserial").value

					.MoveNext
				WEnd
			EndWith
			_GUICtrlListView_AddArray($batteryidlist,  $batterylist)

		Case $selecidNext
			$batteryID = $batterylist[_GUICtrlListView_GetSelectedIndices($batteryidlist)][0]
			;MsgBox(0,"","Selected " & $batteryID & " battery id")
			GUISetState(@SW_SHOW,$selectdateform)
			GUISetState(@SW_HIDE,$selectidform)

		Case $selectDatePrev
			GUISetState(@SW_SHOW,$selectidform)
			GUISetState(@SW_HIDE,$selectdateform)

		Case $selectDateCancel
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$selectdateform)

		Case $selectidCancel
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$selectidform)

		Case $selectDateOk
			$ini_date = _DateDiff('s', "1970/01/01 00:00:00", GUICtrlRead($ini) & " " & GUICtrlRead($ini_h) & ":" & GUICtrlRead($ini_m) & ":00")
			$end_date = _DateDiff('s', "1970/01/01 00:00:00", GUICtrlRead($end) & " " & GUICtrlRead($end_h) & ":" & GUICtrlRead($end_m) & ":00")

			If ($ini_date >= $end_date) Then
				MsgBox(0,"Invalid date range","The selected date range is invalid" & @CRLF & "Initial date must be before the end date")
			Else
				$SQLCode = "SELECT * FROM battsignals WHERE battid = "
				;$SQLCode &= "BETWEEN " & $ini_date & " && " & $end_date & " " & "ORDER BY fecha ASC"
				$SQLCode &= $batteryID & " && " & "fecha >= " & $ini_date & " && " & "fecha <= " & $end_date & " " & "ORDER BY fecha ASC"
				ConsoleWrite($SQLCode & @CRLF)
				$TableContents = _Query($SQLInstance, $SQLCode)

				$first = True
				ReDim $sensor[6][1]

				With $TableContents
					While Not .EOF

						If $first Then			; if array has only 1 cell write the data in it, in other case
							$first = False
						Else
							ReDim $sensor[6][UBound($sensor,2)+1]		; add space for the next data
						EndIf

						$sensor[0][UBound($sensor,2)-1] = .Fields("fecha").value
						$sensor[1][UBound($sensor,2)-1] = .Fields("voltajeh").value
						$sensor[2][UBound($sensor,2)-1] = .Fields("voltajel").value
						$sensor[3][UBound($sensor,2)-1] = .Fields("amperaje").value
						$sensor[4][UBound($sensor,2)-1] = .Fields("temperature").value
						$sensor[5][UBound($sensor,2)-1] = 1

						.MoveNext
					WEnd
				EndWith
				;_ArrayDisplay($sensor, "")

				GUISetState(@SW_ENABLE,$myGui)
				GUISetState(@SW_SHOW ,$myGui)
				GUISetState(@SW_HIDE,$selectdateform)
			EndIf

		Case $savebutton

			If UBound($sensor,2) > 1 Then
				; Check if the battery exist in batteries table
				$SQLCode = 'SELECT battid FROM batteries WHERE truckmodel = "' & $truckmodel
				$SQLCode &= '" && truckserial = "' & $truckserial
				$SQLCode &= '" && battmodel = "' & $batterymodel
				$SQLCode &= '" && battserial = "' & $batteryserial
				ConsoleWrite($SQLCode & @CRLF)
				$TableContents = _Query($SQLInstance, $SQLCode)

				If $TableContents.EOF then ; Querry is empty
					; Insert the battery data in table
					$SQLCode = 'INSERT INTO batteries (truckmodel, truckserial, battmodel, battserial) VALUES('
					$SQLCode &= '"' & $truckmodel & '", "' & $truckserial & '", "' & $batterymodel & '", "' & $batteryserial & '")'
					ConsoleWrite($SQLCode & @CRLF)
					_Query($SQLInstance, $SQLCode)
					; Get the battery id
					$SQLCode = 'SELECT battid FROM batteries WHERE truckmodel = "' & $truckmodel
					$SQLCode &= '" && truckserial = "' & $truckserial
					$SQLCode &= '" && battmodel = "' & $batterymodel
					$SQLCode &= '" && battserial = "' & $batteryserial
					ConsoleWrite($SQLCode & @CRLF)
					$TableContents = _Query($SQLInstance, $SQLCode)
					$batteryID = $TableContents.Fields("battid").value
				Else
					$batteryID = $TableContents.Fields("battid").value
				EndIf

				For $k = 0 To (UBound($sensor,2)-1) Step 1
					$SQLCode = "INSERT INTO battsignals (fecha, battid, voltajeh, voltajel, amperaje, temperature, level) VALUES (" & $sensor[0][$k] & ", " & $batteryID & ", " & $sensor[1][$k] & ", "  & $sensor[2][$k] & ", "  & $sensor[3][$k] & ", "  & $sensor[4][$k] & ", "  & True & ")"
					$SQLCode &= " ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id)"    ;Don`t work Error with querry sentence ¿?¿?¿?
					;$SQLCode = "INSERT INTO battsignals (battid, voltajeh, voltajel, amperaje, temperature, level) VALUES (" & "01" & ", " & $sensor[1][$k] & ", "  & $sensor[2][$k] & ", "  & $sensor[3][$k] & ", "  & $sensor[4][$k] & ", "  & True & ")"
					ConsoleWrite($SQLCode & @CRLF)
					_Query($SQLInstance, $SQLCode) 		;TODO: check success in database write
				Next
			EndIf


		Case $printbutton


		Case $exitbutton
			If ($serialconnected) Then      ;If a serial port is open close it before exit application
				_CommClosePort()
			EndIf
			_MySQLEnd($SQLInstance)
			Exit


		Case $voltajecheck
			If (GUICtrlRead($voltajecheck) = $GUI_CHECKED) Then
				$visible[0] = True
				$visible[1] = True
			Else
				$visible[0] = False
				$visible[1] = False
			EndIf
			_Draw()
			_ShowCursorsValues()

		Case $currentcheck
			If (GUICtrlRead($currentcheck) = $GUI_CHECKED) Then
				$visible[2] = True
			Else
				$visible[2] = False
			EndIf
			_Draw()
			_ShowCursorsValues()

		Case $tempcheck
			If (GUICtrlRead($tempcheck) = $GUI_CHECKED) Then
				$visible[3] = True
			Else
				$visible[3] = False
			EndIf
			_Draw()
			_ShowCursorsValues()

		Case $levelcheck
			If (GUICtrlRead($levelcheck) = $GUI_CHECKED) Then
				$visible[4] = True
			Else
				$visible[4] = False
			EndIf
			_Draw()
			_ShowCursorsValues()

		Case $zoominXbutton
			Switch $xgain
				Case 0.01
					$xgain = 0.02
				Case 0.02
					$xgain = 0.05
				Case 0.05
					$xgain = 0.1
				Case 0.1
					$xgain = 0.2
				Case 0.2
					$xgain = 0.25
				Case 0.25
					$xgain = 0.33
				Case 0.33
					$xgain = 0.5
				Case 0.5
					$xgain = 1
				Case 1
					$xgain = 2
				Case 2
					$xgain = 3
				Case 3
					$xgain = 4
				Case 4
					$xgain = 5
			EndSwitch
			GUISwitch($myGui)
			_Draw()
			_DrawCursors()

		Case $zoomoutXbutton
			Switch $xgain
				Case 0.02
					$xgain = 0.01
				Case 0.05
					$xgain = 0.02
				Case 0.1
					$xgain = 0.05
				Case 0.2
					$xgain = 0.1
				Case 0.25
					$xgain = 0.2
				Case 0.33
					$xgain = 0.25
				Case 0.5
					$xgain = 0.33
				Case 1
					$xgain = 0.5
				Case 2
					$xgain = 1
				Case 3
					$xgain = 2
				Case 4
					$xgain = 3
				Case 5
					$xgain = 4
			EndSwitch
			GUISwitch($myGui)
			_Draw()
			_DrawCursors()

		Case $zoominYbutton
			Switch $ygain
				Case 0.2
					$ygain = 0.25
				Case 0.25
					$ygain = 0.33
				Case 0.33
					$ygain = 0.5
				Case 0.5
					$ygain = 1
				Case 1
					$ygain = 2
				Case 2
					$ygain = 3
				Case 3
					$ygain = 4
				Case 4
					$ygain = 5
			EndSwitch
			GUISwitch($myGui)
			_Draw()
			_DrawCursors()

		Case $zoomoutYbutton
			Switch $ygain
				Case 0.25
					$ygain = 0.2
				Case 0.33
					$ygain = 0.25
				Case 0.5
					$ygain = 0.33
				Case 1
					$ygain = 0.5
				Case 2
					$ygain = 1
				Case 3
					$ygain = 2
				Case 4
					$ygain = 3
				Case 5
					$ygain = 4
			EndSwitch
			GUISwitch($myGui)
			_Draw()
			_DrawCursors()

		Case $zoomfitbutton
			GUISwitch($myGui)
			$xoffset = 0
			$yoffset = 0
			$xgain = 1
			$ygain = 1
			_Draw()
			_DrawCursors()

		Case $showcursorsbutton
			If $cursorvisible Then
				GUICtrlSetState($cursor[0], $GUI_HIDE)
				GUICtrlSetState($cursor[1], $GUI_HIDE)
				GUICtrlSetState($cursor1date, $GUI_HIDE)
				GUICtrlSetState($cursor2date, $GUI_HIDE)
				$cursorvisible = False
			Else
				GUICtrlSetState($cursor[0], $GUI_SHOW)
				GUICtrlSetState($cursor[1], $GUI_SHOW)
				GUICtrlSetState($cursor1date, $GUI_SHOW)
				GUICtrlSetState($cursor2date, $GUI_SHOW)
				$cursorvisible = True
				_DrawCursors()
			EndIf
			_ShowCursorsValues()

		Case $showgridbutton
			If $gridvisible Then
				GUICtrlSetState($grid, $GUI_HIDE)
				$gridvisible = False
			Else
				GUICtrlSetState($grid, $GUI_SHOW)
				_DrawGrid()
				$gridvisible = True
			EndIf

		Case $xoff_p
			$xoffset -= 100
			GUISwitch($myGui)
			_Draw()
			_DrawCursors()
		Case $xoff_m
			$xoffset += 100
			GUISwitch($myGui)
			_Draw()
			_DrawCursors()
		Case $yoff_p
			$yoffset += 50
			GUISwitch($myGui)
			_Draw()
			_DrawCursors()
		Case $yoff_m
			GUISwitch($myGui)
			$yoffset -= 50
			GUISwitch($myGui)
			_Draw()
			_DrawCursors()


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


		Case $comselectokbutton    ; ********** Set the COM port configuration on his respective vars

			$comport = StringReplace(GUICtrlRead($comportselect),'COM','') ; Eliminate the COM caracters to the comportselect text

			$baudrate = GUICtrlRead($baudrateselct)

			Switch GUICtrlRead($databitselect)
				Case "7 bit"
					$databit = 7
				Case "8 bit"
					$databit = 8
				Case Else
					$databit = 8
			EndSwitch

			Switch GUICtrlRead($dataparityselect)
				Case "none"
					$parity = 0

				Case "odd"
					$parity = 1

				Case "even"
					$parity = 2

				Case "mark"
					$parity = 3

				Case "space"
					$parity = 4

				Case Else
					$parity = 0
			EndSwitch

			Switch GUICtrlRead($stopbitselect)
				Case "1 bit"
					$stopbit = 1

				Case "1,5 bits"
					$stopbit = 15

				Case "2 bits"
					$stopbit = 2

			Case Else
					$stopbit = 1

			EndSwitch

			Switch GUICtrlRead($flowcontrolselect)
				Case "none"
					$flowcontrol = 2

				Case "Xon/Xoff"
					$flowcontrol = 1

				Case "Hardware"
					$flowcontrol = 0

				Case Else
					$flowcontrol = 2

			EndSwitch

			_CommSetPort($comport, $sportSetError, $baudrate, $databit, $parity, $stopbit, $flowcontrol) ; Open the port

			;TODO look for error in com connection. Now ok connection is assumed
			$serialconnected = True

			IniWrite($ConfigFile, "COMPortConfig", "Port", $comport)
			IniWrite($ConfigFile, "COMPortConfig", "BaudRate", $baudrate)
			IniWrite($ConfigFile, "COMPortConfig", "DabaBits", $databit)
			IniWrite($ConfigFile, "COMPortConfig", "ParityBits", $parity)
			IniWrite($ConfigFile, "COMPortConfig", "StopBits", $stopbit)
			IniWrite($ConfigFile, "COMPortConfig", "FlowControl", $flowcontrol)


			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$comportselectform)

		Case $comselectcancelbutton
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$comportselectform)

		Case $comselecthelpbutton

		Case $databaseselectokbutton
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$databaseconfigform)

		Case $databaseselectcancelbutton
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$databaseconfigform)

		Case $databaseselecthelpbutton


		Case $dataconfigokbutton
			$dat = GUICtrlRead($dataconfigtruckmodel)
			For $k = 1 To StringLen($dat)
				$res &= Hex(Asc(StringMid($dat,$k,1)),2)
			Next
			ConsoleWrite($res & @CRLF)

			$received=False
			$times=1
			While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
				_SendZBData($SET_TRUCK_MODEL & $res)

				$Time = TimerInit()
				While ((TimerDiff($Time)/1000) <= 0.75 )  ; Wait until a zb data packet is received or 750ms
					GUICtrlSetData($status, ".", 1)
					If _CheckIncomingFrame() Then
						ConsoleWrite(_PrintFrame() & @CRLF)
						GUICtrlSetData($status, "-", 1)
						If _GetApiID() == $ZB_RX_RESPONSE Then
							GUICtrlSetData($status, "/", 1)				;Only check if a frame is returned by Arduino. Don´t check the content
							$received = True
						EndIf
					EndIf
				WEnd
				$times+=1
			WEnd

			$dat = GUICtrlRead($dataconfigtruckserial)
			For $k = 1 To StringLen($dat)
				$res &= Hex(Asc(StringMid($dat,$k,1)),2)
			Next
			ConsoleWrite($res & @CRLF)

			$received=False
			$times=1
			While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
				_SendZBData($SET_TRUCK_SN & $res)

				$Time = TimerInit()
				While ((TimerDiff($Time)/1000) <= 0.75 )  ; Wait until a zb data packet is received or 750ms
					GUICtrlSetData($status, ".", 1)
					If _CheckIncomingFrame() Then
						ConsoleWrite(_PrintFrame() & @CRLF)
						GUICtrlSetData($status, "-", 1)
						If _GetApiID() == $ZB_RX_RESPONSE Then
							GUICtrlSetData($status, "/", 1)				;Only check if a frame is returned by Arduino. Don´t check the content
							$received = True
						EndIf
					EndIf
				WEnd
				$times+=1
			WEnd

			$dat = GUICtrlRead($dataconfigbatterymodel)
			For $k = 1 To StringLen($dat)
				$res &= Hex(Asc(StringMid($dat,$k,1)),2)
			Next
			ConsoleWrite($res & @CRLF)

			$received=False
			$times=1
			While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
				_SendZBData($SET_BATT_MODEL & $res)

				$Time = TimerInit()
				While ((TimerDiff($Time)/1000) <= 0.75 )  ; Wait until a zb data packet is received or 750ms
					GUICtrlSetData($status, ".", 1)
					If _CheckIncomingFrame() Then
						ConsoleWrite(_PrintFrame() & @CRLF)
						GUICtrlSetData($status, "-", 1)
						If _GetApiID() == $ZB_RX_RESPONSE Then
							GUICtrlSetData($status, "/", 1)				;Only check if a frame is returned by Arduino. Don´t check the content
							$received = True
						EndIf
					EndIf
				WEnd
				$times+=1
			WEnd

			$dat = GUICtrlRead($dataconfigbatteryserial)
			For $k = 1 To StringLen($dat)
				$res &= Hex(Asc(StringMid($dat,$k,1)),2)
			Next
			ConsoleWrite($res & @CRLF)

			$received=False
			$times=1
			While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
				_SendZBData($SET_BATT_SN & $res)

				$Time = TimerInit()
				While ((TimerDiff($Time)/1000) <= 0.75 )  ; Wait until a zb data packet is received or 750ms
					GUICtrlSetData($status, ".", 1)
					If _CheckIncomingFrame() Then
						ConsoleWrite(_PrintFrame() & @CRLF)
						GUICtrlSetData($status, "-", 1)
						If _GetApiID() == $ZB_RX_RESPONSE Then
							GUICtrlSetData($status, "/", 1)				;Only check if a frame is returned by Arduino. Don´t check the content
							$received = True
						EndIf
					EndIf
				WEnd
				$times+=1
			WEnd

			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$hardwaredataform)

		Case $dataconfigcancelbutton
			GUISetState(@SW_ENABLE,$myGui)
			GUISetState(@SW_SHOW ,$myGui)
			GUISetState(@SW_HIDE,$hardwaredataform)

		Case $dataconfighelpbutton


		case $versionformokbutton
			GUISetState(@SW_HIDE, $versionform)

		Case Else

	EndSwitch

EndFunc


Func _MenuClicked ()
	Local $comportlist, $k ; Used in COM port detection
	Local $fecha, $res
	Local $Time, $Time1 ; Used for delay calculation in XBee transmisions/responses
	Local $received ; a status ok frame is received
	Local $times ; Used for control the resend xbee frame


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


		Case $configmenu_serialport  ;****************************

			$comportlist = _CommListPorts(0) ;find the available COM ports and write them into the COMportB combo
											;$portlist[0] contain the $portlist[] lenght
			For $k = 1 To $comportlist[0]
				GUICtrlSetData($comportselect,$comportlist[$k]);add de list of detected COMports to the $comportselect combo
			Next

			GUISetState(@SW_DISABLE,$myGui)
			GUISetState(@SW_SHOW ,$comportselectform)


		Case $configmenu_database
			GUISetState(@SW_DISABLE,$myGui)
			GUISetState(@SW_SHOW ,$databaseconfigform)

		Case $configmenu_hardware
			GUISetState(@SW_DISABLE,$myGui)
			GUISetState(@SW_SHOW ,$hardwaredataform)

		Case $configmenu_reset
			$received=False
			$times=1
			While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
				_SendZBData("99")

				$Time = TimerInit()
				While ((TimerDiff($Time)/1000) <= 0.75 )  ; Wait until a zb data packet is received or 750ms
					GUICtrlSetData($status, ".", 1)
					If _CheckIncomingFrame() Then
						ConsoleWrite(_PrintFrame() & @CRLF)
						GUICtrlSetData($status, "-", 1)
						If _GetApiID() == $ZB_RX_RESPONSE Then
							GUICtrlSetData($status, "/", 1)				;Only check if a frame is returned by Arduino. Don´t check the content
							$received = True
						EndIf
					EndIf
				WEnd
				$times+=1
			WEnd

		Case $configmenu_settime
			$fecha = Int(_DateDiff('s', "1970/01/01 00:00:00", _NowCalc()))
			$res = ""
			While $fecha > 0
				$res &= Hex(Mod($fecha, 255),2)
				$fecha = Int($fecha/255)
			WEnd

			$received=False
			$times=1
			While Not($received) And ($times <=3)  ;Resend 3 times if not ok ack frame is received
				_SendZBData("08" & $res)

				$Time = TimerInit()
				While ((TimerDiff($Time)/1000) <= 0.75 )  ; Wait until a zb data packet is received or 750ms
					GUICtrlSetData($status, ".", 1)
					If _CheckIncomingFrame() Then
						ConsoleWrite(_PrintFrame() & @CRLF)
						GUICtrlSetData($status, "-", 1)
						If _GetApiID() == $ZB_RX_RESPONSE Then
							GUICtrlSetData($status, "/", 1)				;Only check if a frame is returned by Arduino. Don´t check the content
							$received = True
						EndIf
					EndIf
				WEnd
				$times+=1
			WEnd


		Case $testmenu_serialport

		Case $testmenu_database

		Case $helpmenu_help

		Case $helpmenu_about

		Case $helpmenu_version
			GUISetState(@SW_SHOW,$versionform)

		Case Else

	EndSwitch

EndFunc




Func _imputBoxChange()

	Switch @GUI_CtrlId
		Case $ini_h
			If GUICtrlRead($ini_h) < 0 Then
				GUICtrlSetData($ini_h, 23)
			ElseIf GUICtrlRead($ini_h) > 23 Then
				GUICtrlSetData($ini_h, 0)
			EndIf

		Case $ini_m
			If GUICtrlRead($ini_m) < 0 Then
				GUICtrlSetData($ini_m, 59)
			ElseIf GUICtrlRead($ini_m) > 59 Then
				GUICtrlSetData($ini_m, 0)
			EndIf

		Case $end_h
			If GUICtrlRead($end_h) < 0 Then
				GUICtrlSetData($end_h, 23)
			ElseIf GUICtrlRead($end_h) > 23 Then
				GUICtrlSetData($end_h, 0)
			EndIf

		Case $end_m
			If GUICtrlRead($end_m) < 0 Then
				GUICtrlSetData($end_m, 59)
			ElseIf GUICtrlRead($end_m) > 59 Then
				GUICtrlSetData($end_m, 0)
			EndIf

		Case Else

	EndSwitch
EndFunc


;****************** GRAPHICAL REPRESENTATION FUNCTIONS **********************
Func _Draw()
	Local $j, $x, $y
	Local $first = True                   ; is the first value in range to represent?
	Local $t0, $tx		; time at init and x moment
	Local $c			; position in sensor[][c] array
	;$xmax = 400

	; Fill $screen[][] values with $sensor[][] values


	$t0 = Int($sensor[0][0]) + $xoffset/$xgain ; and take initial moment time
	$tx = $t0
	ConsoleWrite(@CRLF & "t0=" & $t0 & " , tx=" & $tx & ", xoffset=" & $xoffset & ", xgain=" & $xgain & @CRLF)
	$c = 0		;Pos at sensor[][] begin
	;ReDim $screen[6][1]

	; Take first sample to represent
	#cs If UBound($sensor,2)-1>=1 Then
		While ($sensor[0][$c]<$t0) And ($c<UBound($sensor,2)-1)
			$c+=1
		WEnd

		For $j = 0 To 5 		; and store it in the first
			$screen[$j][0] = $sensor[$j][$c]
		Next
	EndIf
	#ce

	$first=True
	$x=0

	While ($x<$xmax)   ;Until the end of $sensor[][] array or get xmax points

		If UBound($sensor,2)-1>=1 Then ; There are some sensor sample
			;ConsoleWrite("" & ", Sensor time=" & $sensor[0][$c] & ", x=" & $x & ", tx=" & $tx & ", c=" & $c & @CRLF)
			If $first Then
				If ($tx < $sensor[0][$c]) Then  ;Add '0' a the begin of the screen
					ConsoleWrite("<" & ", Sensor time=" & $sensor[0][$c] & ", x=" & $x & ", tx=" & $tx & ", c=" & $c & @CRLF)
					$screen[0][$x] = $tx
					For $j = 1 To 5
						$screen[$j][$x] = 0
					Next
					$x+=1
					$tx+=2/$xgain
				ElseIf ( $tx = $sensor[0][$c]) Then  ;This is the first sample
					ConsoleWrite("f" & ", Sensor time=" & $sensor[0][$c] & ", x=" & $x & ", tx=" & $tx & ", c=" & $c & @CRLF)
					$first=False
					$screen[0][$x] = $tx
					For $j = 1 To 5
						$screen[$j][$x] = $sensor[$j][$c]
					Next
					$c+=1
					$x+=1
					$tx+=2/$xgain

				Else
					If ($t0 > $sensor[0][$c+1]) Then
						ConsoleWrite(">" & ", Sensor time=" & $sensor[0][$c] & ", x=" & $x & ", tx=" & $tx & ", c=" & $c & @CRLF)
						$c+=1
					Else
						ConsoleWrite(">f" & ", Sensor time=" & $sensor[0][$c] & ", x=" & $x & ", tx=" & $tx & ", c=" & $c & @CRLF)
						$screen[0][$x] = $tx
						For $j = 1 To 5
							$screen[$j][$x] = $sensor[$j][$c]
						Next
						$c+=1
						$x+=1
						$tx+=2/$xgain
						$first=False
					EndIf
				EndIf
			Else
				If ($c<UBound($sensor,2)-1) Then	  ;Not the end of sensor array
					$screen[0][$x] = $tx
					ConsoleWrite("p" & ", Sensor time=" & $sensor[0][$c] & ", x=" & $x & ", tx=" & $tx & ", c=" & $c & @CRLF)
					For $j = 1 To 5
						If $tx < $sensor[0][$c] Then					; No stored value at this time
							$screen[$j][$x] = $sensor[$j][$c-1]   	; value was previous value
						Else
							$screen[$j][$x] = $sensor[$j][$c]
							$c+=1
						EndIf
					Next
					$x+=1
					$tx+=2/$xgain
				Else
					ConsoleWrite(">e" & ", Sensor time=" & $sensor[0][$c] & ", x=" & $x & ", tx=" & $tx & ", c=" & $c & @CRLF)
					For $j = 1 To 5
						;ConsoleWrite("j=" & $j & ", x=" & $x & @CRLF)
						$screen[$j][$x] = 0
					Next
					$x+=1
					$tx+=2/$xgain
				EndIf
			EndIf
		Else 			; there aren't any sample
			For $j = 1 To 5
				;ConsoleWrite("j=" & $j & ", x=" & $x & @CRLF)
				$screen[$j][$x] = 0
			Next
			$x+=1
			$tx+=2/$xgain
		EndIf

	WEnd
	;_ArrayDisplay($screen, "")

	$first=True
	For $j=0 To 4
		If $visible[$j] = True Then
			GUICtrlSetState($historygraph[$j], $GUI_SHOW)
			GUICtrlDelete($historygraph[$j])      ; Delete previous graphic handle
			$historygraph[$j] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax);, $WS_BORDER) ; create a new one

			;_PrintInGraphic($historygraph[$j], $j+1, $xmax, $ymax, $xgain, $yscale[$j]*$ygain, $xoffset, $offset[$j] + $yoffset, $colours[$j])

			GUICtrlSetGraphic($historygraph[$j], $GUI_GR_PENSIZE, 2)
			GUICtrlSetGraphic($historygraph[$j], $GUI_GR_COLOR, $colours[$j])						; Set the appropiate colour

			$t0 = Int($screen[0][0])
			For $x = 40 To $xmax -1 -40

				;$tx = Int($screen[0][$x])

				If (($x) < 0) Or (($x)>(UBound($screen,2)-1)) Then
					$y=0
					$first=True
				Else
					$y=$ymax - ($yscale[$j]*$ygain*$screen[$j+1][$x]+$offset[$j] + $yoffset)
					;$y=$ymax - ($yscale[$j]*$screen[$j+1][$x]+$offset[$j])
				EndIf

				If $y<0 Then
					$y=0
				ElseIf $y>$ymax Then
					$y=$ymax
				EndIf

					;ConsoleWrite("X=" & $x & ", $t0=" & $t0 & ", tx=" & $tx & ", tx-t0=" & $tx-$t0 & ", Y=" & $y & @CRLF)
				If $first Then         ; is the first value to represent in the graphic
					GUICtrlSetGraphic($historygraph[$j], $GUI_GR_MOVE, $x, $y) ;posicionate at inic of draw
					$first = False
					;GUICtrlSetData($status, "f", 1)
				Else
					GUICtrlSetGraphic($historygraph[$j], $GUI_GR_LINE, $x, $y)
					;GUICtrlSetData($status, "," & $x, 1)
				EndIf
				;EndIf
			Next

			GUICtrlSetColor($historygraph[$j], 0xffffff)
			$first = True
			;GUICtrlSetData($status, @CRLF, 1)

		Else
			GUICtrlSetState($historygraph[$j], $GUI_HIDE)
		EndIf
	Next

	; Now print the range value in the rules label

	For $j = 0 To 8
		GUICtrlSetData($rulesValue[0][$j],Round((($j+1)/10)*($ymax/($yscale[0]*$ygain))-($offset[0]+$yoffset)/($yscale[0]*$ygain),2) & "V")
		GUICtrlSetData($rulesValue[1][$j],Round((($j+1)/10)*($ymax/($yscale[2]*$ygain))-($offset[2]+$yoffset)/($yscale[2]*$ygain),1) & "A")
		GUICtrlSetData($rulesValue[2][$j],Round((($j+1)/10)*($ymax/($yscale[3]*$ygain))-($offset[3]+$yoffset)/($yscale[3]*$ygain),1) & "ºC")
	Next
EndFunc

Func _DrawGrid()
	Local $k
	GUICtrlSetGraphic($grid, $GUI_GR_COLOR, 0xDDDDDD)
	For $k = 1 To 9
		GUICtrlSetGraphic($grid, $GUI_GR_MOVE, 40, $k*$ymax/10)
		GUICtrlSetGraphic($grid, $GUI_GR_LINE, $xmax -1 -40, $k*$ymax/10)
		GUICtrlSetGraphic($grid, $GUI_GR_MOVE,  $k*$xmax/10, 15)
		GUICtrlSetGraphic($grid, $GUI_GR_LINE, $k*$xmax/10, $ymax)
	Next
	GUICtrlSetColor($grid, 0xffffff)
EndFunc


Func _DrawRules()
	Local $k

	GUICtrlSetGraphic($rules, $GUI_GR_COLOR, 0x000000)
	For $k = 1 To 9
		GUICtrlSetGraphic($rules, $GUI_GR_MOVE, 0, $k*$ymax/10)
		GUICtrlSetGraphic($rules, $GUI_GR_LINE, 10, $k*$ymax/10)
		GUICtrlSetGraphic($rules, $GUI_GR_MOVE, $xmax-1, $k*$ymax/10)
		GUICtrlSetGraphic($rules, $GUI_GR_LINE, $xmax-1-10, $k*$ymax/10)
	Next

	For $k = 1 to 4
		GUICtrlSetGraphic($rules, $GUI_GR_MOVE, 2*$k*$xmax/10, 0)
		GUICtrlSetGraphic($rules, $GUI_GR_LINE, 2*$k*$xmax/10, 10)
	Next

	GUICtrlSetColor($rules, 0xffffff)

EndFunc


Func _DrawCursors()
	If $cursorvisible Then
		GUICtrlDelete($cursor[0])      ; Delete previous graphic handle
		$cursor[0] =  GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER); create a new one
		GUICtrlSetGraphic($cursor[0], $GUI_GR_COLOR, 0xff0000)
		GUICtrlSetGraphic($cursor[0], $GUI_GR_MOVE, $cursor1, 20)
		GUICtrlSetGraphic($cursor[0], $GUI_GR_LINE, $cursor1, $ymax)
		GUICtrlSetColor($cursor[0], 0xffffff)
		GUICtrlDelete($cursor[1])
		$cursor[1] =  GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER); create a new one
		GUICtrlSetGraphic($cursor[1], $GUI_GR_COLOR, 0x0000ff)
		GUICtrlSetGraphic($cursor[1], $GUI_GR_MOVE, $cursor2, 20)
		GUICtrlSetGraphic($cursor[1], $GUI_GR_LINE, $cursor2, $ymax)
		GUICtrlSetColor($cursor[1], 0xffffff)

		; fill the label with the sensor value for each cursor
		If (Int($cursor1) >= 0) And (Int($cursor1) < (UBound($screen,2)-1)) Then ; don´t exceded the sensor data range
			GUICtrlSetData($sensorvalue[0][0], Round($screen[1][$cursor1],2) & "V")
			GUICtrlSetData($sensorvalue[1][0], Round($screen[3][$cursor1],1)& "A")
			GUICtrlSetData($sensorvalue[2][0], Round($screen[4][$cursor1],1)& "ºC")
			GUICtrlSetData($sensorvalue[3][0], Round($screen[5][$cursor1],1))
		Else
			GUICtrlSetData($sensorvalue[0][0], "V")
			GUICtrlSetData($sensorvalue[1][0], "A")
			GUICtrlSetData($sensorvalue[2][0], "ºC")
			GUICtrlSetData($sensorvalue[3][0], "")
		EndIf

		If (Int($cursor2) >= 0) And (Int($cursor2) < (UBound($screen,2)-1)) Then
			GUICtrlSetData($sensorvalue[0][1], Round($screen[1][$cursor2],2)& "V")
			GUICtrlSetData($sensorvalue[1][1], Round($screen[3][$cursor2],1)& "A")
			GUICtrlSetData($sensorvalue[2][1], Round($screen[4][$cursor2],1)& "ºC")
			GUICtrlSetData($sensorvalue[3][1], Round($screen[5][$cursor2],1))
		Else
			GUICtrlSetData($sensorvalue[0][1], "V")
			GUICtrlSetData($sensorvalue[1][1], "A")
			GUICtrlSetData($sensorvalue[2][1], "ºC")
			GUICtrlSetData($sensorvalue[3][1], "")
		EndIf

		; Fill $cursor1date with the date al cursor position
		If (Int($cursor2) >= 0) And (Int($cursor1) < (UBound($screen,2)-1)) Then
			GUICtrlSetData($cursor1date, _DateAdd('s',$screen[0][$cursor1],"1970/01/01 00:00:00"))
		Else
			GUICtrlSetData($cursor1date,"")
		EndIf

		If (Int($cursor2) >= 0) And (Int($cursor2) < (UBound($screen,2)-1)) Then
			GUICtrlSetData($cursor2date, _DateAdd('s',$screen[0][$cursor2],"1970/01/01 00:00:00"))
		Else
			GUICtrlSetData($cursor2date,"")
		EndIf

	EndIf

EndFunc

Func _ShowCursorsValues()
	If $cursorvisible Then
		If (GUICtrlRead($voltajecheck) = $GUI_CHECKED) Then
			GUICtrlSetState($sensorvalue[0][0], $GUI_SHOW)
			GUICtrlSetState($sensorvalue[0][1], $GUI_SHOW)
		Else
			GUICtrlSetState($sensorvalue[0][0], $GUI_HIDE)
			GUICtrlSetState($sensorvalue[0][0], $GUI_HIDE)
		EndIf

		If (GUICtrlRead($currentcheck) = $GUI_CHECKED) Then
			GUICtrlSetState($sensorvalue[1][0], $GUI_SHOW)
			GUICtrlSetState($sensorvalue[1][1], $GUI_SHOW)
		Else
			GUICtrlSetState($sensorvalue[1][0], $GUI_HIDE)
			GUICtrlSetState($sensorvalue[1][1], $GUI_HIDE)
		EndIf

		If (GUICtrlRead($tempcheck) = $GUI_CHECKED) Then
			GUICtrlSetState($sensorvalue[2][0], $GUI_SHOW)
			GUICtrlSetState($sensorvalue[2][1], $GUI_SHOW)
		Else
			GUICtrlSetState($sensorvalue[2][0], $GUI_HIDE)
			GUICtrlSetState($sensorvalue[2][1], $GUI_HIDE)
		EndIf

		If (GUICtrlRead($levelcheck) = $GUI_CHECKED) Then
			GUICtrlSetState($sensorvalue[3][0], $GUI_SHOW)
			GUICtrlSetState($sensorvalue[3][1], $GUI_SHOW)
		Else
			GUICtrlSetState($sensorvalue[3][0], $GUI_HIDE)
			GUICtrlSetState($sensorvalue[3][1], $GUI_HIDE)
		EndIf
	EndIf
EndFunc

Func _voltaje($sensorvalue)
	Return ((($sensorvalue*3.2226/1000)+4.1030)/0.4431);
EndFunc


Func _current($sensorvalue)
	Return ((($sensorvalue*3.2226/1000)-1.6471)/0.0063);
EndFunc

Func _temperature($sensorvalue)
	Return ((($sensorvalue*3.2226/1000)-0.5965)/0.0296);
EndFunc

Func _convert($dato)
	Local $k
	Local $res
	Local $d
	Local $long = StringLen($dato)/2

	For $k=1 To $long
		$d = StringMid($dato,$k*2-1,2) ;Extract byte by byte
		$res += Dec($d)*255^($k - 1)     ; Convert to a decimal data
	Next
	Return $res
EndFunc

Func _convertForDatabase($dato)
	Local $k
	Local $char
	Local $res = ""

	For $k = 1 To StringLen($dato)
		$char = StringMid($dato, $k, 1)
		If $char = "/" Then
			$res &= "-"
		Else
			$res &= $char
		EndIf
	Next
	Return $res
EndFunc

Func _convertFromDatabase($dato)
	Local $k
	Local $char
	Local $res = ""

	For $k = 1 To StringLen($dato)
		$char = StringMid($dato, $k, 1)
		If $char = "-" Then
			$res &= "/"
		Else
			$res &= $char
		EndIf
	Next
	Return $res
EndFunc