@echo off

set vnum=1.6
set vdate=Feb 23rd 2022

@echo Please check https://github.com/tundra-labs/HWID_check to make sure that you have the latest version of this script!
@echo This is version number %vnum% changed on %vdate%.
@echo+
@echo A new log file is created after each device verification, these can be found in the same folder as this script.
@echo+
@echo+
@echo This script can cause damage to SteamVR devices that are not Tundra Tracker!
@echo+
set /P c=Are you sure that only one Tundra tracker is connected to your PC and no other devices are connected? (y)es, (n)o: 
@echo+

for /F "Tokens=1 skip=1 delims=." %%A in ('wmic os get localdatetime') do (
  if not defined dt set dt=%%A
)

set /a cycles=0
set overwr=false
set logname=name

set version_csl='lighthouse_console.exe version'

set /a active_devices=0

set serial_number=unknown

set /a bl_version_current=0
:: set /a bl_version_check=1622649182 REMOVED CHECK FOR SPECIFIC VERSION NEEDS ADJUSTEMNT IN CODE
set /a bl_version_required=1637337510

set hwid_current=0x0
set product_id_check=0xf0000109
set product_id_required=0xf1030009

set /a fw_version_current=0
set /a fw_version_buffer=0
set /a fw_version_required=1637337510

set /a rad_version_current=0
set /a rad_version_required=1632527453

set "fpga_version_current=0(0)"
set "fpga_version_required=538(2.26/7/2)"
set "fpga_version_missing=0(0.0/255/15)"

if /I "%c%" == "y" goto :check_compatibility
if /I "%c%" == "n" goto :stop
if /I "%c%" == "OVER!WRITE_FIRM!WARE" @echo+ Firmware verification check disabled! & set overwr=true & goto :check_compatibility
:: DON'T USE THIS UNLESS YOU 100% KNOW WHAT YOU ARE DOING
goto :stop

:check_compatibility
set /a cycles=cycles+1
set /a nextcycle=cycles+1
set logname=hwid_check_%dt:~0,4%%dt:~4,2%%dt:~6,2%%dt:~8,2%%dt:~10,2%%dt:~12,2%_c%cycles%.log
echo Created logfile on the %dt:~0,4%-%dt:~4,2%-%dt:~6,2% (MM-DD) at %dt:~8,2%:%dt:~10,2%:%dt:~12,2% for HWID check with version number %vnum% from %vdate%. >%logname%
echo+ Current device verification cycle is %cycles%. >>%logname%
@echo+
echo+ >>%logname%
if %overwr% == true echo+ WARNING: Overwrite firmware flag set! >>%logname%

@echo+
@echo Do not unplug the device at any point!
@echo+
@echo Verifying device data, please wait...

for /F "Tokens=1,5 delims= " %%A in (%version_csl%) do (
  if "%%A" == "Attached" (set /a active_devices=%%B)
)
echo+ >>%logname%
echo Active devices check resulted in: "%active_devices%" - expecting 3. >>%logname%
echo+ >>%logname%
timeout /t 1 /nobreak >nul

@echo+
if %active_devices% == 0 (@echo Could not find any active devices! & echo ERROR: Could not find any active devices! >>%logname%)
if %active_devices% == 0 goto :err
if %active_devices% LSS 3 (@echo Wrong device connected? & echo ERROR: Wrong device connected? >>%logname%)
if %active_devices% LSS 3 goto :err
if %active_devices% GTR 3 (@echo Too many devices or dongle connected? & echo ERROR: Too many devices or dongle connected? >>%logname%)
if %active_devices% GTR 3 goto :err
:: Tries to catch if no device, the wrong device or too many devices are plugged in.

for /F "Tokens=1,2 skip=10 delims=-:," %%A in (%version_csl%) do (
  if "%%A" == "LHR" (set serial_number=LHR-%%B)
)
echo+ >>%logname%
echo+ Device serial number is "%serial_number%". >>%logname%

