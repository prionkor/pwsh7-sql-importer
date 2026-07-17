@echo off
cd /d "%~dp0"
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "miner.ps1" -Scheduled
