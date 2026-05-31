@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "BUILD_MODE=%APK_BUILD_MODE%"
if /I not "%BUILD_MODE%"=="release" set "BUILD_MODE=debug"

set "DART_DEFINES="

:collect_args
if "%~1"=="" goto run_build
set "CURRENT_ARG=%~1"
echo %CURRENT_ARG% | findstr /B /C:"--dart-define=" >nul
if not errorlevel 1 set "DART_DEFINES=!DART_DEFINES! %CURRENT_ARG%"
shift
goto collect_args

:run_build
echo Building MedVault APK in %BUILD_MODE% mode...
flutter build apk --%BUILD_MODE%%DART_DEFINES%
exit /b %ERRORLEVEL%