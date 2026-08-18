@echo off
rem Usage: claude-code.bat [-SkipPermissions] [claude args...]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0claude-code.ps1" %*