for /F "Tokens=1,2,7 skip=14 delims=:, " %%A in (%version_csl%) do (
  if "%%A" == "Watchman" if "%%B" == "Version" (set "fpga_version_current=%%C")
)

for /F "Tokens=1,2,9 skip=14 delims=:, " %%A in (%version_csl%) do (
  if "%%A" == "Watchman" if "%%B" == "Version" (set /a bl_version_current=%%C)
)

for /F "Tokens=1,3 skip=14 delims= " %%A in (%version_csl%) do (
  if "%%A" == "Hardware" (set hwid_current=%%B)
  if "%%A" == "VRC" (
    if not %overwr% == true (
	    set /a fw_version_current=%%B
	    set /a fw_version_buffer=%%B
    )
    if %overwr% == true (
	    set /a fw_version_current=01100001
	    set /a fw_version_buffer=%%B
    )
  )
  if "%%A" == "Radio" (set rad_version_current=%%B)
)


echo+ >>%logname%
echo Device HWID is "%hwid_current%",                expecting "%product_id_required%" - new or "%product_id_check%" - old. >>%logname%
echo Device FPGA version is "%fpga_version_current%",     expecting "%fpga_version_required%" - needed. >>%logname%
echo Device firmware version is "v%fw_version_buffer%",   expecting "v%fw_version_required%" - needed. >>%logname%
echo Device bootloader version is "v%bl_version_current%", expecting "v%bl_version_required%" - new. >>%logname%
echo Device radio version is "v%rad_version_current%",      expecting "v%rad_version_required%" - new. >>%logname%

timeout /t 1 /nobreak >nul

echo+ >>%logname%
@echo+
@echo -- Device status --

@echo+
@echo Device serial number is "%serial_number%".

@echo+
@echo Device HWID is "%hwid_current%".
if %hwid_current% == 0x0 (@echo HWID could not be identified, quit for safety! & echo ERROR: HWID could not be identified, quit! >>%logname%)
if %hwid_current% == 0x0 goto :stop
if not %hwid_current% == %product_id_check% if not %hwid_current% == %product_id_required% (@echo HWID of "%hwid_current%" is not associated with Tundra Tracker, quit for safety! & echo WARNING: HWID of "%hwid_current%" not associated with Tundra Tracker, quit! >>%logname%)
if not %hwid_current% == %product_id_check% if not %hwid_current% == %product_id_required% goto :stop
if %hwid_current% == %product_id_required% (@echo This is the correct HWID for Tundra Tracker. & echo Correct HWID for Tundra Tracker. >>%logname%)
if %hwid_current% == %product_id_required% goto :hwid_is_safe
if %hwid_current% == %product_id_check% (@echo This is an older HWID and should be updated. & echo Older HWID and should be updated. >>%logname%)
if %hwid_current% == %product_id_check% goto :bad_hwid
@echo HWID of "%hwid_current%" is not associated with Tundra Tracker, quit for safety! & echo WARNING: HWID of "%hwid_current%" not associated with Tundra Tracker, quit! "(Script end)" >>%logname%
:: This catches all other possibilities.
goto :stop

:hwid_is_safe

@echo+
@echo Device FPGA version is "%fpga_version_current%".
if "%fpga_version_current%" == "%fpga_version_missing%" (@echo The FPGA version could not be identified, quit for safety! Please notify @Keigun on 'https://forum.tundra-labs.com/u/keigun/'! & echo ERROR: FPGA version could not be identified, quit! >>%logname%)
if "%fpga_version_current%" == "%fpga_version_missing%" goto :stop
if not "%fpga_version_current%" == "%fpga_version_missing%" if not "%fpga_version_current%" == "%fpga_version_required%" (@echo Unexpected FPGA version identified, quit for safety! Please notify @Keigun on 'https://forum.tundra-labs.com/u/keigun/'! & echo WARNING: Unexpected FPGA version of "%fpga_version_current%", quit! >>%logname%)
if not "%fpga_version_current%" == "%fpga_version_missing%" if not "%fpga_version_current%" == "%fpga_version_required%" goto :stop
if "%fpga_version_current%" == "%fpga_version_required%" (@echo This is the correct FPGA version for Tundra Tracker. & echo Correct FPGA version for Tundra Tracker. >>%logname%)
if "%fpga_version_current%" == "%fpga_version_required%" goto :fpga_is_safe
@echo The FPGA version could not be identified, quit for safety! Please notify @Keigun on 'https://forum.tundra-labs.com/u/keigun/'! & echo WRANING: FPGA version could not be identified, quit! "(Script end)" >>%logname%)
goto :stop

