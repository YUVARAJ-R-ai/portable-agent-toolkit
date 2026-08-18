@echo off
rem Usage: update.bat <target_dir>
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1" %*
