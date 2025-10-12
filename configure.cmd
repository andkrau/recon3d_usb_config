@ECHO OFF
TITLE Recon3D Configuration
COLOR 9F
SET RENDER_FOUND=FALSE
SET CAPTURE_FOUND=FALSE

:VERSION
pnputil /? | findstr /C:"/enum-devices" >nul
if %errorlevel% NEQ 0 GOTO UNSUPPORTED

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