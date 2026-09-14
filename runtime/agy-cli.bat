@echo off
rem Usage: agy-cli.bat [-Workspace <dir>] [agy args...]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0agy-cli.ps1" %*
