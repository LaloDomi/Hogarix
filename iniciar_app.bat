@echo off
REM Abre la app en Chrome en el puerto 5000 (el que se registra en Google y Facebook).
REM Antes abre iniciar_backend.bat.
cd /d "%~dp0frontend"
call flutter pub get
call flutter run -d chrome --web-port 5000
pause
