@ECHO OFF
SETLOCAL

where gradle8 >nul 2>nul
IF %ERRORLEVEL% EQU 0 (
  gradle8 %*
  EXIT /B %ERRORLEVEL%
)

where gradle >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
  ECHO ERROR: Gradle is not installed. Install Gradle 8.x or use Android Studio.
  EXIT /B 1
)

FOR /F "tokens=2" %%G IN ('gradle --version ^| findstr /R "^Gradle "') DO SET GV=%%G
FOR /F "tokens=1 delims=." %%M IN ("%GV%") DO SET GM=%%M
IF %GM% GEQ 9 (
  ECHO ERROR: Detected Gradle %GV%, but this project requires Gradle 8.x with AGP 8.1.1.
  ECHO Please install Gradle 8 and ensure 'gradle8' is available in PATH.
  EXIT /B 1
)

gradle %*
EXIT /B %ERRORLEVEL%
