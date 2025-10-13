' update-capigames.vbs  (versão corrigida)
Option Explicit

Dim owner
Dim repo
Dim branch
owner  = "educacaodigital"
repo   = "capigames"
branch = "main"

Dim fso
Dim shell
Dim wsh
Set fso   = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("Shell.Application")
Set wsh   = CreateObject("WScript.Shell")

Dim scriptDir
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
If scriptDir = "" Then scriptDir = fso.GetAbsolutePathName(".")

Dim tempGuid
tempGuid = CreateObject("Scriptlet.TypeLib").Guid
tempGuid = Replace(tempGuid, "{", "")
tempGuid = Replace(tempGuid, "}", "")
tempGuid = Replace(tempGuid, "-", "")

Dim tempRoot
tempRoot = fso.BuildPath(wsh.ExpandEnvironmentStrings("%TEMP%"), "capigames_update_" & tempGuid)

If Not fso.FolderExists(tempRoot) Then fso.CreateFolder tempRoot

Dim extractPath
extractPath = fso.BuildPath(tempRoot, "extracted")
If Not fso.FolderExists(extractPath) Then fso.CreateFolder extractPath

Dim zipPath
zipPath = fso.BuildPath(tempRoot, "repo.zip")

WScript.Echo "[INFO ] Destino: " & scriptDir
WScript.Echo "[INFO ] Repo: " & owner & "/" & repo & " (branch: " & branch & ")"

Dim zipUrl
zipUrl = "https://codeload.github.com/" & owner & "/" & repo & "/zip/refs/heads/" & branch

If DownloadFile(zipUrl, zipPath) = False Then
  WScript.Echo "[ERR  ] Falha ao baixar ZIP"
  WScript.Quit 1
End If
WScript.Echo "[ OK  ] ZIP baixado: " & zipPath

If ExtractZip(zipPath, extractPath) = False Then
  WScript.Echo "[ERR  ] Falha ao extrair ZIP"
  WScript.Quit 1
End If
WScript.Echo "[ OK  ] ZIP extraído em: " & extractPath

Dim repoRoot
repoRoot = fso.BuildPath(extractPath, repo & "-" & branch)
If Not fso.FolderExists(repoRoot) Then
  Dim d
  For Each d In fso.GetFolder(extractPath).SubFolders
    repoRoot = d.Path
    Exit For
  Next
End If
If Not fso.FolderExists(repoRoot) Then
  WScript.Echo "[ERR  ] Pasta do repositório não encontrada."
  WScript.Quit 1
End If
WScript.Echo "[INFO ] Raiz do repo: " & repoRoot

' exclusões
Dim excludeDirs
excludeDirs = Array(".git", ".github")

Dim excludeFiles
excludeFiles = Array("README.md", ".gitignore", ".gitattributes", "LICENSE")

If CopyTree(repoRoot, scriptDir, excludeDirs, excludeFiles) = False Then
  WScript.Echo "[ERR  ] Falha ao copiar arquivos."
  WScript.Quit 1
End If

WScript.Echo "[ OK  ] Atualização concluída."

'========================
' FUNÇÕES
'========================
Function DownloadFile(url, outPath)
  On Error Resume Next
  Dim xhr
  Set xhr = CreateObject("MSXML2.XMLHTTP")
  xhr.open "GET", url, False
  xhr.send
  If xhr.Status <> 200 Then
    DownloadFile = False
    Exit Function
  End If

  Dim stm
  Set stm = CreateObject("ADODB.Stream")
  stm.Type = 1 'binário
  stm.Open
  stm.Write xhr.responseBody
  stm.SaveToFile outPath, 2
  stm.Close
  Set stm = Nothing
  Set xhr = Nothing
  DownloadFile = True
End Function

Function ExtractZip(zipFile, destFolder)
  On Error Resume Next
  Dim zipNs
  Dim destNs
  Set zipNs = shell.NameSpace(zipFile)
  Set destNs = shell.NameSpace(destFolder)
  If (zipNs Is Nothing) Or (destNs Is Nothing) Then
    ExtractZip = False
    Exit Function
  End If
  ' FOF_NOCONFIRMMKDIR = &H200 (usa 0x10 no PS, aqui basta 0)
  destNs.CopyHere zipNs.Items, 16
  WScript.Sleep 2000
  ExtractZip = True
End Function

Function CopyTree(src, dst, exDirs, exFiles)
  On Error Resume Next
  If Not fso.FolderExists(dst) Then fso.CreateFolder dst

  Dim file
  For Each file In fso.GetFolder(src).Files
    If Not IsInArray(fso.GetFileName(file.Path), exFiles) Then
      fso.CopyFile file.Path, fso.BuildPath(dst, fso.GetFileName(file.Path)), True
    End If
  Next

  Dim subf
  For Each subf In fso.GetFolder(src).SubFolders
    If Not IsInArray(fso.GetFileName(subf.Path), exDirs) Then
      Dim destSub
      destSub = fso.BuildPath(dst, fso.GetFileName(subf.Path))
      CopyTree subf.Path, destSub, exDirs, exFiles
    End If
  Next
  CopyTree = True
End Function

Function IsInArray(name, arr)
  Dim i
  For i = 0 To UBound(arr)
    If LCase(arr(i)) = LCase(name) Then
      IsInArray = True
      Exit Function
    End If
  Next
  IsInArray = False
End Function
