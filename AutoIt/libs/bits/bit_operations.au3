Func _bit($byte, $bit)
	Local $res
	If (BitAND($byte,_bitSet(0,$bit)) > 0) Then
		$res = True
	Else
		$res = False
	EndIf
	Return $res

EndFunc

Func _bitSet($byte, $bit)
	Local $res

	Switch $bit
		Case 0
			$res = BitOR($byte,0x01)
		Case 1
			$res = BitOR($byte,0x02)
		Case 2
			$res = BitOR($byte,0x04)
		Case 3
			$res = BitOR($byte,0x08)
		Case 4
			$res = BitOR($byte,0x10)
		Case 5
			$res = BitOR($byte,0x20)
		Case 6
			$res = BitOR($byte,0x40)
		Case 7
			$res = BitOR($byte,0x80)
	EndSwitch
	Return $res
EndFunc

Func _bitClear($byte, $bit)
	Local $res

	Switch $bit
		Case 0
			$res = BitAND($byte,0xFE)
		Case 1
			$res = BitAND($byte,0xFD)
		Case 2
			$res = BitAND($byte,0xFB)
		Case 3
			$res = BitAND($byte,0xF7)
		Case 4
			$res = BitAND($byte,0xEF)
		Case 5
			$res = BitAND($byte,0xDF)
		Case 6
			$res = BitAND($byte,0xBF)
		Case 7
			$res = BitAND($byte,0x7F)
	EndSwitch
	Return $res
EndFunc


