@echo off
setlocal enabledelayedexpansion

:: Configuration
set GIT_REPO_URL=https://github.com/lsaray/minecraft-server-local.git
set LOCK_FILE=lock.txt

:: Pull the latest files
git pull
if %errorlevel% neq 0 (
    echo Error: Failed to pull from Git repository.
    pause
    exit /b 1
)

:: Check lock file
if not exist %LOCK_FILE% (
    echo 0 > %LOCK_FILE%
    git add %LOCK_FILE%
    git commit -m "Initialize lock file"
    git push
)

set /p LOCK=<%LOCK_FILE%
if "%LOCK%"=="1" (
    echo Error: Server is already locked by another host.
    pause
    exit /b 1
)

:: Acquire lock
echo 1 > %LOCK_FILE%
git add %LOCK_FILE%
git commit -m "Acquire server lock"
git push
if %errorlevel% neq 0 (
    echo Error: Failed to acquire lock.
    pause
    exit /b 1
)

:: Start Minecraft server
C:/Users/andeo/AppData/Roaming/PrismLauncher/java/jre-legacy/bin/java.exe -Xmx4096M -Xms1024M -jar forge-1.16.5-36.2.34.jar nogui

:: On script exit (Ctrl+C or window close), release lock and push
:cleanup
echo Releasing lock and shutting down...
echo 0 > %LOCK_FILE%
git add %LOCK_FILE%
git add *
git commit -m "Release server lock"
git push

endlocal