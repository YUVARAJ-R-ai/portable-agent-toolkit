@echo off
rem Usage: dev.bat -- enters a shell with the portable dev toolchains on PATH
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dev.ps1" %*
