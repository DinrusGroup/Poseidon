@echo ============================
@echo     Building  Poseidon
@echo ============================

del *.obj *.rsp *.ksp *.def *.html /s /q
c:\dm\bin\bud poseidon/poseidon.d -release -O -Xdwt -Xdparser -gui -allobj -clean -version=OLE_COM -Tposeidon.exe -I../dwt/import/ -Id:/codeanalyzer dparser/dparser.lib
pause
