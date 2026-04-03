@ECHO OFF
SETLOCAL

SET APP_HOME=%~dp0
SET WRAPPER_JAR=%APP_HOME%gradle\wrapper\gradle-wrapper.jar

IF NOT EXIST "%WRAPPER_JAR%" (
  ECHO gradle-wrapper.jar not found, bootstrapping wrapper via local Gradle...
  where gradle >nul 2>nul
  IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: local gradle command not found. Please install Gradle 8.x first.
    EXIT /B 1
  )
  pushd "%APP_HOME%"
  gradle -b wrapper-bootstrap.gradle wrapper --no-validate-url
  popd
)

java -Dorg.gradle.appname=gradlew -classpath "%WRAPPER_JAR%" org.gradle.wrapper.GradleWrapperMain %*
