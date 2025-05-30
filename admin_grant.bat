@echo off
net localgroup Administrators %username% /add
echo %username% has been added to the Administrators group.
pause
