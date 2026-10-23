@echo off
title Publish Web App to Firebase Hosting
echo ========================================================
echo   PUBLISHING WEBCART STORE TO FIREBASE HOSTING
echo ========================================================
echo.
set "PATH=%APPDATA%\npm;C:\Program Files\nodejs;%PATH%"

echo 1. Checking Firebase Login...
call firebase login

echo.
echo 2. Deploying to Firebase Hosting (webcart-store-945ab)...
call firebase deploy --only hosting

echo.
echo ========================================================
echo   DONE! Your live web app URL is displayed above.
echo ========================================================
pause
