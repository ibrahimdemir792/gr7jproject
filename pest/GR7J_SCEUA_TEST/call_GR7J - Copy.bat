@echo off
REM delete old files

rem del /F %~dp0*.out
rem del /F %~dp0*.Rout


SET "slave=1"


SET OMP_NUM_THREADS=12
ECHO %OMP_NUM_THREADS%


rem "C:\Program Files\MATLAB\R2016b\bin\matlab.exe" CMD BATCH --vanilla karasu_hymod1.m
matlab -wait -nojvm -nosplash -nodesktop -minimize -r "GR7J_snowlu" -logfile output.log

:LOOPSTART
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq MATLAB.exe"') DO IF %%x == MATLAB.exe goto FOUND
goto FIN
:FOUND
TIMEOUT /T 30
goto LOOPSTART
:FIN



@echo off
setlocal enableextensions enabledelayedexpansion
set /p COUNTER=<.\OF.out
echo CURRENT NSE is %COUNTER%


ping 127.0.0.1 -n 2 > nul 

 rem pause