@echo off

set vnum=1.4
set vdate=Feb 14th 2022

@echo Please check https://github.com/tundra-labs/HWID_check to make sure that you have the latest version of this script!
@echo This is version number %vnum% changed on %vdate%.
@echo.
@echo This script can cause damage to SteamVR devices that are not Tundra Tracker!
@echo.
@echo A new log file is created after each device verification, these can be found in the same folder as this script.
@echo.
set /P c=Are you sure that only one Tundra tracker is connected to your PC and no other devices are connected? (y)es, (n)o: 
@echo.

:get_time
for /F "Tokens=1 skip=1 delims=." %%A in ('wmic os get localdatetime') do (
  if not defined dt set dt=%%A
)
set datetime=%dt:~0,4%%dt:~4,2%%dt:~6,2%%dt:~8,2%%dt:~10,2%%dt:~12,2%
set /a cycles=0
set logname=hwid_check_%datetime%_c1.log
echo. >>%logname%

if /I "%c%" EQU "Y" goto :check_compatibility
if /I "%c%" EQU "y" goto :check_compatibility
if /I "%c%" EQU "N" goto :stop
if /I "%c%" EQU "n" goto :stop
goto :stop

:check_compatibility
set /a cycles=cycles+1
set /a nextcycle=cycles+1
echo Created logfile on the %dt:~0,4%-%dt:~4,2%-%dt:~6,2% (MM-DD) at %dt:~8,2%:%dt:~10,2%:%dt:~12,2% for HWID check with version number %vnum% from %vdate%. >%logname%
echo. Current device verification cycle is %cycles%. >>%logname%

@echo.
@echo Do not unplug the device at any point!
@echo.
@echo Verifying device data, please wait... & echo Verified data: >>%logname%

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
echo Active devices check resulted in: %active_devices% - expecting 3. >>%logname%

@echo.
if %active_devices% EQU 0 (@echo Could not find any active devices! & echo ERROR: Could not find any active devices! >>%logname%)
if %active_devices% EQU 0 goto :err
if %active_devices% LSS 3 (@echo Wrong device connected? & echo ERROR: Wrong device connected? >>%logname%)
if %active_devices% LSS 3 goto :err
if %active_devices% GTR 3 (@echo Too many devices connected? & echo ERROR: Too many devices connected? >>%logname%)
if %active_devices% GTR 3 goto :err
:: Tries to catch if no device, the wrong device or too many devices are plugged in.

timeout /t 1 /nobreak >nul
for /F "Tokens=1,3 delims= " %%A in (%version_csl%) do (
  if "%%A" EQU "VRC" (set /a fw_version_current=%%B)
)
echo Device firmware version is %fw_version_current%, expecting %fw_version_required% - needed. >>%logname%
:: Check for firmware version.

timeout /t 1 /nobreak >nul
echo. >>%logname%
echo Setting into bootloader mode. >>%logname%
echo. Executing -bw3 >>%logname%
lighthouse_watchman_update.exe -bw3 >>%logname% 2>&1
echo. >>%logname%
timeout /t 8 /nobreak >nul
:: Timeout of 8 or greater, mitigates issues with slow USB initialization.

for /F "Tokens=1,3 delims= " %%A in (%version_cmd%) do (
  if "%%A" EQU "Hardware" (set hwid_current=%%B)
  if "%%A" EQU "Bootloader" (set /a bl_version_current=%%B)
  if "%%A" EQU "Serial" (set serial_number=lhr-%%B)
)
echo Device HWID is %hwid_current%, expecting %product_id_required% - new or %product_id_check% - old. >>%logname%
echo Device bootloader version is %bl_version_current%, expecting %bl_version_required% - new or %bl_version_check% - old. >>%logname%
echo. >>%logname%
echo. Device serial number is %serial_number%. >>%logname%
:: Check for HWID, serial and bootloader version.

echo. >>%logname%
@echo.
@echo -- Device status --

@echo.
@echo Device serial number is %serial_number%.

