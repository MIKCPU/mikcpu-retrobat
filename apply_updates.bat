@echo off
echo.
echo Apply Updates ~Retrobat Maximusbat v 1.0 ~ 
echo Terminating running Retrobat processes...
echo.
TASKKILL /F /IM retrobat.exe /IM emulationstation.exe /IM retroarch.exe 2>nul
DEL /F /Q %TEMP%\mikcpu_update.tmp 2>nul
pushd V:\_tools
for /f "skip=3 eol=: delims=" %%F in ('dir /b /o-d mikcpu-update-*.log') do @del "%%F" 2>nul
popd
echo Welcome to Maximusbat Post-Fixes and Optimization Menu, By MIKCPU!
echo This script will update and optimize common Retrobat files to any other associated files for MIKCPU's build.
echo IMPORTANT! - RetroBat/Emulationstation will close automatically during the update process.
echo.
echo Refer to MIKCPU's github repo for all changes at https://github.com/MIKCPU/mikcpu-retrobat
echo You also have option to run from cli v:\_tools\Retrobat_updater.bat.
echo.
echo IMPORTANT! - Backup all your config files manually, however script will create backup of any existing files with extension of *.VM
echo.
echo Press any key to continue to start the update process - be patient . . .
pause >nul

powershell -Command "$ErrorActionPreference= 'silentlycontinue' ; (Get-Content 'V:\_tools\mikcpu-retrobat-master\updates.txt') -notlike '#*' | ConvertFrom-Csv -Delimiter '|' | ForEach-Object {ForEach ($file in (Get-ChildItem -Path "$($_.Files)" -exclude *.VM)){Remove-Item -ErrorAction SilentlyContinue -Path $($file.fullname + '.VM');Copy-Item -Path $($file.fullname) -Destination $($file.fullname + '.VM');$filecontent = Get-Content -path $file ; if ($($_.LineNr)) {$filecontent[$($_.LineNr)] = $filecontent[$($_.LineNr)] -creplace $($_.SearchTxt),$($_.ReplaceTxt)} else {$filecontent = $filecontent -creplace $($_.SearchTxt),$($_.ReplaceTxt)} ; Set-Content $file.PSpath -Value $filecontent }}"

rem 1. 2021-07-11 - Fix Spider-Man The Video Game Arcade bezelproject decoration and for any other future missing overlays.
rem robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\decorations\thebezelproject\games\ V:\RetroBat\decorations\thebezelproject\games\ /S /NFL /NDL /IS /MT:4
rem 2. 2021-07-18 - GameCube Controller mapping fix (x/y swap) and for any other future controller profiles for dolphin.
rem robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulators\dolphin-emu\ V:\RetroBat\emulators\dolphin-emu\ /S /NFL /NDL /IS /MT:4

rem 3. 2021-08-05 - Corrent snap naming for High Octane.
rem "V:\RetroBat\roms\dos\snap\Hi Octane.pc.mp4" "Hi Octane.mp4"

rem 4. 2021-10-08 - rpcs3 emulator fix missing HDD PS3 games.
rem robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulators\rpcs3\ V:\RetroBat\emulators\rpcs3\ /S /NFL /NDL /IS /MT:4

rem 5. 2021-11-08 - amigacd32 change controller remap to cd32 + extra emulator configs (vic-20).
rem robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulators\retroarch\ V:\RetroBat\emulators\retroarch\ /S /NFL /NDL /IS /MT:4

rem 6. 2021-11-14 - snes9x change controller remap for 'H' some home brew games.
rem robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulators\snes9x\ V:\RetroBat\emulators\snes9x\ /S /NFL /NDL /IS /MT:4

rem 7. 2021-12-24 - sync mikcpu custom collections.
rem robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulationstation\.emulationstation\collections\ V:\RetroBat\emulationstation\.emulationstation\collections\ /S /NFL /NDL /IS /MT:4

rem 8. 2021-12-28 - EmulationStation Theme fix for apple2/c20.
rem robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulationstation\.emulationstation\themes\ V:\RetroBat\emulationstation\.emulationstation\themes\ /S /NFL /NDL /IS /MT:4

rem 9. 2022-04-02 - Fix PS3 After Burner Climax.m3u.
rem copy /y "V:\_tools\mikcpu-retrobat-master\roms\ps3\After Burner Climax.m3u" V:\RetroBat\roms\ps3\

rem 10. 2022-05-08 - Xbox Xemu config update for 0.7.x.
rem robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulators\xemu\ V:\RetroBat\emulators\xemu\ /S /NFL /NDL /IS /MT:4

