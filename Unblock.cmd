@echo off

PowerShell -ExecutionPolicy Unrestricted "dir -recurse | unblock-file"
