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

Global $zoominbutton, $zoomoutbutton, $zoomfitbutton, $showcursorsbutton
Global $zoominbuttonhelp, $zoomoutbuttonhelp, $zoomfitbuttonhelp,$showcursorsbuttonhelp

Dim $buttonxpos = 0, $buttonypos = 0
$zoominbutton = GUICtrlCreateButton("Zoom In",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$zoominbuttonhelp =GUICtrlCreateLabel("Zoom In", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$zoomoutbutton = GUICtrlCreateButton("Zoom Out",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$zoomoutbuttonhelp =GUICtrlCreateLabel("Zoom Out", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$zoomfitbutton = GUICtrlCreateButton("Zoom Fit",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$zoomfitbuttonhelp =GUICtrlCreateLabel("Zoom Fit", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)
$buttonxpos += $ButtonWith

$showcursorsbutton = GUICtrlCreateButton("Show Cursors",$buttonxpos,$buttonypos,$ButtonWith,$ButtonHeight,$BS_ICON)
GUICtrlSetImage(-1, "shell32.dll", -28)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$showcursorsbuttonhelp =GUICtrlCreateLabel("Show Cursors", $buttonxpos+$ButtonWith/2, $buttonypos+$ButtonHeight)
GUICtrlSetState(-1,$GUI_HIDE)


; Dimensiones tal y como estan creadas en el formulario Sismonbat
Const $xmax = $GUIWidth*3/4
Const $ymax	= $GUIHeight-$ButtonHeight-$checkboxheight-$statusHeight
Global $sensor[6][$xmax] ; sensors signals for representation [date,v+,v-,a,t,l]
Global $offset[5] = [Int($ymax/2),0,Int($ymax/2),Int($ymax/10),int($ymax/10)]; offset off each sensor representation
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

Global $cursor[2]
$cursor[0] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER)
$cursor[1] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER)

Global $xoff_m, $xoff_p, $yoff_m, $yoff_p

$xoff_m = GUICtrlCreateButton("",$xmax - 80,$ButtonHeight,20,20)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$xoff_p = GUICtrlCreateButton("",$xmax - 40,$ButtonHeight,20,20)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$yoff_p = GUICtrlCreateButton("",$xmax - 20,$ButtonHeight + 20, 20, 20)
GUICtrlSetOnEvent(-1, "_ButtonClicked")
$yoff_m = GUICtrlCreateButton("",$xmax - 20,$ButtonHeight + 60, 20, 20)
GUICtrlSetOnEvent(-1, "_ButtonClicked")

#cs
Global $SliderXoff, $SliderXgain, $SliderYoff, $SliderYgain
$SliderXoff = GUICtrlCreateSlider(368, 16, 150, 45)
GUICtrlSetLimit($SliderXoff, 200, -200)
GUICtrlSetOnEvent(-1, "_SlideMoved")
$SliderYoff = GUICtrlCreateSlider(368, 64, 150, 45)
GUICtrlSetLimit($SliderYoff, 200, -200)
GUICtrlSetOnEvent(-1, "_SlideMoved")
$SliderXgain = GUICtrlCreateSlider(368, 104, 150, 45)
GUICtrlSetLimit($SliderXgain, 5, 0.2)
GUICtrlSetData($SliderXgain, 1)
GUICtrlSetOnEvent(-1, "_SlideMoved")
$SliderYgain = GUICtrlCreateSlider(368, 152, 150, 45)
GUICtrlSetLimit($SliderYgain, 5, 0.2)
GUICtrlSetData($SliderYgain, 1)
GUICtrlSetOnEvent(-1, "_SlideMoved")
#ce

Global $xoffset = 0
Global $yoffset = 0
Global $xgain = 1
Global $ygain = 1


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

	_Draw()
	While 1

		Sleep(50)
	WEnd
EndFunc

Func _CLOSEClicked ()
	Switch @GUI_WINHANDLE
		Case $myGui
			Exit

		Case Else

	EndSwitch
EndFunc


Func _Draw()
	Local $k, $x
	For $j=0 To 4
		GUICtrlDelete($historygraph[$j])      ; Delete previous graphic handle
		$historygraph[$j] = GUICtrlCreateGraphic(0, $ButtonHeight, $xmax, $ymax, $WS_BORDER) ; create a new one
		_PrintInGraphic($historygraph[$j], $j+1, $xmax, $ymax, $xgain, $yscale[$j]*$ygain, $xoffset, $offset[$j] + $yoffset, $colours[$j])
	Next


EndFunc


Func _PrintInGraphic($graphic, $data, $xmax, $ymax, $xgain, $ygain, $xoff, $yoff, $color)
	Local $x, $xeff, $y
	Local $first = True                   ; is the first value in range to represent

	;GUICtrlSetGraphic($graphic, $GUI_GR_PENSIZE, 3)
	GUICtrlSetGraphic($graphic, $GUI_GR_COLOR, $color)						; Set the appropiate colour
	For $x = 0 To $xmax -1
		If ((($x/$xgain)+$xoff) >= 0) And ((($x/$xgain)+$xoff) < ($xmax -1)) Then							; Don´t exceeded the $sensor[$j] range
			If $first Then         ; is the first value to represent in the graphic
				GUICtrlSetGraphic($graphic, $GUI_GR_MOVE, $x, $ymax - ($yoff*$sensor[$data][($x/$xgain)+$xoff]+$yoff)) ;posicionate at inic of draw
				$first = False
			EndIf
			$y=$ymax - ($ygain*$sensor[$data][($x/$xgain)+$xoff]+$yoff)
			;If ($y > 0) And ($y < $ymax) Then
				GUICtrlSetGraphic($graphic, $GUI_GR_LINE, $x, $ymax - ($ygain*$sensor[$data][($x/$xgain)+$xoff]+$yoff))
			;EndIf
		EndIf
	Next
	GUICtrlSetColor($graphic, 0xffffff)


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
				GUICtrlSetState($historygraph[1], $GUI_HIDE)
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


		Case $zoominbutton
			Switch $xgain
				Case 0.2
					$xgain = 0.25
					$ygain = 0.25
				Case 0.25
					$xgain = 0.33
					$ygain = 0.33
				Case 0.33
					$xgain = 0.5
					$ygain = 0.5
				Case 0.5
					$xgain = 1
					$ygain = 1
				Case 1
					$xgain = 2
					$ygain = 2
				Case 2
					$xgain = 3
					$ygain = 3
				Case 3
					$xgain = 4
					$ygain = 4
				Case 4
					$xgain = 5
					$ygain = 5
			EndSwitch
			_Draw()

		Case $zoomoutbutton
			Switch $xgain
				Case 0.25
					$xgain = 0.2
					$ygain = 0.2
				Case 0.33
					$xgain = 0.25
					$ygain = 0.25
				Case 0.5
					$xgain = 0.33
					$ygain = 0.33
				Case 1
					$xgain = 0.5
					$ygain = 0.5
				Case 2
					$xgain = 1
					$ygain = 1
				Case 3
					$xgain = 2
					$ygain = 2
				Case 4
					$xgain = 3
					$ygain = 3
				Case 5
					$xgain = 4
					$ygain = 4

			EndSwitch
			_Draw()

		Case $zoomfitbutton
			$xoffset = 0
			$yoffset = 0
			$xgain = 1
			$ygain = 1
			_Draw()

		Case $xoff_p
			$xoffset += 20
			_Draw()
		Case $xoff_m
			$xoffset -= 20
			_Draw()
		Case $yoff_p
			$yoffset += 20
			_Draw()
		Case $yoff_m
			$yoffset -= 20
			_Draw()

	EndSwitch
EndFunc