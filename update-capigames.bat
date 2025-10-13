@echo off
title Atualizador do Capi Games
color 0A
chcp 65001 >nul

setlocal
cd /d "%~dp0"

echo ============================================================
echo       ATUALIZADOR DO PROJETO CAPI GAMES - EDUCACAODIGITAL
echo ============================================================
echo.
echo Iniciando atualização... (%date% %time%)
echo.

REM Executa o script VBScript e mostra o resultado no terminal
cscript //nologo "%~dp0update-capigames.vbs"

echo.
echo ============================================================
echo      Atualização concluída! (%date% %time%)
echo ============================================================
echo.

pause
exit /b
