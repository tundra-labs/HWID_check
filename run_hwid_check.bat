@echo off

@echo This script can cause damage to SteamVR devices that are not Tundra Tracker
set /P c=Are you sure that only one Tundra tracker is connected to your PC and no other devices are connected? (y)es, (n)o: 
@echo.
if /I "%c%" EQU "Y" goto :check_compatibility
if /I "%c%" EQU "y" goto :check_compatibility
if /I "%c%" EQU "N" goto :stop
if /I "%c%" EQU "n" goto :stop
goto :stop

:check_compatibility
@echo Verifying compatibility, please wait...
@echo.
lighthouse_watchman_update.exe -bw3 >nul 2>&1
timeout /t 5 /nobreak > nul

set version_cmd='lighthouse_watchman_update.exe -aw3'


set serial_number=unknown

set hwid_current=0
set product_id_check=f0000109
set product_id_required=f1030009

set /a bl_version_current=0
set /a bl_version_check=1622649182
set /a bl_version_required=1629157907  

for /F "Tokens=1,3 delims= " %%A in (%version_cmd%) do (
  
  if "%%A"=="Hardware" (set hwid_current=%%B)
  if "%%A"=="Serial" (set serial_number=lhr-%%B)
  if "%%A"=="Bootloader" (set /a bl_version_current=%%B)
)

@echo Device Serial number is %serial_number%
@echo Device Bootloader Version is %bl_version_current%
if %bl_version_current% EQU %bl_version_required% (@echo This is the correct bootloader version for Tundra Tracker)
@echo Device HWID is %hwid_current%
if "%hwid_current%" == "%product_id_required%" (@echo This is the correct HWID for Tundra Tracker)
if "%hwid_current%" == "%product_id_check%" (@echo This is an older HWID and should be updated)

if "%hwid_current%" == "%product_id_required%" ( goto :hwid_is_safe )
if "%hwid_current%" == "%product_id_check%" ( goto :hwid_is_safe )
@echo HWID of 0x%hwid_current% is not associated with Tundra Tracker, quit for safety
goto :stop
:hwid_is_safe

if %bl_version_current% LSS %bl_version_check% goto :bad_bl_version
:post_bl_check

if "%hwid_current%" == "%product_id_required%" ( goto :post_hwid )
if "%hwid_current%" == "%product_id_check%" ( goto :bad_hwid )
@echo HWID of 0x%hwid_current% is not associated with Tundra Tracker, quit for safety
goto :stop
:post_hwid

@echo.
@echo Compatibility checks passed.
goto :stop

:bad_hwid
set /P c=HWID needs to be updated, would you like to update? (y)es, (n)o: 
if /I "%c%" EQU "Y" goto :update_hwid
if /I "%c%" EQU "y" goto :update_hwid
if /I "%c%" EQU "N" goto :stop
if /I "%c%" EQU "n" goto :stop
goto :bad_hwid
:update_hwid
lighthouse_watchman_update.exe -Bw3 0xF1030009
timeout /t 5 /nobreak > nul
lighthouse_watchman_update.exe -bw3 >nul 2>&1
timeout /t 5 /nobreak > nul
goto :check_compatibility

:bad_bl_version:
set /P c=Bootloader version is outdated, would you like to update? (y)es, (n)o: 
@echo.
if /I "%c%" EQU "Y" goto :update_bl
if /I "%c%" EQU "y" goto :update_bl
if /I "%c%" EQU "N" goto :post_bl_check
if /I "%c%" EQU "n" goto :post_bl_check
goto :bad_bl_version
:update_bl
@echo -- Updating Bootloader --
lighthouse_watchman_update -Rw3
timeout /nobreak /t 4
lighthouse_watchman_update.exe -s %serial_number% --hwid 0x%hwid_current% --target=bootloader watchman_v3_bootloader_umodule.fw
timeout /nobreak /t 4
goto :check_compatibility

:stop
lighthouse_watchman_update -Rw3
set /P c=Press Enter to quit...
