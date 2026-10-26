@echo off
rem In-workspace shim so agents can call this without a ..\ path.
call "%~dp0..\rag-search.bat" %*
