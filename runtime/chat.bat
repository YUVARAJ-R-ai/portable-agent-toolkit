@echo off
rem Usage: chat.bat [model] [-Vulkan]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0chat.ps1" %*
