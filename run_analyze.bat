@echo off
rem Runs flutter analyze on the mobile app from the repo root, wherever this repo is cloned.
cd /d "%~dp0"
flutter analyze apps/mobile-app

