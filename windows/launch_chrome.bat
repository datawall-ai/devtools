@echo off
setlocal ENABLEDELAYEDEXPANSION
 
:: === Config (edit as needed) ===
set "PSEXEC=C:\Tools\PsExec.exe"
set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "SESSION_ID=1"
set "PORT=9222"
set "ADDR=127.0.0.1"
set "DATA_DIR=C:\Temp\cdp"
:: ===============================
 
:: Optional CLI overrides:
::   launch_chrome_cdp.bat [sessionId] [port] [dataDir]
if not "%~1"=="" set "SESSION_ID=%~1"
if not "%~2"=="" set "PORT=%~2"
if not "%~3"=="" set "DATA_DIR=%~3"
 
:: Quick elevation check
net session >nul 2>&1
if errorlevel 1 (
  echo [!] This shell is not elevated. Right-click CMD and "Run as administrator".
  exit /b 1
)
 
if not exist "%PSEXEC%" (
  echo [!] PsExec not found at "%PSEXEC%"
  exit /b 2
)
if not exist "%CHROME%" (
  echo [!] Chrome not found at "%CHROME%"
  exit /b 3
)
 
mkdir "%DATA_DIR%" 2>nul
 
echo [+] Launching Chrome CDP on Session %SESSION_ID% (port %PORT%)
"%PSEXEC%" -accepteula -nobanner -i %SESSION_ID% -d -s ^
  "%CHROME%" ^
  --remote-debugging-port=%PORT% ^
  --remote-debugging-address=%ADDR% ^
  --user-data-dir="%DATA_DIR%" ^
  --no-first-run --disable-first-run-ui --new-window
 
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" echo [!] PsExec returned %ERR%
exit /b %ERR%
