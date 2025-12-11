@echo off
title SB E-Series Configuration
color 9F
set RENDER_FOUND=FALSE
set CAPTURE_FOUND=FALSE
set "LANGUAGE=Default"
set "MIXER="
set "SPEAKER="
set "MICROPHONE="
set "BASE=HKEY_LOCAL_MACHINE\SOFTWARE\Creative Tech\KSAud"
set COUNT=0

:LOGO
chcp 65001
cls
echo.
echo. ░▒▓████████▓▒     ░░▒▓███████▓▒░▒▓████████▓▒░▒▓███████▓▒░░▒▓█▓▒░▒▓████████▓▒░░▒▓███████▓▒░
echo. ░▒▓█▓▒░           ░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░
echo. ░▒▓█▓▒░           ░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░
echo. ░▒▓██████▓▒░▒▓███▓▒░▒▓██████▓▒░░▒▓██████▓▒░ ░▒▓███████▓▒░░▒▓█▓▒░▒▓██████▓▒░  ░▒▓██████▓▒░
echo. ░▒▓█▓▒░                  ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░
echo. ░▒▓█▓▒░                  ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░             ░▒▓█▓▒░
echo. ░▒▓████████▓░     ░▒▓███████▓▒░░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓████████▓▒░▒▓███████▓▒░
echo.

:VERSION
where pnputil >nul 2>&1
if %errorlevel% NEQ 0 goto :UNSUPPORTED
pnputil /? | findstr /C:"/enum-devices" >nul
if %errorlevel% NEQ 0 goto :UNSUPPORTED

:REGISTRY
reg query "%BASE%" >nul 2>&1
if %errorlevel% NEQ 0 goto :REG_MISSING
call :ASSIGN_STRING "%BASE%\MixerName" Spk SPEAKER
call :ASSIGN_STRING "%BASE%\MixerName" Mic MICROPHONE
for /f "delims=" %%a in ('reg query "%BASE%\MixerName" /f "" /k 2^>nul') do (
    echo %%a | findstr /b /i "%BASE%\MixerName" >nul
    if errorlevel 1 goto :END_LOOP
    set LANGUAGE=%%~na
    call :ASSIGN_STRING "%%a" Spk SPEAKER
    call :ASSIGN_STRING "%%a" Mic MICROPHONE
)
:END_LOOP

:: SB0910 X-Fi Xtreme Audio Karaoke
call :CHECK_DEVICE PID_3041
:: SB1090 X-Fi Surround 5.1
call :CHECK_DEVICE PID_3042
:: SB1100 X-Fi Go!
call :CHECK_DEVICE PID_30E0
:: SB1095 X-Fi Surround 5.1 Pro
call :CHECK_DEVICE PID_30DF
:: SB1095A X-Fi Surround 5.1 Pro SBX
call :CHECK_DEVICE PID_3237
:: SB1095B X-Fi Surround 5.1 Pro SBX
call :CHECK_DEVICE PID_3263
:: SB1240 X-Fi HD THX
call :CHECK_DEVICE PID_30D7
:: SB1240A X-Fi HD SBX
call :CHECK_DEVICE PID_3232
:: SB1290 X-Fi Go! Pro
call :CHECK_DEVICE PID_30DD
:: SB1290A X-Fi Go! Pro
call :CHECK_DEVICE PID_3233
:: SB1300 Recon3D THX
call :CHECK_DEVICE PID_3221
:: SB1300A Recon3D SBX
call :CHECK_DEVICE PID_322F
:: SB1560 Omni Surround 5.1
call :CHECK_DEVICE PID_322C
:: SB1540 R3/A6U
call :CHECK_DEVICE PID_322B
if "%MIXER%" EQU "" goto :MIXER_MISSING

:DEVICE
for /F "skip=2 tokens=1* delims=:" %%a in ('pnputil -enum-devices /connected /class "AudioEndpoint"') do call :CHECK_ENDPOINTS "%%a" "%%b"
if "%RENDER_FOUND%" EQU "FALSE" goto :RENDER_NOT_DETECTED
if "%CAPTURE_FOUND%" EQU "FALSE" goto :CAPTURE_NOT_DETECTED

goto :SUCCESS

:CHECK_DEVICE
reg query "%BASE%\VID_041E&%1" >nul 2>&1
if %errorlevel% EQU 0 call :ASSIGN_STRING "%BASE%\VID_041E&%1" MixerName MIXER
goto :EOF

:CHECK_ENDPOINTS
set "VALUE=%~2"
if NOT "%VALUE:MMDEVAPI=%" EQU "%VALUE%" set COUNT=1
if %COUNT% EQU 1 for /f "tokens=3 delims=\" %%m in ("%~2") do set "ID=%%m"
if %COUNT% EQU 2 for /f "tokens=*" %%m in ("%~2") do set "DESCRIPTION=%%m"
if %COUNT% EQU 3 (
  if "%DESCRIPTION%" EQU "%SPEAKER% (%MIXER%)" (
    set RENDER_FOUND=TRUE
    reg add "HKCU\SOFTWARE\Creative Tech\Audio Endpoint Selection\Sound Blaster E-Series Control Panel" /v Render /t REG_SZ /d "%ID%" /f >nul
  )
  if "%DESCRIPTION%" EQU "%MICROPHONE% (%MIXER%)" (
    set CAPTURE_FOUND=TRUE
    reg add "HKCU\SOFTWARE\Creative Tech\Audio Endpoint Selection\Sound Blaster E-Series Control Panel" /v Capture /t REG_SZ /d "%ID%" /f >nul
  )
  set DESCRIPTION=""
  set ID=""
)
set /a COUNT+=1
goto :EOF

:ASSIGN_STRING
reg query %1 /v %2 >nul 2>&1
if %errorlevel% NEQ 0 goto :REG_MISSING
for /f "tokens=3*" %%a in ('reg query %1 /v %2 2^>nul') do (
    if "%%b"=="" (
        set "%3=%%a"
    ) else (
        set "%3=%%a %%b"
    )
)
goto :EOF

:RENDER_NOT_DETECTED
echo.
echo. Speaker not detected!
pause>nul
exit

:CAPTURE_NOT_DETECTED
echo.
echo. Microphone not detected!
pause>nul
exit

:REG_MISSING
echo.
echo. Registry entries not found!
pause>nul
exit

:MIXER_MISSING
echo.
echo. Could not find sound mixer!
pause>nul
exit

:UNSUPPORTED
echo.
echo. Windows 10 or above is required!
pause>nul
exit

:SUCCESS
echo. Language: %LANGUAGE%
echo. Mixer: %MIXER%
echo. Speaker: %SPEAKER%
echo. Microphone: %MICROPHONE%
echo. SB E-Series Control Panel configured successfully!
pause>nul
exit
