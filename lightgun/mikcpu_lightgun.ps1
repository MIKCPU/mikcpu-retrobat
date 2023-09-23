# Data sources and variables
$version ='** VMAN RBL Lightgun-Bliss Experience v3.5.1.2 by Bilu **'
$OutputEncoding = [Console]::OutputEncoding
$templatecfg='V:\_tools\mikcpu-retrobat-master\lightgun\templates'
$overridefolder='V:\RetroBat\emulators\retroarch\config'
$roms='V:\RetroBat\roms'
$roms_orig='V:\_tools\mikcpu-retrobat-master\roms'
$corematrix='V:\RetroBat\backup\lightgun\lightgun_matrix.csv'
$corescfgfile='V:\_tools\mikcpu-retrobat-master\lightgun\lightgun_cores.txt'
$collectionfile='V:\RetroBat\emulationstation\.emulationstation\collections\custom-lightgun.cfg'
$arcadelist='V:\RetroBat\roms\arcade\gamelist.xml'
$es_settings_path='V:\RetroBat\emulationstation\.emulationstation\es_settings.cfg'
$settingsfile = 'V:\RetroBat\backup\lightgun\lightgun_settings.txt'

# Games that need specific remap configurations to emulate the Konami Justifier lightgun.
$justifier_games= @(
    './Area 51 (USA).chd'
    './Crime Patrol (USA).chd'
    './Crypt Killer (USA).chd'
    './Elemental Gearbolt (USA).chd'
    './Lethal Enforcers (Sega CD) (U).chd'
    './Lethal Enforcers (USA).7z'
    './Lethal Enforcers I & II (USA).chd'
    './Lethal Enforcers II - Gun Fighters (USA).7z'
    './Lethal_Enforcers_II-Gun_Fighters(US-Genesis).chd'
    './Mad Dog McCree (USA).chd'
    './Mad Dog McCree II - The Lost Gold (USA).chd'
    './Maximum Force (USA).chd'
    './Project - Horned Owl (USA).chd'
    './Who Shot Johnny Rock (USA).chd'
)

# Import variables from settings file.
if (-not (Test-Path -Path $settingsfile -PathType Leaf)){
	Copy-Item -Path $($PSScriptRoot + "\lightgun_settings_default.txt") -Destination (New-Item -Path (Split-Path -Path $settingsfile) -Type Directory -Force)
	Rename-Item -Path ($(Split-Path -Path $settingsfile) + "\lightgun_settings_default.txt") -NewName "lightgun_settings.txt" 
}
Invoke-Expression (Get-Content -Raw $settingsfile)

# Variable validation and fallback to defaults when necessary
if ($nr_lightguns -eq '2') {
		$script_mode='multigun'
	} else {
		$script_mode='singlegun'
	}
if ($sinden -ne 'y') {$sinden = 'n'}
if ($show_crosshair -ne 'n') {$show_crosshair = 'y'}
if (-not (Test-Path -Path $overlay -PathType Leaf)) {$sinden = 'n'}
if ([string]::IsNullOrEmpty($gun_select)) {$gun_select = 'escape'}
if ([string]::IsNullOrEmpty($gun_start)) {$gun_start = 'enter'}
if (-not ($player1_mouse_index -match '^\d+$')) {$player1_mouse_index = '0'}
if (-not ($player2_mouse_index -match '^\d+$')) {$player1_mouse_index = '1'}

Clear-Host

