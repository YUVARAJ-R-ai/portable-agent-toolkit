@echo off
rem Usage: switch-model.bat [-List] [ModelFilename]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0switch-model.ps1" %*