:fpga_is_safe

@echo+
@echo Device firmware version is "v%fw_version_buffer%".
if %fw_version_current% == 0 (@echo Firmware version could not be identified, quit for safety! & echo ERROR: Firmware version could not be identified, quit! >>%logname%)
if %fw_version_current% == 0 goto :stop
if %fw_version_current% == %fw_version_required% (@echo This is the correct firmware version for Tundra Tracker. & echo Correct firmware version for Tundra Tracker. >>%logname%) 
:: Change '==' to 'GEQ' if a newer version is not a issue and remove line further below.
if %fw_version_current% LSS %fw_version_required% (@echo This is a older firmware version for Tundra Tracker. & echo Older firmware version for Tundra Tracker. >>%logname%)
if %fw_version_current% LSS %fw_version_required% goto :bad_fw_version
if %fw_version_current% GTR %fw_version_required% (@echo This is a newer than expected firmware version for Tundra Tracker, quit for safety! & echo WARNING: Newer than expected firmware version for Tundra Tracker, quit! >>%logname%) 
:: Remove ^ line if this is not a problem, added to catch unexpected behaviour.
if %fw_version_current% GTR %fw_version_required% goto :stop
:: Remove ^ line if this is not a problem, added to catch unexpected behaviour.

@echo+
@echo Device bootloader version is "v%bl_version_current%".
if %bl_version_current% == 0 (@echo Bootloader version could not be identified, quit for safety! & echo ERROR: Bootloader version could not be identified, quit! >>%logname%)
if %bl_version_current% == 0 goto :stop
if %bl_version_current% == %bl_version_required% (@echo This is the correct bootloader version for Tundra Tracker. & echo Correct bootloader version for Tundra Tracker. >>%logname%)
::if %bl_version_current% == %bl_version_required% goto :stop
if %bl_version_current% LSS %bl_version_required% (@echo This is a older bootloader version for Tundra Tracker. & echo Older bootloader version for Tundra Tracker. >>%logname%) 
:: Change '==' to 'LSS' to update all older bootloaders and remove line further below. CHANGED
if %bl_version_current% LSS %bl_version_required% goto :bad_bl_version
:: Change '==' to 'LSS' to update all older bootloaders and remove line further below. CHANGED
if %bl_version_current% GTR %bl_version_required% (@echo This is a newer than expected bootloader version for Tundra Tracker, quit for safety! & echo WARNING: Newer than expected bootloader version for Tundra Tracker, quit! >>%logname%)
if %bl_version_current% GTR %bl_version_required% goto :stop
::if %bl_version_current% LSS %bl_version_required% (@echo This is a unexpected bootloader version for Tundra Tracker, quit for safety! & echo WARNING: Unexpected bootloader version for Tundra Tracker, quit! >>%logname%) 
:: Remove ^ line when updating all older bootloaders.
::if %bl_version_current% LSS %bl_version_required% goto :stop
:: Remove ^ line when updating all older bootloaders.

