@echo off
echo.
echo Collection Synchronizer ~Retrobat Maximusbat~ 
echo.
echo Welcome to MIKCPU Collection Synchronizer, By MIKCPU!
echo This script will syncronize all custom-collections.cfg for all  bundles/addons in V:\RetroBat\emulationstation\.emulationstation\collections\
echo IMPORTANT! Recommended to run MIKCPU's Updater first.
echo.
echo Refer to MIKCPU's github repo for all changes at https://github.com/MIKCPU/mikcpu-retrobat
echo.
echo IMPORTANT! - Backup all your custom-collection.cfg before continuing.
echo RetroBat/Emulationstation will close automatically during the sync process.
echo.
echo Press any key to continue to start the sync process - be patient . . .
pause >nul
echo Terminating running Retrobat processes...
echo.
TASKKILL /F /IM retrobat.exe /IM emulationstation.exe /IM retroarch.exe 2>nul
robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulationstation\.emulationstation\collections V:\RetroBat\emulationstation\.emulationstation\collections /S /NFL /NDL /IS /MT:4
echo.
echo Sync Completed. Enjoy! :)
echo.
echo Press any key to continue . . .
pause >nul
 