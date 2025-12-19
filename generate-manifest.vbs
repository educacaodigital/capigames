' Script para gerar games-manifest.js automaticamente
' Versão: LER TÍTULO DO HTML (<title>...</title>)
' Se não achar o title, usa o nome do arquivo.

Option Explicit

Dim fso, currentDir, gamesDir, outputFile
Dim outputContent, entryList
Dim folder, subFolder, file

Set fso = CreateObject("Scripting.FileSystemObject")

' 1. Define diretórios
currentDir = fso.GetAbsolutePathName(".")
gamesDir = fso.BuildPath(currentDir, "games")
outputFile = fso.BuildPath(currentDir, "games-manifest.js")

' Verifica se a pasta games existe
If Not fso.FolderExists(gamesDir) Then
    MsgBox "A pasta 'games' nao foi encontrada!", 16, "Erro"
    WScript.Quit
End If

' 2. Começa a montar o JSON
outputContent = "window.CAPI_MANIFEST = {" & vbCrLf & _
                "  ""generated_at"": """ & Now & """," & vbCrLf & _
                "  ""entries"": ["

entryList = ""

' 3. Varre TODAS as subpastas dentro de 'games'
Set folder = fso.GetFolder(gamesDir)

For Each subFolder In folder.SubFolders
    For Each file In subFolder.Files
        ' Verifica se é HTML
        If LCase(fso.GetExtensionName(file.Name)) = "html" Or LCase(fso.GetExtensionName(file.Name)) = "htm" Then
            
            Dim relativePath, finalTitle
            relativePath = "games/" & subFolder.Name & "/" & file.Name
            
            ' Tenta ler o <title> de dentro do arquivo
            finalTitle = GetHtmlTitle(file.Path)
            
            ' Se não achou título no código, usa o nome do arquivo limpo
            If finalTitle = "" Then
                finalTitle = CleanFileName(file.Name)
            End If
            
            ' Adiciona vírgula se necessário
            If entryList <> "" Then entryList = entryList & "," & vbCrLf
            
            ' Adiciona ao JSON (Title em UpperCase para manter padrão)
            entryList = entryList & "    { ""path"": """ & relativePath & """, ""title"": """ & UCase(finalTitle) & """ }"
        End If
    Next
Next

' 4. Finaliza e Salva o manifesto
outputContent = outputContent & vbCrLf & entryList & vbCrLf & "  ]" & vbCrLf & "};"

WriteFileUTF8 outputFile, outputContent

MsgBox "Manifesto atualizado!" & vbCrLf & "Os nomes agora foram pegos da tag <title> dos jogos.", 64, "Sucesso"

' ==========================================
' FUNÇÕES AUXILIARES
' ==========================================

' Função para ler o arquivo e extrair o conteúdo da tag <title>
Function GetHtmlTitle(filePath)
    On Error Resume Next
    Dim objStream, content, regex, matches
    Set objStream = CreateObject("ADODB.Stream")
    
    ' Abre arquivo como UTF-8 para não quebrar acentos
    objStream.CharSet = "utf-8"
    objStream.Open
    objStream.LoadFromFile filePath
    content = objStream.ReadText
    objStream.Close
    
    ' Procura por <title>...</title> usando Regex
    Set regex = New RegExp
    regex.IgnoreCase = True
    regex.Global = False
    ' Padrão: <title (qualquer coisa) > (texto) </title>
    regex.Pattern = "<title[^>]*>([\s\S]*?)<\/title>"
    
    If regex.Test(content) Then
        Set matches = regex.Execute(content)
        GetHtmlTitle = Trim(matches(0).SubMatches(0))
    Else
        GetHtmlTitle = ""
    End If
    
    If Err.Number <> 0 Then GetHtmlTitle = ""
End Function

' Função para escrever arquivo em UTF-8 (para salvar os acentos corretamente no manifesto)
Sub WriteFileUTF8(filePath, textContent)
    Dim objStream
    Set objStream = CreateObject("ADODB.Stream")
    objStream.CharSet = "utf-8"
    objStream.Open
    objStream.WriteText textContent
    objStream.SaveToFile filePath, 2 ' 2 = Sobrescrever
    objStream.Close
End Sub

' Fallback: Limpa o nome do arquivo se não tiver title
Function CleanFileName(fName)
    Dim t
    t = Replace(fName, ".html", "")
    t = Replace(t, ".htm", "")
    t = Replace(t, "-", " ")
    t = Replace(t, "_", " ")
    CleanFileName = t
End Function
