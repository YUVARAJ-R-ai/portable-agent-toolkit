@echo off
rem Usage: install.bat [-Target <dir>] [-Components core,dev] [-Models qwen2.5-coder]
rem Forwards to install.ps1. See docs/install.md.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