@echo+
@echo Device radio version is "v%rad_version_current%".
::if %rad_version_current% == 0 (@echo Radio version could not be identified, quit for safety! & echo ERROR: Radio version could not be identified, quit! >>%logname%) RADIO VERSIONS ARE REPORTING 0?
::if %rad_version_current% == 0 goto :stop RADIO VERSIONS ARE REPORTING 0?
if %rad_version_current% == %rad_version_required% (@echo This is the correct radio version for Tundra Tracker. & echo Correct radio version for Tundra Tracker. >>%logname%)
if %rad_version_current% == %rad_version_required% goto :stop
if %rad_version_current% LSS %rad_version_required% (@echo This is a older radio version for Tundra Tracker. & echo Older radio version for Tundra Tracker. >>%logname%) 
:: Change '==' to 'LSS' to update all older bootloaders and remove line further below. CHANGED
if %rad_version_current% LSS %rad_version_required% goto :bad_rad_version
:: Change '==' to 'LSS' to update all older bootloaders and remove line further below. CHANGED
if %rad_version_current% GTR %rad_version_required% (@echo This is a newer than expected radio version for Tundra Tracker, quit for safety! & echo WARNING: Newer than expected radio version for Tundra Tracker, quit! >>%logname%)
if %rad_version_current% GTR %rad_version_required% goto :stop
::if %rad_version_current% LSS %rad_version_required% (@echo This is a unexpected radio version for Tundra Tracker, quit for safety! & echo WARNING: Unexpected radio version for Tundra Tracker, quit! >>%logname%) 
:: Remove ^ line when updating all older bootloaders.
::if %rad_version_current% LSS %rad_version_required% goto :stop
:: Remove ^ line when updating all older bootloaders.
echo Script failed, please notify @Keigun on 'https://forum.tundra-labs.com/u/keigun/'! >>%logname%
@echo Script failed, please notify @Keigun on 'https://forum.tundra-labs.com/u/keigun/'!
echo+ >>%logname%
@echo+
goto :stop

:err_hw_check
@echo+
echo+ >>%logname%
@echo You need to update the HWID to continue! & echo User declined HWID update! >>%logname%
goto :stop

:err_fw_check
@echo+
echo+ >>%logname%
@echo You need to update the firmware to continue! & echo User declined firmware update! >>%logname%
goto :stop

:err_bl_check
@echo+
echo+ >>%logname%
@echo You need to update the bootloader to continue! & echo User declined bootloader update! >>%logname%
goto :stop

:err_rad_check
@echo+
echo+ >>%logname%
@echo Radio update was aborted! & echo User declined radio update! >>%logname%
goto :stop

:bad_hwid
@echo+
set /P c=HWID needs to be updated, would you like to update? (y)es, (n)o: 
@echo+
if /I "%c%" == "y" goto :update_hwid
if /I "%c%" == "n" goto :err_hw_check
goto :bad_hwid

:update_hwid
@echo+
echo+ >>%logname%
@echo -- Updating HWID -- & echo -- Updating HWID -- >>%logname%
@echo+
echo+ >>%logname%
echo Setting into bootloader mode. >>%logname%
echo+ Executing -bw3 >>%logname%
lighthouse_watchman_update.exe -bw3 >>%logname% 2>&1
echo+ >>%logname%
timeout /t 8 /nobreak >nul
echo+ Executing -Bw3 >>%logname%
lighthouse_watchman_update.exe -Bw3 0xF1030009 >>%logname% 2>&1
@echo+ ... Saved info to log file ...
@echo+
echo+ >>%logname%
timeout /t 8 /nobreak >nul
@echo -- Updating HWID done -- & echo -- Updating HWID done -- >>%logname%
@echo+
echo+ >>%logname%
echo+ Next device verification cycle log is hwid_check_%dt:~0,4%%dt:~4,2%%dt:~6,2%%dt:~8,2%%dt:~10,2%%dt:~12,2%_c%nextcycle%.log. >>%logname%
goto :check_compatibility

:bad_fw_version
@echo+
set overwr=false
set /P c=Firmware version is outdated, would you like to update? (y)es, (n)o: 
@echo+
if /I "%c%" == "y" goto :update_fw
if /I "%c%" == "n" goto :err_fw_check
goto :bad_fw_version

