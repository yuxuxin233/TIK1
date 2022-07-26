:: TEST
@echo off

echo "Success" 
echo "FAIL" & call :RET1 || call :LOGE "TEST"

exit /b 0
:LOGE
echo ERROR : %*
goto :eof

:RET1
exit /b 1