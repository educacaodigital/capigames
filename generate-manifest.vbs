' generate-manifest.vbs — gera games-manifest.js para estrutura com BASE_DIR = "games"
Option Explicit

Const BASE_DIR = "games"

Dim fso, wsh
Set fso = CreateObject("Scripting.FileSystemObject")
Set wsh = CreateObject("WScript.Shell")

Dim rootDir
rootDir = fso.GetParentFolderName(WScript.ScriptFullName)
If rootDir = "" Then rootDir = fso.GetAbsolutePathName(".")

Dim basePath
basePath = fso.BuildPath(rootDir, BASE_DIR)
If Not fso.FolderExists(basePath) Then
  WScript.Echo "[ERRO] Pasta '" & BASE_DIR & "' não encontrada em: " & rootDir
  WScript.Quit 1
End If

Dim cats : cats = Array("1-3","4-5","6-10","11-14","naee")

Dim excludeDirs
excludeDirs = Array(".git",".github","assets","static","img","images","css","js","vendor","node_modules")

Dim excludeFilesTop
excludeFilesTop = Array("README.md",".gitignore",".gitattributes","LICENSE","games-manifest.js","generate-manifest.vbs","index.html")

Dim listJson : listJson = "["
Dim isFirst : isFirst = True

Dim i
For i = 0 To UBound(cats)
  Dim cat, catPath
  cat = cats(i)
  catPath = fso.BuildPath(basePath, cat)
  If fso.FolderExists(catPath) Then
    Walk catPath, cat
  End If
Next

listJson = listJson & "]"

Dim stamp : stamp = NowISO()
Dim out
out = "window.CAPI_MANIFEST = {""generated_at"":""" & J(stamp) & """,""entries"":" & listJson & "};" & vbCrLf

Dim outPath
outPath = fso.BuildPath(rootDir, "games-manifest.js")
If WriteUtf8(outPath, out) Then
  WScript.Echo "[OK] Manifesto gerado: " & outPath
Else
  WScript.Echo "[ERRO] Falha ao escrever: " & outPath
End If

' ====== funções ======
Sub Walk(folderPath, catName)
  Dim d, f
  ' arquivos
  For Each f In fso.GetFolder(folderPath).Files
    If LCase(fso.GetExtensionName(f.Name)) = "html" Then
      If Not IsInArray(LCase(f.Name), MapLower(excludeFilesTop)) Then
        AddEntry f.Path, catName
      End If
    End If
  Next
  ' subpastas
  For Each d In fso.GetFolder(folderPath).SubFolders
    If Not IsInArray(d.Name, excludeDirs) Then
      Walk d.Path, catName
    End If
  Next
End Sub

Sub AddEntry(fullPath, catName)
  Dim relFromRoot, relNormalized, title
  ' Caminho relativo a partir da RAIZ do projeto (onde está o index.html)
  relFromRoot = Replace(fullPath, rootDir & "\", "")
  relNormalized = Replace(relFromRoot, "\", "/")
  ' Garante prefixo "games/"
  If LCase(Left(relNormalized, Len(BASE_DIR)+1)) <> LCase(BASE_DIR & "/") Then
    relNormalized = BASE_DIR & "/" & relNormalized
  End If
  ' Ignora um "index.html" que por acaso esteja na raiz do projeto
  If LCase(relNormalized) = "index.html" Then Exit Sub

  title = ReadTitle(fullPath)
  If title = "" Then title = StripExt(fso.GetFileName(fullPath))

  If Not isFirst Then
    listJson = listJson & ","
  Else
    isFirst = False
  End If
  listJson = listJson & "{""path"":""" & J(relNormalized) & """,""title"":""" & J(title) & """,""category"":""" & J(catName) & """}"
End Sub

Function ReadTitle(p)
  On Error Resume Next
  Dim s, txt, re, m
  ReadTitle = ""
  Set s = CreateObject("ADODB.Stream")
  s.Type = 1 : s.Open : s.LoadFromFile p
  s.Position = 0 : s.Type = 2 : s.Charset = "utf-8"
  txt = s.ReadText(-1)
  s.Close : Set s = Nothing
  If Len(txt) = 0 Then Exit Function

  Set re = New RegExp
  re.Pattern = "<title[^>]*>([\s\S]*?)</title>"
  re.IgnoreCase = True
  re.Global = False
  Set m = re.Execute(txt)
  If m.Count > 0 Then ReadTitle = Trim(m(0).SubMatches(0))
End Function

Function StripExt(n)
  Dim p : p = InStrRev(n,".")
  If p>0 Then StripExt = Left(n,p-1) Else StripExt = n
End Function

Function J(s)
  Dim r : r = s
  r = Replace(r, "\", "\\")
  r = Replace(r, """", "\""")
  r = Replace(r, vbCrLf, "\n")
  r = Replace(r, vbCr, "\n")
  r = Replace(r, vbLf, "\n")
  J = r
End Function

Function WriteUtf8(path, content)
  On Error Resume Next
  Dim st : Set st = CreateObject("ADODB.Stream")
  st.Type = 2 : st.Charset = "utf-8" : st.Open
  st.WriteText content
  st.SaveToFile path, 2
  st.Close : Set st = Nothing
  WriteUtf8 = True
End Function

Function IsInArray(v, arr)
  Dim k
  For k = 0 To UBound(arr)
    If LCase(arr(k)) = LCase(v) Then IsInArray = True : Exit Function
  Next
  IsInArray = False
End Function

Function MapLower(arr)
  Dim i, out : ReDim out(UBound(arr))
  For i=0 To UBound(arr) : out(i)=LCase(arr(i)) : Next
  MapLower = out
End Function

Function NowISO()
  Dim d: d = Now
  NowISO = Year(d) & "-" & Right("0"&Month(d),2) & "-" & Right("0"&Day(d),2) & "T" & Right("0"&Hour(d),2) & ":" & Right("0"&Minute(d),2) & ":" & Right("0"&Second(d),2)
End Function
