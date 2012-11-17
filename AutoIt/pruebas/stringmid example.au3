Local $sh = "0013A200"
Local $sl = "408C51AB"
Local $id1 = "20524F5554455231"
Local $array[20]

$array = _StringToByteArray($sh & $sl)

For $k = 1 To $array[0]
	ConsoleWrite($array[$k] & @CRLF)
Next

ConsoleWrite(_BytestringToCharstring($id1) & @CRLF)

Func _StringToByteArray($string)
	Local $k
	Local $array[20]

	For $k=1 To StringLen($string)/2
		$array[$k] = StringMid($string,$k*2-1,2)
	Next
	$array[0] = $k-1

	Return $array

Endfunc    ;==>_StringToByteArray

Func _BytestringToCharstring($string)
	Local $str
	Local $k
	$str =""
	For $k=1 To StringLen($string)/2
		$str &= Chr(StringMid($string,$k*2-1,2))
	Next
	Return $str
EndFunc