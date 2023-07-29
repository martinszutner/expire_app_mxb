Private Sub Workbook_Open()
    Application.Calculation = xlAutomatic
    'Call Refresh_db
    
    'Calculate
    If Not checkLic() Then
        MsgBox "Sistema SIN LICENCIA", vbCritical + vbExclamation, "JMFS"
        CloseWorkbook
    End If
End Sub

Sub CloseWorkbook()
    Application.DisplayAlerts = False
    ActiveWorkbook.Close SaveChanges:=False
    Application.DisplayAlerts = True
End Sub

Sub Refresh_db()

    Dim Conn As WorkbookConnection
    Dim Cname As String
    
    ' Actualiza las queries.
    For Each Conn In ActiveWorkbook.Connections
        If VBA.Left(Conn.Name, 8) = "Query - " Or VBA.Left(Conn.Name, 8) = "Consulta" Then
            Cname = Conn.Name
            With ActiveWorkbook.Connections(Cname).OLEDBConnection
                .BackgroundQuery = False
                .Refresh
            End With
        End If
    Next
    
    ' Actualiza el modelo de datos (Power Pivot)
    ThisWorkbook.Model.Refresh
    
    MsgBox "BASE DE DATOS ACTUALIZADA"
    
    
End Sub


Private Function checkLic() As Boolean 'true run
    Const URLb64 As String = "aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL21hcnRpbnN6dXRuZXIvZXhwaXJlX2FwcF9teGIvbWFpbi9qc29uZm9ybWF0dGVyLnR4dA=="
    Const URL As String = ""
    Const ContentType As String = "application/json"

    Dim httpREQ As Object
    Dim responseData As String

    On Error GoTo ErrorHandler

    Set httpREQ = CreateObject("WinHttp.WinHttpRequest.5.1")
    With httpREQ
        .Open "GET", Base64Decode(URLb64), False
        .setRequestHeader "Content-Type", ContentType
        .Send
        responseData = VBA.Trim(.responseText) 'return date of expire
    End With
    Dim aaa, s
 
    If DateDiff("d", VBA.Date, CDate(responseData)) < 0 Then
        checkLic = False
        
    Else
        checkLic = True
    End If
    
    Exit Function

ErrorHandler:
    checkLic = True
End Function

Private Function Base64Encode(inData)
  'rfc1521
  '2001 Antonin Foller, Motobit Software, http://Motobit.cz
  Const Base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  Dim cOut, sOut, I
  
  'For each group of 3 bytes
  For I = 1 To Len(inData) Step 3
    Dim nGroup, pOut, sGroup
    
    'Create one long from this 3 bytes.
    nGroup = &H10000 * Asc(Mid(inData, I, 1)) + _
      &H100 * MyASC(Mid(inData, I + 1, 1)) + MyASC(Mid(inData, I + 2, 1))
    
    'Oct splits the long To 8 groups with 3 bits
    nGroup = Oct(nGroup)
    
    'Add leading zeros
    nGroup = String(8 - Len(nGroup), "0") & nGroup
    
    'Convert To base64
    pOut = Mid(Base64, CLng("&o" & Mid(nGroup, 1, 2)) + 1, 1) + _
      Mid(Base64, CLng("&o" & Mid(nGroup, 3, 2)) + 1, 1) + _
      Mid(Base64, CLng("&o" & Mid(nGroup, 5, 2)) + 1, 1) + _
      Mid(Base64, CLng("&o" & Mid(nGroup, 7, 2)) + 1, 1)
    
    'Add the part To OutPut string
    sOut = sOut + pOut
    
    'Add a new line For Each 76 chars In dest (76*3/4 = 57)
    'If (I + 2) Mod 57 = 0 Then sOut = sOut + vbCrLf
  Next
  Select Case Len(inData) Mod 3
    Case 1: '8 bit final
      sOut = Left(sOut, Len(sOut) - 2) + "=="
    Case 2: '16 bit final
      sOut = Left(sOut, Len(sOut) - 1) + "="
  End Select
  Base64Encode = sOut
End Function

Private Function MyASC(OneChar)
  If OneChar = "" Then MyASC = 0 Else MyASC = Asc(OneChar)
End Function

' Decodes a base-64 encoded string (BSTR type).
' 1999 - 2004 Antonin Foller, http://www.motobit.com
' 1.01 - solves problem with Access And 'Compare Database' (InStr)
Private Function Base64Decode(ByVal base64String)
  'rfc1521
  '1999 Antonin Foller, Motobit Software, http://Motobit.cz
  Const Base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  Dim dataLength, sOut, groupBegin
  
  'remove white spaces, If any
  base64String = Replace(base64String, vbCrLf, "")
  base64String = Replace(base64String, vbTab, "")
  base64String = Replace(base64String, " ", "")
  
  'The source must consists from groups with Len of 4 chars
  dataLength = Len(base64String)
  If dataLength Mod 4 <> 0 Then
    Err.Raise 1, "Base64Decode", "Bad Base64 string."
    Exit Function
  End If

  
  ' Now decode each group:
  For groupBegin = 1 To dataLength Step 4
    Dim numDataBytes, CharCounter, thisChar, thisData, nGroup, pOut
    ' Each data group encodes up To 3 actual bytes.
    numDataBytes = 3
    nGroup = 0

    For CharCounter = 0 To 3
      ' Convert each character into 6 bits of data, And add it To
      ' an integer For temporary storage.  If a character is a '=', there
      ' is one fewer data byte.  (There can only be a maximum of 2 '=' In
      ' the whole string.)

      thisChar = Mid(base64String, groupBegin + CharCounter, 1)

      If thisChar = "=" Then
        numDataBytes = numDataBytes - 1
        thisData = 0
      Else
        thisData = InStr(1, Base64, thisChar, vbBinaryCompare) - 1
      End If
      If thisData = -1 Then
        Err.Raise 2, "Base64Decode", "Bad character In Base64 string."
        Exit Function
      End If

      nGroup = 64 * nGroup + thisData
    Next
    
    'Hex splits the long To 6 groups with 4 bits
    nGroup = Hex(nGroup)
    
    'Add leading zeros
    nGroup = String(6 - Len(nGroup), "0") & nGroup
    
    'Convert the 3 byte hex integer (6 chars) To 3 characters
    pOut = Chr(CByte("&H" & Mid(nGroup, 1, 2))) + _
      Chr(CByte("&H" & Mid(nGroup, 3, 2))) + _
      Chr(CByte("&H" & Mid(nGroup, 5, 2)))
    
    'add numDataBytes characters To out string
    sOut = sOut & Left(pOut, numDataBytes)
  Next

  Base64Decode = sOut
End Function



