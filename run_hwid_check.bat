@echo off
@echo Please check https://github.com/tundra-labs/HWID_check to make sure that you have the latest version of this script
@echo This is version number 1.3 changed on Feb 8th 2022
@echo.
@echo This script can cause damage to SteamVR devices that are not Tundra Tracker
@echo.
set /P c=Are you sure that only one Tundra tracker is connected to your PC and no other devices are connected? (y)es, (n)o: 
@echo.
if /I "%c%" EQU "Y" goto :check_compatibility
if /I "%c%" EQU "y" goto :check_compatibility
if /I "%c%" EQU "N" goto :stop
if /I "%c%" EQU "n" goto :stop
goto :stop

:check_compatibility
@echo.
@echo Do not unplug the device at any point!
@echo.
@echo Verifying device data, please wait...

set version_dvc='lighthouse_console.exe exit'
set version_csl='lighthouse_console.exe version'
set version_cmd='lighthouse_watchman_update.exe -aw3'

set /a active_devices=0

set serial_number=unknown

set /a fw_version_current=0
set /a fw_version_required=1637337510
:: Firmware version from file in \SteamVR\drivers\

set hwid_current=0
set product_id_check=f0000109
set product_id_required=f1030009

set /a bl_version_current=0
set /a bl_version_check=1622649182
set /a bl_version_required=1629157907
:: Newer bootloader version of 1637337510 available?

for /F "Tokens=1,5 delims= " %%A in (%version_dvc%) do (
  if "%%A" EQU "Attached" (set /a active_devices=%%B)
)

@echo.
if %active_devices% EQU 0 (@echo Could not find any active devices!)
if %active_devices% EQU 0 goto :err
if %active_devices% LSS 3 (@echo Wrong device connected?)
if %active_devices% LSS 3 goto :err
if %active_devices% GTR 3 (@echo Too many devices connected?)
if %active_devices% GTR 3 goto :err
:: Tries to catch if no device, the wrong device or too many devices are plugged in.

for /F "Tokens=1,3 delims= " %%A in (%version_csl%) do (
  if "%%A" EQU "VRC" (set /a fw_version_current=%%B)
)
:: Check for firmware version.

lighthouse_watchman_update.exe -bw3 >nul 2>&1
timeout /t 8 /nobreak >nul
:: Timeout of 8 or greater, mitigates issues with slow USB initialization.

for /F "Tokens=1,3 delims= " %%A in (%version_cmd%) do (
  if "%%A" EQU "Hardware" (set hwid_current=%%B)
  if "%%A" EQU "Serial" (set serial_number=lhr-%%B)
  if "%%A" EQU "Bootloader" (set /a bl_version_current=%%B)
)
:: Check for HWID, serial and bootloader version.

@echo.
@echo -- Device status --

@echo.
@echo Device serial number is %serial_number%

@echo.
@echo Device HWID is 0x%hwid_current%
if %hwid_current% EQU 0 (@echo HWID could not be identified, quit for safety!)
if %hwid_current% EQU 0 goto :stop
if %hwid_current% NEQ %product_id_check% if %hwid_current% NEQ %product_id_required% (@echo HWID of 0x%hwid_current% is not associated with Tundra Tracker, quit for safety!)
if %hwid_current% NEQ %product_id_check% if %hwid_current% NEQ %product_id_required% goto :stop
if %hwid_current% EQU %product_id_required% (@echo This is the correct HWID for Tundra Tracker.)
if %hwid_current% EQU %product_id_required% goto :hwid_is_safe
if %hwid_current% EQU %product_id_check% (@echo This is an older HWID and should be updated.)
if %hwid_current% EQU %product_id_check% goto :bad_hwid
@echo.
@echo HWID of 0x%hwid_current% is not associated with Tundra Tracker, quit for safety!
:: This catches all other possibilities.
goto :stop

:hwid_is_safe
@echo.
@echo Device firmware version is v%fw_version_current%
if %fw_version_current% EQU 0 (@echo Firmware version could not be identified, quit for safety!)
if %fw_version_current% EQU 0 goto :stop
if %fw_version_current% EQU %fw_version_required% (@echo This is the correct firmware version for Tundra Tracker.) 
:: Change 'EQU' to 'GEQ' if a newer version is not a issue and remove line further below.
if %fw_version_current% LSS %fw_version_required% (@echo This is a older firmware version for Tundra Tracker.)
if %fw_version_current% LSS %fw_version_required% goto :bad_fw_version
if %fw_version_current% GTR %fw_version_required% (@echo This is a newer than expected firmware version for Tundra Tracker, quit for safety!) 
:: Remove ^ line if this is not a problem, added to catch unexpected behaviour.
if %fw_version_current% GTR %fw_version_required% goto :stop
:: Remove ^ line if this is not a problem, added to catch unexpected behaviour.

