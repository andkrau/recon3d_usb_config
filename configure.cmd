@ECHO OFF
TITLE Recon3D Configuration
COLOR 9F
SET RENDER_FOUND=FALSE
SET CAPTURE_FOUND=FALSE
SET "LANGUAGE=Default"
SET "MIXER="
SET "SPEAKER="
SET "MICROPHONE="
SET "BASE=HKEY_LOCAL_MACHINE\SOFTWARE\Creative Tech\KSAud"
SET COUNT=0

:LOGO
chcp 65001
cls
ECHO.
ECHO.       ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓░▓▓▓▓▓▓▓░
ECHO.      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░       ▓▓  ▓▓   ░▓▓
ECHO.     ░▓▓▓▓             ░▓▓▓▓       ▓▓▓▓▓ ░▓▓▓▓             ▒▓▓▓▓       ▓▓▓▓▓ ▒▓▓▓▓       ▓▓▓▓▓ ▒▓▓▓▓▓▓▓▒ ▓▓▒   ▓▓
ECHO.     ▓▓▓▓              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓              ▓▓▓▓        ▓▓▓▓  ▓▓▓▓        ▓▓▓▓        ▓▓  ▓▓   ▒▓▓
ECHO.    ▓▓▓▓▒             ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓▓▒             ▓▓▓▓▓       ▓▓▓▓░ ▓▓▓▓▒       ▓▓▓▓░ ▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓
ECHO.   ░▓▓▓▓             ▒▓▓▓▓             ▒▓▓▓▓             ▒▓▓▓▓       ▓▓▓▓▓ ▒▓▓▓▓       ▓▓▓▓▓
ECHO.   ▓▓▓▓              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓        ▓▓▓▓
ECHO.  ▓▓▓▓▓              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▒       ▓▓▓▓░
ECHO.

:VERSION
pnputil /? | findstr /C:"/enum-devices" >nul
if %errorlevel% NEQ 0 GOTO UNSUPPORTED

:REGISTRY
reg query "%BASE%" >nul 2>&1
if %errorlevel% NEQ 0 goto REG_MISSING
CALL :ASSIGN_STRING "%BASE%\MixerName" Spk SPEAKER
CALL :ASSIGN_STRING "%BASE%\MixerName" Mic MICROPHONE
for /f "delims=" %%a in ('reg query "%BASE%\MixerName" /f "" /k 2^>nul') do (
    echo %%a | findstr /b /i "%BASE%\MixerName" >nul
    if errorlevel 1 goto :END_LOOP
    SET LANGUAGE=%%~na
    CALL :ASSIGN_STRING "%%a" Spk SPEAKER
    CALL :ASSIGN_STRING "%%a" Mic MICROPHONE
)
:END_LOOP
reg query "%BASE%\VID_041E&PID_3221" >nul 2>&1
if %errorlevel% EQU 0 CALL :ASSIGN_STRING "%BASE%\VID_041E&PID_3221" MixerName MIXER
reg query "%BASE%\VID_041E&PID_322F" >nul 2>&1
if %errorlevel% EQU 0 CALL :ASSIGN_STRING "%BASE%\VID_041E&PID_322F" MixerName MIXER
if "%MIXER%" EQU "" goto MIXER_MISSING

:DEVICE
FOR /F "skip=2 tokens=1* delims=:" %%a IN ('pnputil -enum-devices /connected /class "AudioEndpoint"') DO CALL :CHECK_ENDPOINTS "%%a" "%%b"
IF "%RENDER_FOUND%" EQU "FALSE" GOTO RENDER_NOT_DETECTED
IF "%CAPTURE_FOUND%" EQU "FALSE" GOTO CAPTURE_NOT_DETECTED

GOTO SUCCESS

:CHECK_ENDPOINTS
SET "VALUE=%~2"
IF NOT "%VALUE:MMDEVAPI=%" EQU "%VALUE%" SET COUNT=1
IF %COUNT% EQU 1 for /f "tokens=3 delims=\" %%m in ("%~2") do set "ID=%%m"
IF %COUNT% EQU 2 for /f "tokens=*" %%m in ("%~2") do set "DESCRIPTION=%%m"
IF %COUNT% EQU 3 (
  IF "%DESCRIPTION%" EQU "%SPEAKER% (%MIXER%)" (
    SET RENDER_FOUND=TRUE
    REG ADD "HKCU\SOFTWARE\Creative Tech\Audio Endpoint Selection\Sound Blaster Recon 3D Control Panel" /v Render /t REG_SZ /d "%ID%" /f >nul
  )
  IF "%DESCRIPTION%" EQU "%MICROPHONE% (%MIXER%)" (
    SET CAPTURE_FOUND=TRUE
    REG ADD "HKCU\SOFTWARE\Creative Tech\Audio Endpoint Selection\Sound Blaster Recon 3D Control Panel" /v Capture /t REG_SZ /d "%ID%" /f >nul
  )
  SET DESCRIPTION=""
  SET ID=""
)
SET /a COUNT+=1
GOTO :EOF

:ASSIGN_STRING
reg query %1 /v %2 >nul 2>&1
if %errorlevel% NEQ 0 goto REG_MISSING
for /f "tokens=3*" %%a in ('reg query %1 /v %2 2^>nul') do (
    if "%%b"=="" (
        set "%3=%%a"
    ) else (
        set "%3=%%a %%b"
    )
)
GOTO :EOF

:RENDER_NOT_DETECTED
ECHO.
ECHO. Speaker not detected!
PAUSE>nul
EXIT

:CAPTURE_NOT_DETECTED
ECHO.
ECHO. Microphone not detected!
PAUSE>nul
EXIT

:REG_MISSING
ECHO.
ECHO. Registry entries not found!
PAUSE>nul
EXIT

:MIXER_MISSING
ECHO.
ECHO. Could not find sound mixer!
PAUSE>nul
EXIT

:UNSUPPORTED
ECHO.
ECHO. Windows 10 or above is required!
PAUSE>nul
EXIT

:SUCCESS
ECHO. Language: %LANGUAGE%
ECHO. Mixer: %MIXER%
ECHO. Speaker: %SPEAKER%
ECHO. Microphone: %MICROPHONE%
ECHO. Sound Blaster Recon 3D Control Panel configured Successfully
PAUSE>nul
exit
