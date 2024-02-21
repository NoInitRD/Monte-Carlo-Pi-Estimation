@echo off
ml64 /c monteCarlo.asm
cl monteCarloDriver.cpp monteCarlo.obj
monteCarloDriver.exe

