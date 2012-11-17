$checksum = 1120

ConsoleWrite($checksum & " " & Hex($checksum,2))
$res = 0xFF -  ("0x" & Hex($checksum,2))
$res2 = "0x"&Hex($res)
ConsoleWrite(@CRLF & $res & @CRLF)
ConsoleWrite(@CRLF & $res2 & @CRLF)
;Return (0xFF - (0xFF And ("0x" & Hex($checksum,2))))