:update_fw
@echo+
echo+ >>%logname%
@echo -- Updating firmware -- & echo -- Updating firmware -- >>%logname%
@echo+
echo+ >>%logname%
echo+ Executing firmware update >>%logname%
lighthouse_watchman_update.exe -s %serial_number% --target=application tundra-tracker_application_1637337510.fw >>%logname% 2>&1
@echo+ ... Saved info to log file ...
@echo+
echo+ >>%logname%
timeout /t 4 /nobreak >nul
@echo -- Updating firmware done -- & echo -- Updating firmware done -- >>%logname%
@echo+
echo+ >>%logname%
echo+ Next device verification cycle log is hwid_check_%dt:~0,4%%dt:~4,2%%dt:~6,2%%dt:~8,2%%dt:~10,2%%dt:~12,2%_c%nextcycle%.log. >>%logname%
goto :check_compatibility

:bad_bl_version
@echo+
set /P c=Bootloader version is outdated, would you like to update? (y)es, (n)o: 
@echo+
if /I "%c%" == "y" goto :update_bl
if /I "%c%" == "n" goto :err_bl_check
goto :bad_bl_version

:update_bl
@echo+
echo+ >>%logname%
@echo -- Updating bootloader -- & echo -- Updating bootloader -- >>%logname%
@echo+
echo+ >>%logname%
echo+ Executing bootloader update >>%logname%
lighthouse_watchman_update.exe -s %serial_number% --hwid %hwid_current% --target=bootloader watchman_v3_bootloader_umodule.fw >>%logname% 2>&1
@echo+ ... Saved info to log file ...
@echo+
echo+ >>%logname%
timeout /t 4 /nobreak >nul
@echo -- Updating bootloader done -- & echo -- Updating bootloader done-- >>%logname%
@echo+
echo+ >>%logname%
echo+ Next device verification cycle log is hwid_check_%dt:~0,4%%dt:~4,2%%dt:~6,2%%dt:~8,2%%dt:~10,2%%dt:~12,2%_c%nextcycle%.log. >>%logname%
goto :check_compatibility

:bad_rad_version
@echo+
set /P c=Radio version is outdated, would you like to update? (y)es, (n)o: 
@echo+
if /I "%c%" == "y" goto :update_rad
if /I "%c%" == "n" goto :err_rad_check
goto :bad_rad_version

:update_rad
@echo+
echo+ >>%logname%
@echo -- Updating radio -- & echo -- Updating radio -- >>%logname%
@echo+
echo+ >>%logname%
echo+ Executing radio update >>%logname%
lighthouse_watchman_update.exe -s %serial_number% --hwid %hwid_current% --target=default nrf52_20210924v1632527453.fw >>%logname% 2>&1
@echo+ ... Saved info to log file ...
@echo+
echo+ >>%logname%
timeout /t 4 /nobreak >nul
@echo -- Updating radio done -- & echo -- Updating radio done-- >>%logname%
@echo+
echo+ >>%logname%
echo+ Next device verification cycle log is hwid_check_%dt:~0,4%%dt:~4,2%%dt:~6,2%%dt:~8,2%%dt:~10,2%%dt:~12,2%_c%nextcycle%.log. >>%logname%
goto :check_compatibility

:err
@echo+
echo+ >>%logname%
@echo+
echo+ >>%logname%
@echo Please check connected devices! & echo ERROR: Device check failed! >>%logname%
set /P c=Press Enter to quit...
echo+ >>%logname%
echo+ Logging finished. >>%logname%
echo+ Total amount of log files for this device is %cycles%. >>%logname%
Exit /b

:stop
@echo+
echo+ >>%logname%
@echo+
echo+ >>%logname%
@echo Device is now safe to unplug, please replug the device before rerunning the script! & echo Device safe to unplug. >>%logname%
set /P c=Press Enter to quit...
echo+ >>%logname%
echo+ Logging finished. >>%logname%
echo+ Total amount of log files for this device is %cycles%. >>%logname%
Exit /b
