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
ECHO Recon3D Control Panel Configured Successfully
PAUSE>nul
exit

:CHECK_ENDPOINTS
IF "%~1" EQU "Instance ID" for /f "tokens=3 delims=\" %%a in ("%~2") do set ID=%%a
IF "%~1" EQU "Device Description" for /f "tokens=*" %%a in ("%~2") do set DESCRIPTION=%%a
IF "%~1" EQU "Class Name" (
  IF "%DESCRIPTION%" EQU "Speaker (Sound Blaster Recon3D)" (
    SET RENDER_FOUND=TRUE
    REG ADD "HKCU\SOFTWARE\Creative Tech\Audio Endpoint Selection\Sound Blaster Recon 3D Control Panel" /v Render /t REG_SZ /d "%ID%" /f >nul
  )
  IF "%DESCRIPTION%" EQU "Microphone (Sound Blaster Recon3D)" (
    SET CAPTURE_FOUND=TRUE
    REG ADD "HKCU\SOFTWARE\Creative Tech\Audio Endpoint Selection\Sound Blaster Recon 3D Control Panel" /v Capture /t REG_SZ /d "%ID%" /f >nul
  )
  SET DESCRIPTION=""
  SET ID=""
)
GOTO :EOF

:RENDER_NOT_DETECTED
ECHO.
ECHO. Recon3D speaker not detected!
PAUSE>nul
EXIT

:CAPTURE_NOT_DETECTED
ECHO.
ECHO. Recon3D microphone not detected!
PAUSE>nul
EXIT

:UNSUPPORTED
ECHO.
ECHO. Windows 10 and above required!
PAUSE>nul
EXIT