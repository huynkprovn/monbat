Dim $var = 0x00
Const $START_BYTE = 0x7E
Const $ZBATCommand = 0x08

Dim $var1, $var2, $var3, $var4, $var5
Dim $CheckSum = 0x00

$var1 = $ZBATCommand
$var2 = 0x01
$var3 = 0x09 + Binary("I")
$var4 = Binary("D")
$var5 = 0xFF - $var4

$CheckSum += $var1
ConsoleWrite(Hex($var1,2) & " " & Hex($CheckSum,2) & @CRLF)

$CheckSum += $var2
ConsoleWrite(Hex($var2,2) & " " & Hex($CheckSum,2) & @CRLF)

$CheckSum = $var3
ConsoleWrite(Hex($var3,2) & " " & Hex($CheckSum,2) & @CRLF)

$CheckSum += $var4
ConsoleWrite(Hex($var4,2) & " " & Hex($CheckSum,2) & @CRLF)

$CheckSum = $var5
ConsoleWrite(Hex($var5,2) & " " & Hex($CheckSum,2) & @CRLF)
