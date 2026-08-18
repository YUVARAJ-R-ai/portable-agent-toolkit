@echo off
rem Usage: start.bat [model] [-Orchestrator opencode|goose] [-Vulkan]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1" %*