# Generate Decision Matrix CSV file. Provides information to set/remove emulator cores in gamelist.xml and Retroarch overrides.
function CreateMatrix {
	Write-Output 'Parsing data...'
	[xml]$gamelistsrc = Get-Content $arcadelist
	[xml]$es_settings = Get-Content $es_settings_path
	$corescfg = Import-Csv $corescfgfile -Delimiter '|'
	$collection = Import-Csv $collectionfile -Delimiter '/' -Header 1,2,system,path | ForEach-Object {$_.path = "./" + $_.path ; $_}

	$gamelist = $gamelistsrc.gameList.ChildNodes|ForEach{[pscustomobject]@{	
	  path = $_.path
	  emulator = $_.emulator
	  core = $_.core
	}}

	Write-Output 'Generating decision matrix...'
	$counter = 0
	$matrix = @()
	foreach ($item in $collection){
		Write-Progress -Activity "Generating decision matrix..." -Status "$($item.system)" -PercentComplete (($counter/$collection.Count)*100)
		if ($corescfg.system -eq $item.system){
			$default_core = ($es_settings.SelectSingleNode("//string[@name='$($item.system + '.core')']")).value
			$old_core0 = ($gamelist | Where-Object -FilterScript { $_.path -eq $item.path } | select -Last 1 core).core
			if ([string]::IsNullOrEmpty($old_core0)) {$old_core = $default_core} else {$old_core = $old_core0}
			if ($item.system -eq 'arcade'){
				if ([string]::IsNullOrWhiteSpace($old_core0)){
					$new_core = $default_core
					$rollback_core = $default_core
					$override = ($corescfg | Where-Object -FilterScript { $_.core -eq $default_core } | select override).override
					} else {
					$new_core = $old_core
					$rollback_core = $old_core
					$override = ($corescfg | Where-Object -FilterScript { $_.core -eq $old_core }  | select override).override	
					}
			} else {
				$new_core = ($corescfg | Where-Object -FilterScript { $_.system -eq $item.system }  | select core).core
				$override = ($corescfg | Where-Object -FilterScript { $_.system -eq $item.system }  | select override).override
				if ([string]::IsNullOrEmpty($old_core)) {$rollback_core = $default_core} else {$rollback_core = $old_core}
				if ([string]::IsNullOrEmpty($rollback_core)) {$rollback_core = $new_core}
			}
			if ($justifier_games -eq $item.path -and $item.system -ne 'saturn'){
				$justifier = 'justifier'
				} else {
				$justifier = ''
			}
			if ($rollback_core -eq $new_core) {$change_core = 'n'} else {$change_core = 'y'}
			$Temp = New-Object PSObject
			$Temp | Add-Member NoteProperty system $item.system
			$Temp | Add-Member NoteProperty path $item.path
			$Temp | Add-Member NoteProperty change_core $change_core
			$Temp | Add-Member NoteProperty rollback_core $rollback_core
			$Temp | Add-Member NoteProperty new_core $new_core
			$Temp | Add-Member NoteProperty override $override
			$Temp | Add-Member NoteProperty justifier $justifier
			$matrix += $Temp
		}
	$counter ++	
	}
	$matrix | Export-Csv $corematrix -Encoding Default -NoTypeInformation	
}

