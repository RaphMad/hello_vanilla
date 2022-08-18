@echo off


set vcv="C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
set nasm="nasm.exe"

if not exist out mkdir out
%nasm% -f win64 src\hello.asm -o out\hello.obj
CMD /c "call %vcv% & link.exe out\hello.obj /entry:_start /nodefaultlib /subsystem:console /out:out\hello.exe"
