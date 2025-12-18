' Script para gerar games-manifest.js automaticamente
' Versão: Dinâmica (Escaneia todas as subpastas em "games")

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
    ' Procura arquivos HTML dentro de cada subpasta
    For Each file In subFolder.Files
        If LCase(fso.GetExtensionName(file.Name)) = "html" Or LCase(fso.GetExtensionName(file.Name)) = "htm" Then
            
            ' Cria o caminho relativo (ex: games/computacional/jogo.html)
            Dim relativePath
            relativePath = "games/" & subFolder.Name & "/" & file.Name
            
            ' Limpa o nome para usar como Título (tira a extensão)
            Dim title
            title = Replace(file.Name, ".html", "")
            title = Replace(title, ".htm", "")
            ' Remove underscores e hifens para ficar bonito
            title = Replace(title, "-", " ")
            title = Replace(title, "_", " ")
            
            ' Adiciona vírgula se não for o primeiro item
            If entryList <> "" Then entryList = entryList & "," & vbCrLf
            
            ' Adiciona ao JSON
            entryList = entryList & "    { ""path"": """ & relativePath & """, ""title"": """ & UCase(title) & """ }"
        End If
    Next
Next

' 4. Finaliza e Salva
outputContent = outputContent & vbCrLf & entryList & vbCrLf & "  ]" & vbCrLf & "};"

' Escreve o arquivo (Forçando codificação simples para evitar erros de caractere)
Dim objStream
Set objStream = CreateObject("ADODB.Stream")
objStream.CharSet = "utf-8"
objStream.Open
objStream.WriteText outputContent
objStream.SaveToFile outputFile, 2 ' 2 = Sobrescrever
objStream.Close

MsgBox "Manifesto atualizado com sucesso!" & vbCrLf & "Novos jogos detectados.", 64, "Sucesso"

