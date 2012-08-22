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

$dummywindow = GUICreate("Dummy window for testing ", 200, 100)
GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEClicked")

GUISwitch($mainwindow)
GUISetState(@SW_SHOW)

GUISwitch($dummywindow)
GUISetState(@SW_SHOW)

While 1
  Sleep(1000)  ; Idle around
WEnd

Func OKButton()
  ;Note: at this point @GUI_CTRLID would equal $okbutton
  MsgBox(0, "GUI Event", "You pressed OK!")
EndFunc

Func CLOSEClicked()
  ;Note: at this point @GUI_CTRLID would equal $GUI_EVENT_CLOSE,
  ;@GUI_WINHANDLE will be either $mainwindow or $dummywindow
  If @GUI_WINHANDLE = $mainwindow Then
    MsgBox(0, "GUI Event", "You clicked CLOSE in the main window! Exiting...")
    Exit
  EndIf
EndFunc

