@echo off
rem Usage: rag-search.bat "<query>" [-List]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rag-search.ps1" %*
