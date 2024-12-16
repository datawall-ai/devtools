@echo off

REM ------------------------------------------------------------
REM 1. Install fnm
REM ------------------------------------------------------------
echo Installing fnm...
winget install Schniz.fnm -e | findstr /i "already installed" >nul
if %ERRORLEVEL% EQU 0 (
    echo fnm is already installed.
) else (
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to install fnm. Exiting script.
        exit /b 1
    )
)

REM ------------------------------------------------------------
REM 2. Generate a .bat file with environment variables
REM ------------------------------------------------------------
echo Configuring fnm environment...
fnm env --use-on-cd > "%TEMP%\fnmEnv.bat"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to generate fnm environment file. Exiting script.
    exit /b 1
)

REM ------------------------------------------------------------
REM 3. Call the generated file to set environment vars
REM ------------------------------------------------------------
call "%TEMP%\fnmEnv.bat"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to configure fnm environment. Exiting script.
    exit /b 1
)

REM ------------------------------------------------------------
REM 4. Install and Use Node.js v22
REM ------------------------------------------------------------
echo Installing Node.js version 22...
fnm use --install-if-missing 22
if %ERRORLEVEL% NEQ 0 (
    echo Failed to install Node.js version 22. Exiting script.
    exit /b 1
)

REM ------------------------------------------------------------
REM 5. Verify Node & npm versions
REM ------------------------------------------------------------
echo Verifying Node.js installation...
for /f "tokens=*" %%i in ('node -v') do set "NODE_VERSION=%%i"
echo Node.js version: %NODE_VERSION%
echo %NODE_VERSION% | findstr "^v22." >nul
if %ERRORLEVEL% NEQ 0 (
    echo Unexpected Node.js version detected: %NODE_VERSION%
    exit /b 1
)

echo Verifying npm installation...
for /f "tokens=*" %%i in ('npm -v') do set "NPM_VERSION=%%i"
echo npm version: %NPM_VERSION%
echo %NPM_VERSION% | findstr "^10." >nul
if %ERRORLEVEL% NEQ 0 (
    echo Unexpected npm version detected: %NPM_VERSION%
    exit /b 1
)

REM ------------------------------------------------------------
REM 6. Success!
REM ------------------------------------------------------------
echo Node.js environment setup completed successfully.
exit /b 0
