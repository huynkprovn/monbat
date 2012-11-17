Dim $var = 0x00
Const $START_BYTE = 0x7E
Const $ZBATCommand = 0x08

Dim $var1, $var2, $var3, $var4, $var5
Dim $CheckSum = Binary(0x00)

$var1 = $ZBATCommand
$var2 = 0x01
$var3 = "0x"&Hex(Binary("I"),2)
$var4 = "0x"&Hex(Binary("D"),2)
;$var3 = 0x49
;var4 = 0x44
$var5 = 0xFF

;ConsoleWrite($var3 & " " & ($var3 + 0x1) & @CRLF)


$CheckSum += $var1
ConsoleWrite($var1 & " " & $CheckSum & @CRLF)

$CheckSum += $var2
ConsoleWrite($var2 & " " & $CheckSum & @CRLF)

$CheckSum += $var3
ConsoleWrite($var3 & " " & $CheckSum & @CRLF)

$CheckSum += $var4
ConsoleWrite($var4 & " " & $CheckSum & @CRLF)

$CheckSum = 0xFF - $CheckSum
ConsoleWrite($var5 & " " & $CheckSum & @CRLF)

;StringToASCIIArray("ID")