@echo off

set NAME=KBFR222

if not exist Release mkdir Release

::Assemble keyboard driver
zmac\zmac --mras %NAME%.ASM -o Release\%NAME%.cim
if errorlevel 1 pause && goto :eof

::Rename keyboard driver to *.COM
move /Y Release\%NAME%.cim Release\%NAME%.COM
if errorlevel 1 pause && goto :eof