rem 11. 2022-06-11 - Add lr-hatari settings if not existing, search/replace via updates.txt used afterwards
rem set RAOPTS=V:\RetroBat\emulators\retroarch\retroarch-core-options.cfg
rem findstr /c:"hatari_frameskips" %RAOPTS% >nul || echo hatari_frameskips = "0" >> %RAOPTS%
rem findstr /c:"hatari_nokeys" %RAOPTS% >nul || echo hatari_nokeys = "false" >> %RAOPTS%
rem findstr /c:"hatari_nomouse" %RAOPTS% >nul || echo hatari_nomouse = "false" >> %RAOPTS%
rem findstr /c:"hatari_polarized_filter" %RAOPTS% >nul || echo hatari_polarized_filter = "false" >> %RAOPTS%
rem findstr /c:"hatari_twojoy" %RAOPTS% >nul || echo hatari_twojoy = "false" >> %RAOPTS%
rem findstr /c:"hatari_video_crop_overscan" %RAOPTS% >nul || echo hatari_video_crop_overscan = "true" >> %RAOPTS%
rem findstr /c:"hatari_video_hires" %RAOPTS% >nul || echo hatari_video_hires = "true" >> %RAOPTS%

rem 1. 2022-12-18 - Sync Default values reported by Virtualman
robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\backup\ V:\RetroBat\backup\ /S /NFL /NDL /IS /MT:4

rem 2. 2022-12-21 - Fix PS3 Metal Gear Solid - Peace Walker HD Edition (USA).m3u - reported by Lydonb77
copy /y "V:\_tools\mikcpu-retrobat-master\roms\ps3\Metal Gear Solid - Peace Walker HD Edition (USA).m3u" V:\RetroBat\roms\ps3\

rem 3. 2022-12-30 - amigacd32 added controller remap to support cd32 and other retroarch future configs - reported by Virtualman
robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulators\retroarch\ V:\RetroBat\emulators\retroarch\ /S /NFL /NDL /IS /MT:4

rem 4. 2023-12-21 - Fix Rockin'Bliss shortcut from Ports - Note: Change Drive according to your location C: or V: - reported by Virtualman
copy /y "V:\_tools\mikcpu-retrobat-master\roms\ports\Rockin'Bliss!.lnk" V:\RetroBat\roms\ports\

rem 5. 2023-1-19 - EmulationStation Theme fixes - reported by Virtualman
robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulationstation\.emulationstation\themes\ V:\RetroBat\emulationstation\.emulationstation\themes\ /S /NFL /NDL /IS /MT:4

rem 6. 2023-1-22 - Saves for Retroarch (Terminator2, Mame bind new key) and more fixes - reported by Virtualman
robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\saves\ V:\RetroBat\saves\ /S /NFL /NDL /IS /MT:4

rem 7. 2023-1-24 - Update configurations backup script - reported by Bilu
robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\backup\ V:\RetroBat\backup\ /S /NFL /NDL /IS /MT:4
copy /y V:\RetroBat\backup\mikcpu_backupcfg.bat V:\RetroBat\emulationstation\.emulationstation\scripts\quit\

rem 8. 2023-1-30 - rpcs3 restore default.yml as Retrobat 5.1 was overriding causing inverting controls. Disable PS3 Autocontrollers fixes this problem - reported by Virtualman
robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\emulators\rpcs3\ V:\RetroBat\emulators\rpcs3\ /S /NFL /NDL /IS /MT:4

rem 9. 2023-2-02 - Added missing bezelproject and decorations for any other future missing overlays - reported by Virtualman
robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\decorations\ V:\RetroBat\decorations\ /S /NFL /NDL /IS /MT:4

rem 10. 2023-2-03 - Copy es_padtokey.cfg (pre-post-upgrade) to support additional kill switches - reported by Virtualman
copy /y  "V:\_tools\mikcpu-retrobat-master\RetroBat\backup\mikcpu_orig\RetroBat\emulationstation\.emulationstation\es_padtokey.cfg" V:\RetroBat\emulationstation\.emulationstation\

rem 11. 2023-2-04 - New RBL Features ES Menu sync
robocopy V:\_tools\mikcpu-retrobat-master\RetroBat\system\es_menu\ V:\RetroBat\system\es_menu\ /S /NFL /NDL /IS /MT:4

rem 12. 2023-4-29 - rm old model1 collection as it's replaced with sega model 1.cfg for system sort reason
DEL /F /Q V:\RetroBat\emulationstation\.emulationstation\collections\custom-model1.cfg 2>nul

rem Apply XML-based updates using PowerShell
powershell -ExecutionPolicy Bypass -File V:\_tools\mikcpu-retrobat-master\xml_updates.ps1

echo.
echo Update Completed. Enjoy! :)
echo.
echo Press any key to continue . . .
pause >nul
 
