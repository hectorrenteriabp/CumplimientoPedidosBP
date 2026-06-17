@echo off
setlocal
cd /d "%~dp0"

echo [*] Sincronizando ultimas actualizaciones del repositorio...
git checkout -- BP_Dashboard_Standalone.html BP_Dashboard_Cumplimiento.html web-dashboard/public/dashboard.html web-dashboard/public/test-cooler.html >nul 2>&1
git pull origin main

echo.
echo ================================================
echo   BP Dashboard - Actualizador Automatico
echo ================================================
echo.

:: Detectar Python
set "PY="
py --version >nul 2>&1 && set "PY=py"
if not defined PY python --version >nul 2>&1 && set "PY=python"
if not defined PY python3 --version >nul 2>&1 && set "PY=python3"

if not defined PY (
    echo [!] Python no encontrado. Instalando...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;(New-Object Net.WebClient).DownloadFile('https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe','%TEMP%\pyinst.exe')"
    "%TEMP%\pyinst.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 Include_launcher=1
    del "%TEMP%\pyinst.exe" >nul 2>&1
    set "PY=py"
)

:: Verificar librerias
%PY% -c "import pandas,numpy,openpyxl,pdfplumber" >nul 2>&1
if errorlevel 1 (
    echo [!] Instalando librerias...
    %PY% -m pip install pandas numpy openpyxl pdfplumber --quiet --disable-pip-version-check
)

:: Levantar servidor de persistencia (si no está ya corriendo)
echo [*] Iniciando servidor de persistencia local...
start /b "" %PY% "%~dp0bp_servidor.py"
timeout /t 1 /nobreak >nul

:: Verificar Git
git --version >nul 2>&1
if errorlevel 1 (
    echo [!] Instalando Git...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;(New-Object Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe','%TEMP%\gitinst.exe')"
    if exist "%TEMP%\gitinst.exe" (
        "%TEMP%\gitinst.exe" /VERYSILENT /NORESTART /NOCANCEL /SP-
        del "%TEMP%\gitinst.exe" >nul 2>&1
    )
)

:: Ejecutar actualizador
echo.
echo ================================================
echo.
set "BP_AUTORIZADO=1"

:: Cargar token de GitHub desde archivo local (no versionado, esta en .gitignore)
:: El token NO se escribe en este .bat ni en el .py: vive solo en bp_token.txt
if exist "%~dp0bp_token.txt" set /p BP_GITHUB_TOKEN=<"%~dp0bp_token.txt"

%PY% "%~dp0BP_Cumplimiento_Actualizador.py"
set "BP_GITHUB_TOKEN="
set "BP_AUTORIZADO="
echo.
echo ================================================
echo.
echo   https://hectorrenteriabp.github.io/CumplimientoPedidosBP/
echo.
echo ================================================
echo.
pause
