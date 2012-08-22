#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here


MsgBox(0, "SRE Example 2 Result", StringRegExp("text", 'te[sx]t'))
MsgBox(0, "SRE Example 2 Result", StringRegExp("test", 'te[sx]t'))