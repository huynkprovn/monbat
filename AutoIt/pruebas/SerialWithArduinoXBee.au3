#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         A.M.R.

 Script Function:
	Pueba de lectura de caracteres por el puerto serie enviados desde Arduino
	La placa arduino esta conectada mediante un Modulo XBee en la placa
	XBeeExplorer conectada al puerto COM9.
	La placa envia "1" y "0" en funcion del estado del puerto D10.
	Los datos leidos se muestran por la consola con el comando "ConsoleWrite()"


#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here

; LIBRERIAS
#include <array.au3>
#include <CommMG.au3>


; VARIABLES GLOBALES
Global $sportSetError = '' ;Internal for the Serial UDF


;COM Vars
Global $CMPort = 9				; Puerto al que esta conectada la placa XBee Explorer
Global $CmBoBaud = 9600			; Baud
Global $CmboDataBits =  8		; Data Bits
Global $CmBoParity = "none"		; Parity none
Global $CmBoStop = 1			; Stop
Global $setflow = 2				; Flow NONE


;Start up communication with the Arduino
_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)

_main()

_CommClosePort()


; **** MAIN() ****

Func _main()

; variables locales
Local $k = 0
Local $sChar


;Start a loop
	While $k <20
		$sChar = _CommReadChar(1)
		ConsoleWrite($sChar & @CRLF)
		Sleep (10) ;Espera 10ms
		$k = $k + 1
	WEnd


EndFunc




#cs
    Local $aComPort = _ComGetPortNames()
    _ArrayDisplay($aComPort)
    Local $sComPort = _ComGetPortNames("COM1")
    If @error Then
    MsgBox(16, "Error " & @error, "No matching COM port found.")
    Else
    ConsoleWrite($sComPort & @CRLF)
    EndIf
#ce