@echo.
@echo Device HWID is 0x%hwid_current%.
if %hwid_current% EQU 0 (@echo HWID could not be identified, quit for safety! & echo ERROR: HWID could not be identified, quit! >>%logname%)
if %hwid_current% EQU 0 goto :stop
if %hwid_current% NEQ %product_id_check% if %hwid_current% NEQ %product_id_required% (@echo HWID of 0x%hwid_current% is not associated with Tundra Tracker, quit for safety! & echo WARNING: HWID of 0x%hwid_current% not associated with Tundra Tracker, quit! >>%logname%)
if %hwid_current% NEQ %product_id_check% if %hwid_current% NEQ %product_id_required% goto :stop
if %hwid_current% EQU %product_id_required% (@echo This is the correct HWID for Tundra Tracker. & echo Correct HWID for Tundra Tracker. >>%logname%)
if %hwid_current% EQU %product_id_required% goto :hwid_is_safe
if %hwid_current% EQU %product_id_check% (@echo This is an older HWID and should be updated. & echo Older HWID and should be updated. >>%logname%)
if %hwid_current% EQU %product_id_check% goto :bad_hwid
@echo.
@echo HWID of 0x%hwid_current% is not associated with Tundra Tracker, quit for safety! & echo HWID of 0x%hwid_current% not associated with Tundra Tracker, quit! >>%logname%
:: This catches all other possibilities.
goto :stop

:hwid_is_safe
@echo.
@echo Device firmware version is v%fw_version_current%.
if %fw_version_current% EQU 0 (@echo Firmware version could not be identified, quit for safety! & echo ERROR: Firmware version could not be identified, quit! >>%logname%)
if %fw_version_current% EQU 0 goto :stop
if %fw_version_current% EQU %fw_version_required% (@echo This is the correct firmware version for Tundra Tracker. & echo Correct firmware version for Tundra Tracker. >>%logname%) 
:: Change 'EQU' to 'GEQ' if a newer version is not a issue and remove line further below.
if %fw_version_current% LSS %fw_version_required% (@echo This is a older firmware version for Tundra Tracker. & echo Older firmware version for Tundra Tracker. >>%logname%)
if %fw_version_current% LSS %fw_version_required% goto :bad_fw_version
if %fw_version_current% GTR %fw_version_required% (@echo This is a newer than expected firmware version for Tundra Tracker, quit for safety! & echo WARNING: Newer than expected firmware version for Tundra Tracker, quit! >>%logname%) 
:: Remove ^ line if this is not a problem, added to catch unexpected behaviour.
if %fw_version_current% GTR %fw_version_required% goto :stop
:: Remove ^ line if this is not a problem, added to catch unexpected behaviour.

@echo.
@echo Device bootloader version is v%bl_version_current%.
if %bl_version_current% EQU 0 (@echo Bootloader version could not be identified, quit for safety! & echo ERROR: Bootloader version could not be identified, quit! >>%logname%)
if %bl_version_current% EQU 0 goto :stop
if %bl_version_current% EQU %bl_version_required% (@echo This is the correct bootloader version for Tundra Tracker. & echo Correct bootloader version for Tundra Tracker. >>%logname%)
if %bl_version_current% EQU %bl_version_required% goto :stop
if %bl_version_current% EQU %bl_version_check% (@echo This is a older bootloader version for Tundra Tracker. & echo Older bootloader version for Tundra Tracker. >>%logname%) 
:: Change 'EQU' to 'LSS' to update all older bootloaders and remove line further below.
if %bl_version_current% EQU %bl_version_check% goto :bad_bl_version
:: Change 'EQU' to 'LSS' to update all older bootloaders and remove line further below.
if %bl_version_current% GTR %bl_version_required% (@echo This is a newer than expected bootloader version for Tundra Tracker, quit for safety! & echo WARNING: Newer than expected bootloader version for Tundra Tracker, quit! >>%logname%)
if %bl_version_current% GTR %bl_version_required% goto :stop
if %bl_version_current% LSS %bl_version_required% (@echo This is a unexpected bootloader version for Tundra Tracker, quit for safety! & echo WARNING: Unexpected bootloader version for Tundra Tracker, quit! >>%logname%) 
:: Remove ^ line when updating all older bootloaders.
if %bl_version_current% LSS %bl_version_required% goto :stop
:: Remove ^ line when updating all older bootloaders.
goto :stop

