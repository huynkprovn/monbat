#include <Array.au3> ; Required only for _ArrayDisplay().
#include <GUIConstantsEx.au3>
#include <GUIListView.au3>
#include <WindowsConstants.au3>

Example()

Func Example()
    Local $iWidth = 600, $iHeight = 400, $iListView
    Local $hGUI = GUICreate('_GUICtrlListView_CreateArray()', $iWidth, $iHeight, -1, -1, BitOR($GUI_SS_DEFAULT_GUI, $WS_MAXIMIZEBOX, $WS_SIZEBOX))

    _CreateListView($hGUI, $iListView)

    Local $iGetArray = GUICtrlCreateButton('Get Array', $iWidth - 90, $iHeight - 28, 85, 25)
    GUICtrlSetResizing(-1, $GUI_DOCKRIGHT + $GUI_DOCKSIZE + $GUI_DOCKBOTTOM)

    Local $iRefresh = GUICtrlCreateButton('Refresh', $iWidth - 180, $iHeight - 28, 85, 25)
    GUICtrlSetResizing(-1, $GUI_DOCKRIGHT + $GUI_DOCKSIZE + $GUI_DOCKBOTTOM)

    GUISetState(@SW_SHOW, $hGUI)

    Local $aReturn = 0, $aStringSplit = 0
    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                ExitLoop

            Case $iGetArray
                $aReturn = _GUICtrlListView_CreateArray($iListView, Default) ; Use | as the default delimeter.
                _ArrayDisplay($aReturn, '_GUICtrlListView_CreateArray() array.')

                $aStringSplit = StringSplit($aReturn[0][2], '|')
                _ArrayDisplay($aStringSplit, 'StringSplit() to retrieve column names.')

            Case $iRefresh
                GUICtrlDelete($iListView)
                _CreateListView($hGUI, $iListView)

        EndSwitch
    WEnd
    GUIDelete($hGUI)
EndFunc   ;==>Example

Func _CreateListView($hGUI, ByRef $iListView) ; Thanks to AZJIO for this function.
    Local $aClientSize = WinGetClientSize($hGUI)
    $iListView = GUICtrlCreateListView('', 0, 0, $aClientSize[0], $aClientSize[1] - 30)
    GUICtrlSetResizing($iListView, $GUI_DOCKBORDERS)
    Sleep(250)

    Local $iColumns = Random(1, 8, 1)
    __ListViewFill($iListView, $iColumns, Random(25, 500, 1)) ; Fill the ListView with Random data.
    For $i = 0 To $iColumns
        _GUICtrlListView_SetColumnWidth($iListView, $i, $LVSCW_AUTOSIZE)
        _GUICtrlListView_SetColumnWidth($iListView, $i, $LVSCW_AUTOSIZE_USEHEADER)
    Next
EndFunc   ;==>_CreateListView

Func __ListViewFill($hListView, $iColumns, $iRows) ; Required only for the Example.
    If Not IsHWnd($hListView) Then
        $hListView = GUICtrlGetHandle($hListView)
    EndIf
    Local $fIsCheckboxesStyle = (BitAND(_GUICtrlListView_GetExtendedListViewStyle($hListView), $LVS_EX_CHECKBOXES) = $LVS_EX_CHECKBOXES)

    _GUICtrlListView_BeginUpdate($hListView)
    For $i = 0 To $iColumns - 1
        _GUICtrlListView_InsertColumn($hListView, $i, 'Column ' & $i + 1, 50)
        _GUICtrlListView_SetColumnWidth($hListView, $i - 1, -2)
    Next
    For $i = 0 To $iRows - 1
        _GUICtrlListView_AddItem($hListView, 'Row ' & $i + 1 & ': Col 1', $i)
        If Random(0, 1, 1) And $fIsCheckboxesStyle Then
            _GUICtrlListView_SetItemChecked($hListView, $i)
        EndIf
        For $j = 1 To $iColumns
            _GUICtrlListView_AddSubItem($hListView, $i, 'Row ' & $i + 1 & ': Col ' & $j + 1, $j)
        Next
    Next
    _GUICtrlListView_EndUpdate($hListView)
EndFunc   ;==>__ListViewFill



; #FUNCTION# ====================================================================================================================
; Name ..........: _GUICtrlListView_CreateArray
; Description ...: Creates a 2-dimensional array from a lisview.
; Syntax ........: _GUICtrlListView_CreateArray($hListView[, $sDelimeter = '|'])
; Parameters ....: $hListView           - Control ID/Handle to the control
;                  $sDelimeter          - [optional] One or more characters to use as delimiters (case sensitive). Default is '|'.
; Return values .: Success - The array returned is two-dimensional and is made up of the following:
;                                $aArray[0][0] = Number of rows
;                                $aArray[0][1] = Number of columns
;                                $aArray[0][3] = Delimited string of the column name(s) e.g. Column 1|Column 2|Column 3|Column nth

;                                $aArray[1][0] = 1st row, 1st column
;                                $aArray[1][1] = 1st row, 2nd column
;                                $aArray[1][2] = 1st row, 3rd column
;                                $aArray[n][0] = nth row, 1st column
;                                $aArray[n][1] = nth row, 2nd column
;                                $aArray[n][2] = nth row, 3rd column
; Author ........: guinness
; Remarks .......: GUICtrlListView.au3 should be included.
; Example .......: yes
; ===============================================================================================================================
Func _GUICtrlListView_CreateArray($hListView, $sDelimeter = '|')
    Local $iColumnCount = _GUICtrlListView_GetColumnCount($hListView), $iDim = 0, $iItemCount = _GUICtrlListView_GetItemCount($hListView)
    If $iColumnCount < 3 Then
        $iDim = 3 - $iColumnCount
    EndIf
    If $sDelimeter = Default Then
        $sDelimeter = '|'
    EndIf

    Local $aColumns = 0, $aReturn[$iItemCount + 1][$iColumnCount + $iDim] = [[$iItemCount, $iColumnCount, '']]
    For $i = 0 To $iColumnCount - 1
        $aColumns = _GUICtrlListView_GetColumn($hListView, $i)
        $aReturn[0][2] &= $aColumns[5] & $sDelimeter
    Next
    $aReturn[0][2] = StringTrimRight($aReturn[0][2], StringLen($sDelimeter))

    For $i = 0 To $iItemCount - 1
        For $j = 0 To $iColumnCount - 1
            $aReturn[$i + 1][$j] = _GUICtrlListView_GetItemText($hListView, $i, $j)
        Next
    Next
    Return SetError(Number($aReturn[0][0] = 0), 0, $aReturn)
EndFunc   ;==>_GUICtrlListView_CreateArray