#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here



#include <GUIConstantsEx.au3>

Opt("GUIOnEventMode", 1)  ; Change to OnEvent mode

$mainwindow = GUICreate("Hello World", 200, 100)
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEClicked")
GUICtrlCreateLabel("Hello world! How are you?", 30, 10)
$okbutton = GUICtrlCreateButton("OK", 70, 50, 60)
GUICtrlSetOnEvent($okbutton, "OKButton")
GUISetState(@SW_SHOW)

While 1
  Sleep(1000)  ; Idle around
WEnd

Func OKButton()
  ;Note: at this point @GUI_CTRLID would equal $okbutton,
  ;and @GUI_WINHANDLE would equal $mainwindow
  MsgBox(0, "GUI Event", "You pressed OK!")
EndFunc

Func CLOSEClicked()
  ;Note: at this point @GUI_CTRLID would equal $GUI_EVENT_CLOSE,
  ;and @GUI_WINHANDLE would equal $mainwindow
  MsgBox(0, "GUI Event", "You clicked CLOSE! Exiting...")
  Exit
EndFunc