@echo off
setlocal

if exist *.bin del *.bin
if exist *.com del *.com
if exist *.img del *.img
if exist *.rom del *.rom
if exist *.upd del *.upd
if exist *.lst del *.lst
if exist *.exp del *.exp
if exist *.tmp del *.tmp
if exist *.mrk del *.mrk
if exist *.sys del *.sys
if exist build.inc del build.inc
if exist font*.asm del font*.asm
if exist build_env.cmd del build_env.cmd
if exist hbios_env.cmd del hbios_env.cmd
