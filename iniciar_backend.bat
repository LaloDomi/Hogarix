@echo off
REM Arranca el backend. Deja esta ventana abierta mientras usas la app.
cd /d "%~dp0backend"
if not exist ".env" (
  echo Falta el archivo backend\.env. Copia .env.example a .env y llenalo.
  pause
  exit /b 1
)
if not exist "node_modules" (
  echo Instalando dependencias por primera vez...
  call npm install
)
node server.js
echo.
echo El servidor se detuvo. Revisa el mensaje de arriba.
pause
