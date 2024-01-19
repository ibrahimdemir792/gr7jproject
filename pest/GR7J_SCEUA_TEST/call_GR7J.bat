@echo off


SET "slave=1"


SET OMP_NUM_THREADS=4
ECHO %OMP_NUM_THREADS%

matlab -wait -nojvm -nosplash -nodesktop -minimize -r "GR7J_snowlu" -logfile output.log


@echo off
setlocal enableextensions enabledelayedexpansion
set /p COUNTER=<.\OF.out
echo CURRENT NSE is %COUNTER%


ping 127.0.0.1 -n 2 > nul 

 rem pause