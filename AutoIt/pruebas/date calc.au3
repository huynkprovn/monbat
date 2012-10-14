#include <Date.au3>

Dim $sNewDate, $Date

$Date = 47*255^0+201*255^1+109*255^2+81*255^3

ConsoleWrite($Date & @CRLF)


$sNewDate = _DateAdd('s', $Date, "1970/01/01 00:00:00")
ConsoleWrite("Date: " & $sNewDate)