:err_hw_check
@echo.
@echo You need to update the HWID to continue! & echo User declined HWID update! >>%logname%
goto :stop

:err_fw_check
@echo.
@echo You need to update the firmware to continue! & echo User declined firmware update! >>%logname%
goto :stop

:err_bl_check
@echo.
@echo Bootloader update was aborted! & echo User declined bootloader update! >>%logname%
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
@echo.
echo. >>%logname%
@echo -- Updating HWID -- & echo -- Updating HWID -- >>%logname%
echo. Executing -Bw3 >>%logname%
lighthouse_watchman_update.exe -Bw3 0xF1030009 >>%logname% 2>&1
@echo. ... Saved info to log file ...
echo. >>%logname%
timeout /t 8 /nobreak >nul
@echo -- Updating HWID done -- & echo -- Updating HWID done -- >>%logname%
:: Timeout of 8 or greater, mitigates issues with slow USB initialization.
echo. Next device verification cycle log is hwid_check_%datetime%_c%nextcycle%.log. >>%logname%
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
echo. >>%logname%
@echo -- Updating firmware -- & echo -- Updating firmware -- >>%logname%
echo. Executing -Rw3 >>%logname%
lighthouse_watchman_update.exe -Rw3 >>%logname% 2>&1
echo. >>%logname%
timeout /t 8 /nobreak >nul
echo. >>%logname%
echo. Executing firmware update >>%logname%
lighthouse_watchman_update.exe -s %serial_number% --target=application "tundra-tracker_application_1637337510.fw" >>%logname% 2>&1
:: Local firmware version.
@echo. ... Saved info to log file ...
echo. >>%logname%
timeout /t 8 /nobreak >nul
@echo -- Updating firmware done -- & echo -- Updating firmware done -- >>%logname%
:: Timeout of 8 or greater, mitigates issues with slow USB initialization.
echo. Next device verification cycle log is hwid_check_%datetime%_c%nextcycle%.log. >>%logname%
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
@echo.
echo. >>%logname%
@echo -- Updating bootloader -- & echo -- Updating bootloader -- >>%logname%
echo. Executing -Rw3 >>%logname%
lighthouse_watchman_update.exe -Rw3 >>%logname% 2>&1
echo. >>%logname%
timeout /t 8 /nobreak >nul
echo. >>%logname%
echo. Executing bootloader update >>%logname%
lighthouse_watchman_update.exe -s %serial_number% --hwid 0x%hwid_current% --target=bootloader watchman_v3_bootloader_umodule.fw >>%logname% 2>&1
@echo. ... Saved info to log file ...
echo. >>%logname%
timeout /t 8 /nobreak >nul
@echo -- Updating bootloader done -- & echo -- Updating bootloader done-- >>%logname%
:: Timeout of 8 or greater, mitigates issues with slow USB initialization.
echo. Next device verification cycle log is hwid_check_%datetime%_c%nextcycle%.log. >>%logname%
goto :check_compatibility

:err
@echo.
echo. >>%logname%
@echo Please check connected devices! & echo ERROR: Device check failed! >>%logname%
set /P c=Press Enter to quit...
Exit /b

:stop
@echo.
echo. >>%logname%
@echo Resetting device, please wait... & echo Device reset. >>%logname%
:: To make sure the device is fully initialised before removal.
echo. Executing -Rw3 >>%logname%
lighthouse_watchman_update.exe -Rw3 >>%logname% 2>&1
timeout /t 8 /nobreak >nul
echo. >>%logname%
@echo.
@echo Device is now safe to unplug! & echo Device safe to unplug. >>%logname%
set /P c=Press Enter to quit...
echo. >>%logname%
echo. Logging finished. >>%logname%
echo. Total amount of log files for this device is %cycles%. >>%logname%
Exit /b