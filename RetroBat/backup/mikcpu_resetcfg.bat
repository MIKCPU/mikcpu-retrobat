@echo off
echo Restoring configs...
rem #######################################
echo Mikcpu Backup/Restore Config v5.x by Mikcpu
rem #######################################
echo Tool to retain VMan customizations through a RetroBat upgrade.
pause

set BASE=V:\RetroBat
set EMULATIONSTATION=%BASE%\emulationstation\.emulationstation
set DRIVE=V:

rem Prevent RetroBat update notifications to discourage emulator updates.
rem We had issues with newer versions of Teknoparrot, Citra, lr-mame and lr-fbneo.
rem Users can still update emulators at their own risk. 
attrib -r %TEMP%\emulationstation.tmp\versions.xml > NUL 2>&1
xcopy /Q /Y /-I %BASE%\backup\emu_versions\versions.xml %TEMP%\emulationstation.tmp\versions.xml > NUL 2>&1
attrib +r %TEMP%\emulationstation.tmp\versions.xml > NUL 2>&1
del /Q /F "%BASE%\system\es_menu\*.menu" > NUL 2>&1

for %%I in (^ 
 %BASE%\retrobat.ini^
 %BASE%\emulationstation\version.info^
 %BASE%\system\padtokey\*.keys^
 %EMULATIONSTATION%\es_padtokey.cfg^
 %EMULATIONSTATION%\es_systems.cfg^
 %EMULATIONSTATION%\es_settings.cfg^
 %BASE%\emulators\retroarch\cores\mame_libretro.dll^
 %BASE%\emulators\retroarch\cores\fbneo_libretro.dll^
 %BASE%\system\es_menu\*.menu^
 %BASE%\system\es_menu\gamelist.xml^
 %BASE%\system\es_menu\media\mikcpu*.png^
 %BASE%\RetroBat\roms\ports\gamelist.xml^
 %BASE%\emulators\cemu\settings.xml^
 %BASE%\emulators\citra\user\config\qt-config.ini^
 %BASE%\emulators\dolphin-emu\User\Config\Dolphin.ini^
 %BASE%\emulators\dolphin-emu\User\Config\GCPadNew.ini^
 %BASE%\emulators\dolphin-emu\User\Config\Hotkeys.ini^
 %BASE%\emulators\duckstation\settings.ini^
 %BASE%\emulators\pcsx2-16\inis\Dev9null.ini^
 %BASE%\emulators\pcsx2-16\inis\FWnull.ini^
 %BASE%\emulators\pcsx2-16\inis\GSdx.ini^
 %BASE%\emulators\pcsx2-16\inis\LilyPad.ini^
 %BASE%\emulators\pcsx2-16\inis\PCSX2_ui.ini^
 %BASE%\emulators\pcsx2-16\inis\PCSX2_vm.ini^
 %BASE%\emulators\pcsx2-16\inis\SPU2-X.ini^
 %BASE%\emulators\project64\Config\Project64.cfg^
 %BASE%\emulators\redream\redream.cfg^
 %BASE%\emulators\retroarch\retroarch-core-options.cfg^
 %BASE%\emulators\retroarch\retroarch.cfg^
 %BASE%\emulators\rpcs3\config.yml^
 %BASE%\emulators\rpcs3\config\vfs.yml^
 %BASE%\emulators\scummvm\scummvm.ini^
 %BASE%\emulators\snes9x\snes9x.conf^
 %BASE%\emulators\supermodel\Config\Supermodel.ini^
 %BASE%\emulators\vita3k\config.yml^
 %BASE%\emulators\vita3k\ux0\user\00\user.xml^
 %BASE%\emulators\winuae\winuae.ini^
 %BASE%\emulators\xemu\xemu.toml^
 %BASE%\emulators\bigpemu\userdata\BigPEmuConfig.bigpcfg^
 ) do xcopy /Q /Y /-I %%I %BASE%\backup\rb%%~pI > NUL 2>&1

for %%I in (^ 
 %BASE%\emulationstation\version.info^
 ) do xcopy /Q /Y %%I %BASE%\backup\mikcpu%%~pI > NUL 2>&1
del /Q /F %EMULATIONSTATION%\video\retrobat-*.mp4 > NUL 2>&1
rmdir /s /q %EMULATIONSTATION%\themes\es-theme-carbon > NUL 2>&1
del /Q /F %BASE%\roms\ports\*.libretro > NUL 2>&1
del /Q /F "%EMULATIONSTATION%\music\2080*.ogg" > NUL 2>&1
del /Q /F "%EMULATIONSTATION%\music\Le Brick*.ogg" > NUL 2>&1
del /Q /F "%EMULATIONSTATION%\music\Sawsquarenoise*.ogg" > NUL 2>&1
del /Q /F "%EMULATIONSTATION%\music\Starbox*.ogg" > NUL 2>&1

robocopy /NFL /NDL /NJH /NJS /nc /ns /np /S %BASE%\backup\mikcpu_orig %DRIVE%\

xcopy /Q /Y /-I %BASE%\backup\mikcpu_backupcfg.bat %BASE%\emulationstation\.emulationstation\scripts\quit\mikcpu_backupcfg.bat > NUL 2>&1



