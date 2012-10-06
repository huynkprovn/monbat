#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         myName

 Script Function:

#ce ----------------------------------------------------------------------------


; LIBRERIAS
#include '..\XbeeAPI\XbeeAPI.au3'
#include <array.au3>
#include <CommMG.au3>
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>


; ******** MAIN ************



Global $GUIWidth =1200, $GUIHeight = 700
Global $GUIButtonWith = 40, $GUIButtonHeight = 40
Global $GUIWidthSpacer = 20, $GUIHeigthSpacer = 10

Global $myGui ; main GUI handler

Global $filemenu, $editmenu, $helpmenu ; form menu vars
Global $searchbutton, $readbutton, $viewbutton, $savebutton, $printbutton, $exitbutton ; button vars
Global $histotygraph ; Graph for histoy representation
; Form creation
$myGui = GUICreate("INTERFAZ", $GUIWidth, $GUIHeight, @DesktopWidth / 4, 20)
GUISetState() ; Show the main GUI

; Form menu creation
$filemenu = GUICtrlCreateMenu("File")
$editmenu = GUICtrlCreateMenu("Edit")
$helpmenu = GUICtrlCreateMenu("?")

; Buttons creation
Dim $buttonxpos = 0, $buttonypos = 0
$searchbutton = GUICtrlCreateButton("Batteries",$buttonxpos,$buttonypos,$GUIButtonWith,$GUIButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -23)
$buttonxpos += $GUIButtonWith

$readbutton = GUICtrlCreateButton("Read Data",$buttonxpos,$buttonypos,$GUIButtonWith,$GUIButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -13)
$buttonxpos += $GUIButtonWith

$viewbutton = GUICtrlCreateButton("View History",$buttonxpos,$buttonypos,$GUIButtonWith,$GUIButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -94)
$buttonxpos += $GUIButtonWith

$savebutton = GUICtrlCreateButton("Save History",$buttonxpos,$buttonypos,$GUIButtonWith,$GUIButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -9)
$buttonxpos += $GUIButtonWith

$printbutton = GUICtrlCreateButton("Print",$buttonxpos,$buttonypos,$GUIButtonWith,$GUIButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -137)
$buttonxpos += $GUIButtonWith

$exitbutton = GUICtrlCreateButton("Exit",$buttonxpos,$buttonypos,$GUIButtonWith,$GUIButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)

; History graphic creation
$histotygraph = GUICtrlCreateGraphic(0,$GUIButtonHeight,$GUIWidth/2,$GUIHeight-$GUIButtonHeight, $SS_BLACKFRAME)

While 1
WEnd