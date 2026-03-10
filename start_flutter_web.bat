@echo off
echo Starting Flutter Web App...
echo.

REM Get Flutter dependencies
echo Installing dependencies...
call flutter pub get

echo.
echo Starting app in Chrome...
echo NOTE: Make sure backend is running at http://localhost:8000
echo.

REM Run Flutter web with CORS disabled for development
flutter run -d chrome --web-browser-flag "--disable-web-security"

