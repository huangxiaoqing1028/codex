@ECHO OFF
where gradle >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
  ECHO Gradle is not installed. Please install Gradle or open with Android Studio.
  EXIT /B 1
)
gradle %*