# Copies template Retroarch overrides and remaps to the corresponding folders / game names, including specific remaps for Konami Justifier when applicable.
function SetOverrides {
	$counter = 0
	Write-Output 'Setting Retroarch per-game config overrides and remaps...'
	foreach ($item in $matrix){
		Write-Progress -Activity "Setting Retroarch per-game config overrides and remaps..." -Status "$($item.system)" -PercentComplete (($counter/$matrix.Count)*100)
		
		$templatename=$(Split-Path -Path $item.path -Leaf) -replace "\.(\w+)$"
		$templatesrc_cfg=$($templatecfg + '\' + $script_mode + '\' + $item.override + '\' + $item.system + '.cfg')
		$templatedst0_cfg=$($overridefolder + '\' + $item.override + '\' + $item.system + '.cfg')		
		$templatesrc_opt=$($templatecfg + '\' + $script_mode + '\' + $item.override + '\' + $item.system + '.opt')
		$templatedst0_opt=$($overridefolder + '\' + $item.override + '\' + $item.system + '.opt')
		$templatedst1=$($overridefolder + '\' + $item.override + '\' + $templatename)
		
		$remapsrc=$($templatecfg + '\' + $script_mode + '\remaps\' + $item.override + '\' + $item.system + '.*')
		$remapsrc_j=$($templatecfg + '\' + $script_mode + '\remaps\' + $item.override + '\' + $item.system + '_justifier.*')
		$remapdst0=$($overridefolder + '\remaps\' + $item.override + '\' + $item.system + '.rmp')
		$remapdst0_j=$($overridefolder + '\remaps\' + $item.override + '\' + $item.system + '_justifier.rmp')		
		$remapdst1=$($overridefolder + '\remaps\' + $item.override + '\' + $templatename)
		$remapdst1_j=$($overridefolder + '\remaps\' + $item.override + '\' + $templatename + '_justifier')	

		if (Test-Path $templatedst0_cfg) {Remove-Item -Path $templatedst0_cfg} 
		if (Test-Path $templatedst0_opt) {Remove-Item -Path $templatedst0_opt} 
		if (Test-Path $remapdst0) {Remove-Item -Path $remapdst0}
		if (Test-Path $remapdst0_j) {Remove-Item -Path $remapdst0_j}
		Remove-Item -ErrorAction SilentlyContinue -LiteralPath $($templatedst1+'.cfg') 
		Remove-Item -ErrorAction SilentlyContinue -LiteralPath $($templatedst1+'.opt')
		Remove-Item -ErrorAction SilentlyContinue -LiteralPath $($remapdst1+'.rmp')
		Remove-Item -ErrorAction SilentlyContinue -LiteralPath $($remapdst1_j+'rmp')
		Copy-Item -ErrorAction SilentlyContinue  "$templatesrc_cfg" -Destination (New-Item -Path (Split-Path -Path "$templatedst0_cfg") -Type Directory -Force)
		Copy-Item -ErrorAction SilentlyContinue  "$templatesrc_opt" -Destination (New-Item -Path (Split-Path -Path "$templatedst0_opt") -Type Directory -Force)

		if ('puae','mame','mame2016','mame2003_plus' -contains $item.new_core) {
			Add-Content -Path "$templatedst0_cfg" -Value `n$('input_driver = "raw"')
		} else {
			Add-Content -Path "$templatedst0_cfg" -Value `n$('input_driver = "'+ $lightgun_driver + '"')
		}

		if ($sinden -eq 'y') {
			Add-Content -Path "$templatedst0_cfg" -Value 'input_overlay_enable = "true"'		
			Add-Content -Path "$templatedst0_cfg" -Value $('input_overlay = "'+ $overlay + '"')
		}	

		Add-Content -Path "$templatedst0_cfg" -Value $('input_player1_gun_select = "'+ $gun_select + '"')		
		Add-Content -Path "$templatedst0_cfg" -Value $('input_player1_select = "'+ $gun_select + '"')
		Add-Content -Path "$templatedst0_cfg" -Value $('input_player1_gun_start = "'+ $gun_start + '"')		
		Add-Content -Path "$templatedst0_cfg" -Value $('input_player1_start = "'+ $gun_start + '"')

		if ($nr_lightguns -eq '2') {
			Add-Content -Path "$templatedst0_cfg" -Value $('input_player2_gun_select = "'+ $gun_select + '"')		
			Add-Content -Path "$templatedst0_cfg" -Value $('input_player2_select = "'+ $gun_select + '"')
			Add-Content -Path "$templatedst0_cfg" -Value $('input_player2_gun_start = "'+ $gun_start + '"')		
			Add-Content -Path "$templatedst0_cfg" -Value $('input_player2_start = "'+ $gun_start + '"')
		}

		if ('megadrive','genesis' -contains $item.system) {
			Add-Content -Path "$templatedst0_cfg" -Value $('input_player1_mouse_index = "'+ $player2_mouse_index + '"')		
			Add-Content -Path "$templatedst0_cfg" -Value $('input_player2_mouse_index = "'+ $player1_mouse_index + '"')
		} else {	
		Add-Content -Path "$templatedst0_cfg" -Value $('input_player1_mouse_index = "'+ $player1_mouse_index + '"')		
		Add-Content -Path "$templatedst0_cfg" -Value $('input_player2_mouse_index = "'+ $player2_mouse_index + '"')
		}

		Get-ChildItem -ErrorAction SilentlyContinue "$templatedst0_cfg" | Rename-Item -NewName { $_.Name -replace $item.system,"$templatename" }
				
		if ($show_crosshair -eq 'y'){
			if ($item.new_core -eq 'genesis_plus_gx'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('genesis_plus_gx_gun_cursor = "enabled"')
				}
			if ($item.new_core -eq 'flycast'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('reicast_lightgun1_crosshair = "Red"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('reicast_lightgun2_crosshair = "Blue"')
				}			
			if ($item.new_core -eq 'mednafen_psx_hw'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('beetle_psx_hw_gun_cursor = "cross"')
				}
			if ($item.new_core -eq 'mednafen_saturn'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('beetle_saturn_virtuagun_crosshair = "Cross"')
				}
			if ($item.new_core -eq 'snes9x'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('snes9x_justifier1_crosshair = "2"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('snes9x_justifier2_crosshair = "2"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('snes9x_rifle_crosshair = "2"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('snes9x_superscope_crosshair = "2"')
				}			
			if ($item.new_core -eq 'mame2003_plus'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('mame2003-plus_crosshair_enabled = "enabled"')				
				}		
			if ($item.new_core -eq 'fceumm'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('fceumm_show_crosshair = "enabled"')
				}				
			if ($item.new_core -eq 'fbneo'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('fbneo-lightgun-hide-crosshair = "disabled"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('fbneo-lightgun-crosshair-emulation = "always show"')
				}
		} else {
			if ($item.new_core -eq 'genesis_plus_gx'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('genesis_plus_gx_gun_cursor = "disabled"')
				}
			if ($item.new_core -eq 'flycast'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('reicast_lightgun1_crosshair = "disabled"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('reicast_lightgun2_crosshair = "disabled"')
				}			
			if ($item.new_core -eq 'mednafen_psx_hw'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('beetle_psx_hw_gun_cursor = "off"')
				}
			if ($item.new_core -eq 'mednafen_saturn'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('beetle_saturn_virtuagun_crosshair = "Off"')
				}
			if ($item.new_core -eq 'snes9x'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('snes9x_justifier1_crosshair = "0"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('snes9x_justifier2_crosshair = "0"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('snes9x_rifle_crosshair = "0"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('snes9x_superscope_crosshair = "0"')
				}			
			if ($item.new_core -eq 'mame2003_plus'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('mame2003-plus_crosshair_enabled = "disabled"')
				}		
			if ($item.new_core -eq 'fceumm'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('fceumm_show_crosshair = "disabled"')
				}				
			if ($item.new_core -eq 'fbneo'){
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('fbneo-lightgun-hide-crosshair = "enabled"')
				Add-Content -LiteralPath "$templatedst0_opt" -Value $('fbneo-lightgun-crosshair-emulation = "always hide"')
				}
		}

		Get-ChildItem -ErrorAction SilentlyContinue "$templatedst0_opt" | Rename-Item -NewName { $_.Name -replace $item.system,"$templatename" }

		if ($item.justifier -eq 'justifier') {
			Copy-Item -ErrorAction SilentlyContinue -Path "$remapsrc_j" -Destination (New-Item -Path (Split-Path -Path "$remapdst0_j") -Type Directory -Force)
			Get-ChildItem -ErrorAction SilentlyContinue "$remapdst0_j" | Rename-Item -NewName { $_.Name -replace $($item.system + '_justifier'),"$templatename" }
		} else {
			Copy-Item -ErrorAction SilentlyContinue -Path "$remapsrc" -Destination (New-Item -Path (Split-Path -Path "$remapdst0") -Type Directory -Force)
			Get-ChildItem -ErrorAction SilentlyContinue "$remapdst0" | Rename-Item -NewName { $_.Name -replace $item.system,"$templatename" }
		}
		
	$counter ++
	}
}

# Removes template Retroarch overrides and remaps from the corresponding folders / game names.
# -LiteralPath helps avoid weird filenames being interpreted as PowerShell syntax.
function UnsetOverrides {
	Write-Output 'Cleanup overrides and remaps...'	
	foreach ($item in $matrix){
		$templatename=$(Split-Path -Path $item.path -Leaf) -replace "\.(\w+)$"
		$templatedst1=$($overridefolder + '\' + $item.override + '\' + $templatename)
		$remapdst1=$($overridefolder + '\remaps\' + $item.override + '\' + $templatename)
		$remapdst1_j=$($overridefolder + '\remaps\' + $item.override + '\' + $templatename + '_justifier')	
		Remove-Item -ErrorAction SilentlyContinue -LiteralPath $($templatedst1+'.cfg') 
		Remove-Item -ErrorAction SilentlyContinue -LiteralPath $($templatedst1+'.opt')
		Remove-Item -ErrorAction SilentlyContinue -LiteralPath $($remapdst1+'.rmp')
		Remove-Item -ErrorAction SilentlyContinue -LiteralPath $($remapdst1_j+'rmp')
	}
}

# Sets the appropriate Retroarch cores for lightgun support.
function SetCores {
	$counter = 0
	Write-Output 'Setting Retroarch per-game cores...'	
	foreach ($item in $matrix ){
		Write-Progress -Activity "Setting Retroarch per-game cores..." -Status "$($item.system)" -PercentComplete (($counter/$matrix.Count)*100)
		if ($item.change_core -eq 'y'){
			$gamepath="$($item.path)"
			$gamelistsrc=$($roms + "\" + $item.system + "\gamelist.xml")
			[xml]$gamelist = Get-Content $gamelistsrc -Encoding UTF8
			$game = $($gamelist.SelectNodes("//game[path=""$($gamepath)""]")) | select -Last 1
			$emulatorNode=$gamelist.CreateElement('emulator')
			$coreNode=$gamelist.CreateElement('core')

			if ($game.emulator){
				$game.emulator = "libretro"
			} else {
				$emulator = $game.AppendChild($emulatorNode)
				$game.emulator = "libretro"
			}

			if ($game.core){
				$game.core = "$($item.new_core)"
			} else {
				$core = $game.AppendChild($coreNode)
				$game.core = "$($item.new_core)"
			}
					
			$gamelist.save($gamelistsrc)

		}
	$counter ++
	}
}

# Removes per-game Retroarch cores, will use default core.
function UnsetCores {
	$counter = 0
	Write-Output 'Restoring factory gamelists to undo per-game cores...'	
	foreach ($item in $matrix ){
		Write-Progress -Activity "Restoring factory gamelists to undo per-game cores..." -Status "$($item.system)" -PercentComplete (($counter/$matrix.Count)*100)
		if ($item.change_core -eq 'y'){
			Copy-Item -Path $($roms_orig + "\" + $item.system + "\gamelist.xml") -Destination $($roms + "\" + $item.system) -Force
		}
	$counter ++
	}
}

function Install {
    Write-Host -ForegroundColor Blue -BackgroundColor DarkMagenta $version
	Write-Host -NoNewLine `n"Current mode: "
	Write-Host -ForegroundColor Green $script_mode.ToUpper()
	TASKKILL /F /IM retrobat.exe /IM emulationstation.exe /IM retroarch.exe 2> $null
	CreateMatrix
	$matrix = Import-Csv $corematrix 
	SetOverrides
	SetCores
	Write-Host -NoNewLine "Setup complete in "
	Write-Host -NoNewLine -ForegroundColor Green $script_mode.ToUpper()
	Write-Host " mode."
	Write-Output ""
	cmd /c pause
}

function Uninstall {
    Write-Host -ForegroundColor Blue -BackgroundColor DarkMagenta $version 
	Write-Output ""
	TASKKILL /F /IM retrobat.exe /IM emulationstation.exe /IM retroarch.exe 2> $null
	$matrix = Import-Csv $corematrix 
	UnsetOverrides
	UnsetCores
	Write-Output ""
	Write-Output ""
	Write-Output ""
	Write-Output ""
	cmd /c pause
}

function RetroarchIndex {
	$retroarchcfg='V:\RetroBat\emulators\retroarch\retroarch.cfg'
	((Get-Content -Path $retroarchcfg) -replace 'input_driver = "dinput"','input_driver = "raw"') | Set-Content -Path $retroarchcfg
	cmd /c echo. | V:\RetroBat\emulators\retroarch\retroarch.exe --verbose -L "V:\RetroBat\emulators\retroarch\cores\mame_libretro.dll" "fake.cfg" 2>&1 |findstr "WinRaw"
	((Get-Content -Path $retroarchcfg) -replace 'input_driver = "raw"','input_driver = "dinput"') | Set-Content -Path $retroarchcfg
	Write-Output ""
	cmd /c pause
}

function LightgunSetup {
	Clear-Host
    Write-Host -ForegroundColor Blue -BackgroundColor DarkMagenta $version
	Write-Output ""
	Write-Host -ForegroundColor Red "NOTE1: Emulationstation will be killed, please start again when finished."
	Write-Host "- Enhanced lightgun support for Retroarch cores.
	
Settings file provides further context on the options below."
Write-Host -ForegroundColor Green $settingsfile
Write-Host -NoNewLine `n"Number of lightgun devices : "
Write-Host -ForegroundColor Green $nr_lightguns
Write-Host -NoNewLine "Lightgun input driver (DInput/RawInput) : "
Write-Host -ForegroundColor Green $lightgun_driver
Write-Host -NoNewLine "Show crosshair : "
Write-Host -ForegroundColor Green $show_crosshair
Write-Host -NoNewLine `n"Apply custom overlay (Sinden) : "
Write-Host -ForegroundColor Green $sinden
Write-Host "Custom overlay path:"
Write-Host -ForegroundColor Green $overlay
Write-Host -NoNewLine `n"Keys mapped as Select : "
Write-Host -NoNewLine -ForegroundColor Green $gun_select
Write-Host -NoNewLine " / Start : "
Write-Host -NoNewLine -ForegroundColor Green $gun_start
Write-Host -NoNewLine `n"Hardware input index P1 : "
Write-Host -NoNewLine -ForegroundColor Green $player1_mouse_index
Write-Host -NoNewLine " / P2 : "
Write-Host -ForegroundColor Green $player2_mouse_index
Write-Host `n"If you're happy with these options choose [I]nstall, or [Q]uit to edit settings.

You can also [C]leanup your previous lightgun setup, not needed to apply new settings."
Write-Host -ForegroundColor Red "NOTE2: Be aware [C]leanup will restore MIKCPU original playlists where cores are changed!"
Write-Host -ForegroundColor Red "Usually this impacts NES, PSX and Saturn gamelists."

Write-Host ""
					
	$option = "&Cleanup","&Install","&Hardware Index","&Quit"
	$helptext = "Cleanup your previous lightgun setup","Install with current settings","Details on Retroarch mouse input index","Exit lightgun setup"
	$default = 1
 
	## Create the list of choices
	$choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
	
	## Go through each of the options, and add them to the choice collection
	for ($counter = 0; $counter -lt $option.Length; $counter++)
	{
		$choice = New-Object Management.Automation.Host.ChoiceDescription $option[$counter]
	
		if ($helpText -and $helpText[$counter])
		{
			$choice.HelpMessage = $helpText[$counter]
		}
	
		$choices.Add($choice)
	}
	
	## Prompt for the choice, returning the item the user selected
	$result = $host.UI.PromptForChoice($null, $null, $choices, $default)	
	if ($result -eq 0) {
		if (Test-Path -Path $corematrix -PathType Leaf){
		Clear-Host
		Uninstall
		} else {
		Write-Host -ForegroundColor Red "Decision matrix file not created or available, please verify or cleanup manually."
		cmd /c pause
		}
	}
	elseif ($result -eq 1) {
		Clear-Host
		Install
	}
	elseif ($result -eq 2) {
		Clear-Host
		RetroarchIndex
		LightgunSetup
	}	
}

LightgunSetup