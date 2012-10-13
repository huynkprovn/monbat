$objErr = ObjEvent("AutoIt.Error","MyErrFunc")

#include "mysql.au3"

Global $username = "root"
Global $password = "monbat"
Global $database = "monbat"
Global $MySQLServerName = "localhost"

Global $SQLInstance
Global $SQLCode, $TableContents

$SQLInstance = _MySQLConnect($username, $password, $database, $MySQLServerName)

$SQLCode = "SELECT * FROM battsignals"
$TableContents = _Query($SQLInstance, $SQLCode)

With $TableContents
	While Not .EOF
		ConsoleWrite(.Fields("fecha").value & ", " & .Fields("voltajeh").value & "V, " & .Fields("voltajel").value & "V")
		ConsoleWrite(", " & .Fields("temperature").value & "ºC" & @CRLF)
		.MoveNext
	WEnd
EndWith
_MySQLEnd($SQLInstance)



Func MyErrFunc()

$hexnum=hex($objErr.number,8)

Msgbox(0,"","We intercepted a COM Error!!"      & @CRLF                & @CRLF & _
             "err.description is: " & $objErr.description   & @CRLF & _
             "err.windescription is: " & $objErr.windescription & @CRLF & _
             "err.lastdllerror is: "   & $objErr.lastdllerror   & @CRLF & _
             "err.scriptline is: "   & $objErr.scriptline    & @CRLF & _
             "err.number is: "       & $hexnum               & @CRLF & _
             "err.source is: "       & $objErr.source        & @CRLF & _
             "err.helpfile is: "       & $objErr.helpfile      & @CRLF & _
             "err.helpcontext is: " & $objErr.helpcontext _
            )
exit
EndFunc