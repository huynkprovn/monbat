#include <array.au3>
#include <CommMG.au3>
#include <StaticConstants.au3>
#include <ProgressConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>

Opt("GUIOnEventMode", 1)

Const $GUIWidth = @DesktopWidth-20, $GUIHeight = @DesktopHeight-40
Const $ButtonWith = 40, $ButtonHeight = 40
Const $GUIWidthSpacer = 20, $GUIHeigthSpacer = 10
Const $statusHeight = 50
Const $checkboxheight = 15
Const $checkboxwith = ($GUIWidth*3/16)

Global $myGui ; main GUI handler
Global $historygraph[5]

$myGui = GUICreate("Traction batteries monitor system", $GUIWidth, $GUIHeight, 5, 5)
GUISetOnEvent($GUI_EVENT_CLOSE, "_CLOSEClicked")
;GUISetBkColor(0xf0f0f0)
GUISetState() ; Show the main GUI

; Dimensiones tal y como estan creadas en el formulario Sismonbat
Const $xmax = $GUIWidth*3/4
Const $ymax	= $GUIHeight-$ButtonHeight-$checkboxheight-$statusHeight
Global $sensor[6][$xmax] ; sensors signals for representation [date,v+,v-,a,t,l]
Global $offset[5] = [$ymax/2,0,$ymax/2,$ymax/10,$ymax/10]; offset off each sensor representation
Global $yscale[5] = [50,200,200,50,200]	 ; scale of each sensor representation
Global $colours[5] = [0xff0000, 0x000000, 0xffff00, 0x0000ff, 0xff00ff]
Global $xscale

Dim $xpos = 0
$voltajecheck = GUICtrlCreateCheckbox("Voltage", $xpos ,$GUIHeight - $statusHeight - $checkboxheight, $checkboxwith, $checkboxheight)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$xpos += $checkboxwith
$currentcheck = GUICtrlCreateCheckbox("Current", $xpos ,$GUIHeight - $statusHeight - $checkboxheight, $checkboxwith, $checkboxheight)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$xpos += $checkboxwith
$tempcheck = GUICtrlCreateCheckbox("Temperature", $xpos ,$GUIHeight - $statusHeight - $checkboxheight, $checkboxwith, $checkboxheight)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$xpos += $checkboxwith
$levelcheck = GUICtrlCreateCheckbox("Level", $xpos ,$GUIHeight - $statusHeight - $checkboxheight, $checkboxwith, $checkboxheight)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "_ButtonClicked")


 ; Matriz con los valores y para cada x de cada sensor. Es lo que se representa en el grafico
$historygraph[0] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER) ;V+
$historygraph[1] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER) ;V-
$historygraph[2] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER) ;A
$historygraph[3] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER) ;T
$historygraph[4] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER) ;L


For $k = 0 To $xmax -1
	$sensor[1][$k] = Sin($k/50)
Next

For $k = 0 To $xmax -1
	$sensor[2][$k] = Sin($k/30)
Next

For $k = 0 To $xmax -1
	$sensor[0][$k] = Tan($k/30)
Next

For $k = 0 To $xmax -1
	$sensor[4][$k] = Cos($k/30)
Next


_Main()

Func _Main ()
	Local $k, $x

	While 1
		For $j=0 To 4
			GUICtrlSetGraphic($historygraph[$j], $GUI_GR_MOVE, 0, $yscale[$j]*$sensor[$j+1][0]+$offset[$j]) ;posicionate at inic of draw
			GUICtrlSetGraphic($historygraph[$j], $GUI_GR_COLOR, $colours[$j])						; Set the appropiate colour
			For $x = 0 To $xmax -1
				GUICtrlSetGraphic($historygraph[$j], $GUI_GR_LINE, $x, $ymax - ($yscale[$j]*$sensor[$j+1][$x]+$offset[$j]))
			Next
			GUICtrlSetColor($historygraph[$j], 0xffffff)
		Next

		Sleep(5000)
	WEnd
EndFunc

Func _CLOSEClicked ()
	Switch @GUI_WINHANDLE
		Case $myGui
			Exit

		Case Else

	EndSwitch
EndFunc

Func _Fill($xmax, $y)
	Local $k
	ConsoleWrite($xmax & " " & $y)
	For $k = 0 To $xmax -1
		$sensor[1][$k] = Sin($k/50)
	Next

EndFunc

Func _ButtonClicked ()

	Switch @GUI_CtrlId

		Case $voltajecheck
			If (GUICtrlRead($voltajecheck) = $GUI_CHECKED) Then
				GUICtrlSetState($historygraph[0], $GUI_SHOW)
				GUICtrlSetState($historygraph[1], $GUI_SHOW)
			Else
				GUICtrlSetState($historygraph[0], $GUI_HIDE)
				GUICtrlSetState($historygraph[0], $GUI_HIDE)
			EndIf

		Case $currentcheck
			If (GUICtrlRead($currentcheck) = $GUI_CHECKED) Then
				GUICtrlSetState($historygraph[2], $GUI_SHOW)
			Else
				GUICtrlSetState($historygraph[2], $GUI_HIDE)
			EndIf

		Case $tempcheck
			If (GUICtrlRead($tempcheck) = $GUI_CHECKED) Then
				GUICtrlSetState($historygraph[3], $GUI_SHOW)
			Else
				GUICtrlSetState($historygraph[3], $GUI_HIDE)
			EndIf

		Case $levelcheck
			If (GUICtrlRead($levelcheck) = $GUI_CHECKED) Then
				GUICtrlSetState($historygraph[4], $GUI_SHOW)
			Else
				GUICtrlSetState($historygraph[4], $GUI_HIDE)
			EndIf

	EndSwitch
EndFunc