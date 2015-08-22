@echo off

setlocal

if not exist Output md Output

cd Source

call Build %*
