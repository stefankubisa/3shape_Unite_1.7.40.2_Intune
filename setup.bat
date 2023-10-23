pushd %~dp0
:: Setting local folder, required when running as administrator

mkdir "C:\3Shape" >nul 2>&1 
mkdir "C:\Program Files\3Shape\TRIOS Shell" >nul 2>&1 
mkdir "C:\Programdata\3Shape\DentalDesktop" >nul 2>&1 
:: we need to work in those directories so the installation process completes and no, this can't be done in the .ps1 file, it has to be here in the .bat file 
TIMEOUT /T 3 >nul 2>&1
xcopy "%~dp03Shape" "C:\3Shape" /E /H /C /R /Q /Y >nul 2>&1 
xcopy "%~dp03Shape\TRIOS\TRIOS Shell" "C:\Program Files\3Shape\TRIOS Shell" /E /H /C /R /Q /Y >nul 2>&1 
xcopy "%~dp03Shape\DentalDesktop" "C:\Programdata\3Shape\DentalDesktop" /E /H /C /R /Q /Y >nul 2>&1
:: we copy the files intune downloads here for installation and if later needed reinstallationand no, this can't be done in the .ps1 file, it has to be here in the .bat file 
TIMEOUT /T 3 >nul 2>&1

powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope LocalMachine -Force" >nul 2>&1
TIMEOUT /T 3 >nul 2>&1

powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser -Force" >nul 2>&1
TIMEOUT /T 3 >nul 2>&1 
:: we never bothered finding out which one allowes us to proceed but one or 2 of those are required for certain commands inside the .ps1 script 

powershell -executionpolicy remotesigned -File C:\3Shape\setup.ps1 
:: and finally we start what we need to have the installation happen 

popd 
:: changes the current directory to the directory that was most recently stored by the pushd command 

shutdown /r /t 0 /f 
:: and one final restart to make sure all changes are applied and make sure that upon restart all services needed are running
