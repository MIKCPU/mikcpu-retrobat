@echo off
echo.
echo Gamelist Synchronizer ~MIKCPU Retrobat Maximusbat~ 
echo.
echo Welcome to Mikcpu Gamelist Synchronizer, By MIKCPU!
echo This script will syncronize gamelist.xml for all bundles/addons in V:\RetroBat\roms\
echo IMPORTANT! Recommended to run MIKCPU's Updater first.
echo.
echo Refer to MIKCPU's github repo for all changes at https://github.com/mikcpu/mikcpu-retrobat
echo.
echo IMPORTANT! - Backup all your gamelist.xml before continuing.
echo RetroBat/Emulationstation will close automatically during the sync process.
echo.
echo Press any key to continue to start the sync process - be patient . . .
pause >nul
echo Terminating running Retrobat processes...
echo.
TASKKILL /F /IM retrobat.exe /IM emulationstation.exe /IM retroarch.exe 2>nul
robocopy V:\_tools\mikcpu-retrobat-master\roms V:\RetroBat\roms gamelist.xml /S /NFL /NDL /IS /MT:4
echo.
echo Sync Completed. Enjoy! :)
echo.
echo Press any key to continue . . .
pause >nul
 