@echo.
@echo Device bootloader version is v%bl_version_current%
if %bl_version_current% EQU 0 (@echo Bootloader version could not be identified, quit for safety!)
if %bl_version_current% EQU 0 goto :stop
if %bl_version_current% EQU %bl_version_required% (@echo This is the correct bootloader version for Tundra Tracker.)
if %bl_version_current% EQU %bl_version_required% goto :stop
if %bl_version_current% EQU %bl_version_check% (@echo This is a older bootloader version for Tundra Tracker.) 
:: Change 'EQU' to 'LSS' to update all older bootloaders and remove line further below.
if %bl_version_current% EQU %bl_version_check% goto :bad_bl_version
:: Change 'EQU' to 'LSS' to update all older bootloaders and remove line further below.
if %bl_version_current% GTR %bl_version_required% (@echo This is a newer than expected bootloader version for Tundra Tracker, quit for safety!)
if %bl_version_current% GTR %bl_version_required% goto :stop
if %bl_version_current% LSS %bl_version_required% (@echo This is a unexpected bootloader version for Tundra Tracker, quit for safety!) 
:: Remove ^ line when updating all older bootloaders.
if %bl_version_current% LSS %bl_version_required% goto :stop
:: Remove ^ line when updating all older bootloaders.
goto :stop

:err_hw_check
@echo.
@echo You need to update the HWID to continue!
goto :stop

:err_fw_check
@echo.
@echo You need to update the firmware to continue!
goto :stop

:err_bl_check
@echo.
@echo Bootloader update was aborted!
goto :stop

:bad_hwid
@echo.
set /P c=HWID needs to be updated, would you like to update? (y)es, (n)o: 
@echo.
if /I "%c%" EQU "Y" goto :update_hwid
if /I "%c%" EQU "y" goto :update_hwid
if /I "%c%" EQU "N" goto :err_hw_check
if /I "%c%" EQU "n" goto :err_hw_check
goto :bad_hwid

:update_hwid
lighthouse_watchman_update.exe -Bw3 0xF1030009
timeout /t 8 /nobreak >nul
:: Timeout of 8 or greater, mitigates issues with slow USB initialization.
goto :check_compatibility

:bad_fw_version
@echo.
set /P c=Firmware version is outdated, would you like to update? (y)es, (n)o: 
@echo.
if /I "%c%" EQU "Y" goto :update_fw
if /I "%c%" EQU "y" goto :update_fw
if /I "%c%" EQU "N" goto :err_fw_check
if /I "%c%" EQU "n" goto :err_fw_check
goto :bad_fw_version

:update_fw
@echo.
@echo -- Updating firmware --
lighthouse_watchman_update.exe -Rw3 >nul 2>&1
timeout /t 8 /nobreak >nul
lighthouse_watchman_update.exe -s %serial_number% --target=application "tundra-tracker_application_1637337510.fw"
:: Local firmware version.
timeout /t 8 /nobreak >nul
:: Timeout of 8 or greater, mitigates issues with slow USB initialization.
goto :check_compatibility

:bad_bl_version
@echo.
set /P c=Bootloader version is outdated, would you like to update? (y)es, (n)o: 
@echo.
if /I "%c%" EQU "Y" goto :update_bl
if /I "%c%" EQU "y" goto :update_bl
if /I "%c%" EQU "N" goto :err_bl_check
if /I "%c%" EQU "n" goto :err_bl_check
goto :bad_bl_version

:update_bl
@echo -- Updating bootloader --
lighthouse_watchman_update.exe -Rw3 >nul 2>&1
timeout /t 8 /nobreak >nul
lighthouse_watchman_update.exe -s %serial_number% --hwid 0x%hwid_current% --target=bootloader watchman_v3_bootloader_umodule.fw
timeout /t 8 /nobreak >nul
:: Timeout of 8 or greater, mitigates issues with slow USB initialization.
goto :check_compatibility

:err
@echo.
@echo Please check connected devices!
set /P c=Press Enter to quit...
Exit /b

:stop
@echo.
@echo Resetting device, please wait...
:: To make sure the device is fully initialised before removal.
lighthouse_watchman_update.exe -Rw3 >nul 2>&1
timeout /t 8 /nobreak >nul
@echo.
@echo Device is now safe to unplug!
set /P c=Press Enter to quit...
Exit /b