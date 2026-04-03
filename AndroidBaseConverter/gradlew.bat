@ECHO OFF
SETLOCAL

SET APP_HOME=%~dp0
SET WRAPPER_DIR=%APP_HOME%gradle\wrapper
SET WRAPPER_JAR=%WRAPPER_DIR%\gradle-wrapper.jar

IF NOT EXIST "%WRAPPER_JAR%" (
  ECHO gradle-wrapper.jar not found, bootstrapping wrapper via local Gradle...
  where gradle >nul 2>nul
  IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: local gradle command not found. Please install Gradle 8.x first.
    EXIT /B 1
  )

  SET BOOT_DIR=%APP_HOME%.wrapper-bootstrap
  IF NOT EXIST "%BOOT_DIR%" mkdir "%BOOT_DIR%"
  > "%BOOT_DIR%\settings.gradle" echo rootProject.name = 'wrapperBootstrap'
  > "%BOOT_DIR%\build.gradle" echo task wrapper(type: Wrapper) {
  >> "%BOOT_DIR%\build.gradle" echo     gradleVersion = '8.0'
  >> "%BOOT_DIR%\build.gradle" echo     distributionType = Wrapper.DistributionType.BIN
  >> "%BOOT_DIR%\build.gradle" echo     validateDistributionUrl = false
  >> "%BOOT_DIR%\build.gradle" echo }

  gradle -p "%BOOT_DIR%" wrapper
  IF NOT EXIST "%WRAPPER_DIR%" mkdir "%WRAPPER_DIR%"
  copy /Y "%BOOT_DIR%\gradle\wrapper\gradle-wrapper.jar" "%WRAPPER_JAR%" >nul
  copy /Y "%BOOT_DIR%\gradle\wrapper\gradle-wrapper.properties" "%WRAPPER_DIR%\gradle-wrapper.properties" >nul
  rmdir /S /Q "%BOOT_DIR%"
)

java -Dorg.gradle.appname=gradlew -classpath "%WRAPPER_JAR%" org.gradle.wrapper.GradleWrapperMain %*
